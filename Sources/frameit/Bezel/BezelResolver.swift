//
//  BezelResolver.swift
//  frameit
//
//  Created by Sascha Thöni on 31.05.21.
//  Copyright © 2021 Helsana Versicherungen AG. All rights reserved.
//

import Foundation

/// BezelResolver is responsible for finding and downloading the appropriate device bezel (frame)
/// for a given screenshot. It uses a three-step matching process:
/// 1. Exact match by bezelID (if provided)
/// 2. Match by screen resolution
/// 3. Fallback to aspect ratio matching
class BezelResolver {
    /// URL to the remote repository containing device bezels and metadata
    private let bezelsURL = "https://raw.githubusercontent.com/sathoeni/frameit-bezels/master"
    
    /// Local directory where downloaded bezels are cached
    private let cacheDirectory: URL
    
    /// Cached device bezel metadata loaded from device-bezels.json
    private var bezelsData: DeviceBezelsData?
    
    /// Initializes the BezelResolver and creates the cache directory if needed
    /// - Throws: Error if cache directory creation fails
    init() throws {
        let fileManager = FileManager.default
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDirectory.appendingPathComponent("frameit-bezels")
        
        try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    /// Finds the appropriate device bezel for a screenshot
    /// - Parameters:
    ///   - bezelID: Optional identifier to force a specific device bezel
    ///   - bezelColor: Optional color variant of the device bezel (e.g., "space-gray", "silver")
    ///   - size: The resolution of the screenshot in pixels
    /// - Returns: URL to the local cached bezel image if found, nil otherwise
    /// - Throws: BezelFramerError if loading or downloading fails
    func findBezel(bezelID: String?, bezelColor: String?, forScreenshotSize size: CGSize) throws -> URL? {
        // Load bezel metadata if not already loaded
        if bezelsData == nil {
            try loadBezels()
        }
        
        guard let bezelsData = bezelsData else {
            throw BezelFramerError.couldNotParseBezelData
        }
        
        // Determine if the screenshot is portrait or landscape
        let orientation: DeviceBezelsData.DeviceModel.Orientation =
            size.width > size.height ? .landscape : .portrait
        
        // Step 1: Try to find exact match by bezelID if provided
        if let bezelID = bezelID {
            if let device = bezelsData.devices.first(where: { $0.id.lowercased() == bezelID.lowercased() }) {
                if let frame = device.frames.first(where: { frame in
                    frame.orientation == orientation &&
                    (bezelColor == nil || frame.color == bezelColor)
                }) {
                    print("> Found matching device by ID: \(device.name) (\(frame.color))")
                    return try ensureBezelDownloaded(path: frame.path)
                }
            }
        }
        
        // Step 2: If no bezelID match, try matching by resolution
        for device in bezelsData.devices {
            let matches: Bool
            
            if orientation == .portrait {
                matches = device.resolution.width == Int(size.width) &&
                          device.resolution.height == Int(size.height)
            } else {
                // For landscape, we need to check the rotated dimensions
                matches = device.resolution.width == Int(size.height) &&
                          device.resolution.height == Int(size.width)
            }
            
            if matches {
                // Found matching resolution, get corresponding frame
                if let frame = device.frames.first(where: { frame in
                    frame.orientation == orientation &&
                    (bezelColor == nil || frame.color == bezelColor)
                }) {
                    print("> Found matching device by resolution: \(device.name) (\(frame.color))")
                    return try ensureBezelDownloaded(path: frame.path)
                }
            }
        }
        
        // Step 3: If still no match, try finding a device with matching aspect ratio
        for device in bezelsData.devices {
            let resolutionAspectRatio = Double(device.resolution.width) / Double(device.resolution.height)
            let screenshotAspectRatio = orientation == .portrait ?
                size.width / size.height :
                size.height / size.width
            
            // Allow for small differences in aspect ratio (0.1% tolerance)
            if abs(resolutionAspectRatio - screenshotAspectRatio) < 0.001 {
                if let frame = device.frames.first(where: { frame in
                    frame.orientation == orientation &&
                    (bezelColor == nil || frame.color == bezelColor)
                }) {
                    print("> No exact match found for size: \(size). Using \(device.name) (\(frame.color)) based on aspect ratio")
                    return try ensureBezelDownloaded(path: frame.path)
                }
            }
        }
        
        return nil
    }
    
    /// Loads the device bezel metadata from the remote repository
    /// - Throws: Error if loading or parsing fails
    private func loadBezels() throws {
        let jsonURL = URL(string: "\(bezelsURL)/device-bezels.json")!
        let jsonData = try Data(contentsOf: jsonURL)
        bezelsData = try JSONDecoder().decode(DeviceBezelsData.self, from: jsonData)
    }
    
    /// Ensures the bezel image is downloaded and cached locally
    /// - Parameter path: Relative path to the bezel image in the remote repository
    /// - Returns: URL to the local cached bezel image
    /// - Throws: Error if download or saving fails
    private func ensureBezelDownloaded(path: String) throws -> URL {
        let bezelURL = cacheDirectory.appendingPathComponent(path)
        
        if !FileManager.default.fileExists(atPath: bezelURL.path) {
            // Create intermediate directories if needed
            try FileManager.default.createDirectory(at: bezelURL.deletingLastPathComponent(), 
                                                 withIntermediateDirectories: true)
            
            let downloadURL = URL(string: "\(bezelsURL)/\(path)")!
            let bezelData = try Data(contentsOf: downloadURL)
            try bezelData.write(to: bezelURL)
        }
        
        return bezelURL
    }
} 
