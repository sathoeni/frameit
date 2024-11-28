//
//  main.swift
//  AppStoreScreenshotGenerator
//
//  Created by Sascha Thöni on 31.05.21.
//  Copyright © 2021 Helsana Versicherungen AG. All rights reserved.
//

// Screenshot Infos: https://help.apple.com/app-store-connect/#/devd274dd925
// https://fastlane.github.io/frameit-frames/latest/offsets.json
// https://github.com/fastlane/fastlane/blob/master/frameit/lib/frameit/device_types.rb

import Foundation
import AppKit
import ArgumentParser

@main
struct AppStoreScreenshotGenerator: AsyncParsableCommand {

    @Option(name: .customShort("i"), help: "The directory of the framed screenshots.")
    var screenshotsDirectory: String

    @Option(name: .customShort("o"), help: "The output directory for the appstore screenshots.")
    var outputDirectory: String
    
    @Option(name: .customShort("c"), help: "Path to the configuration file (optional, only needed for adding text)")
    var configPath: String?

    private var frameitConfig: FrameitConfiguration?
    
    mutating func validate() throws { 

        // Expand "~" to home path
        screenshotsDirectory = NSString(string: screenshotsDirectory).expandingTildeInPath

        // Missing screenshots directory is an unrecoverable error
        if !FileManager.default.fileExists(atPath: screenshotsDirectory) {
            throw ValidationError("Screenshots directory does not exist")
        }
        
        // EXPAND "~" to home path
        outputDirectory = NSString(string: outputDirectory).expandingTildeInPath

        // Try to create output directory (if missing)
        if !FileManager.default.fileExists(atPath: outputDirectory) {
            try FileManager.default.createDirectory(
                atPath: outputDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }

        // Only load config if path is provided
        if let configPath = configPath {
            let configURL = URL(fileURLWithPath: NSString(string: configPath).expandingTildeInPath)
            guard let configData = try? Data(contentsOf: configURL) else {
                throw FrameitError.cannotReadConfiguration
            }
            
            let decoder = JSONDecoder()
            guard let config = try? decoder.decode(FrameitConfiguration.self, from: configData) else {
                throw FrameitError.invalidConfigurationFormat
            }
            
            frameitConfig = config
        }
    }

    mutating func run() async throws {
        FontLoader.loadFromBundle(fontFile: "Roboto-Regular.ttf")
        
        // 1. Load all screenshots
        let screenshotURLs = try loadScreenshots(fromDirectory: screenshotsDirectory)
        
        // 2. Add bezels
        let framedImages = try await addBezelsToScreenshots(screenshotURLs)
        
        // 3. If no config provided, just save the bezeled images
        guard let config = frameitConfig else {
            // Save the bezeled images, ensuring they match the original screenshot size
            try await saveFramedScreenshots(framedImages, toDirectory: outputDirectory, originalURLs: screenshotURLs)
            return
        }
        
        // 4. Otherwise prepare rendering data and generate final screenshots with text
        let originalSizes = try loadScreenshots(fromDirectory: screenshotsDirectory).map { NSImage(contentsOf: $0)?.size ?? .zero }
        let renderableData = try prepareRenderingData(images: framedImages.map { $0.framedImage }, originalSizes: originalSizes, urls: screenshotURLs, with: config)
        try await generateFinalScreenshots(from: renderableData)
    }
    
    private func addBezelsToScreenshots(_ urls: [URL]) async throws -> [(originalSize: CGSize, framedImage: NSImage)] {
        var framedImages: [(CGSize, NSImage)] = []
        
        for url in urls {
            guard let originalImage = NSImage(contentsOf: url) else { continue }
            let framedImage = try BezelFramer.addBezel(screenshotImage: originalImage)
            framedImages.append((originalImage.size, framedImage))
            
            // Clear the original image to free up memory
            originalImage.removeRepresentation(originalImage.representations.first!)
        }
        
        return framedImages
    }
    
    private func saveFramedScreenshots(_ framedImages: [(originalSize: CGSize, framedImage: NSImage)], toDirectory directory: String, originalURLs: [URL]) async throws {
        for (index, (originalSize, framedImage)) in framedImages.enumerated() {
            // Create a new image context with the original dimensions
            let outputURL = URL(fileURLWithPath: directory).appendingPathComponent("\(originalURLs[index].deletingPathExtension().lastPathComponent)_framed.png")
            
            // Create a bitmap representation for PNG
            let bitmapRep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(originalSize.width), pixelsHigh: Int(originalSize.height), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)
            
            // Create a CGContext from the bitmap representation
            guard let context = CGContext(data: bitmapRep?.bitmapData,
                                          width: Int(originalSize.width),
                                          height: Int(originalSize.height),
                                          bitsPerComponent: 8,
                                          bytesPerRow: bitmapRep?.bytesPerRow ?? 0,
                                          space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
                print("Failed to create CGContext")
                continue
            }
            
            // Clear the context
            context.clear(CGRect(x: 0, y: 0, width: originalSize.width, height: originalSize.height))
            
            // Draw the framed image in the center of the new image
            let scaleFactor = min(originalSize.width / framedImage.size.width, originalSize.height / framedImage.size.height)
            let scaledSize = NSSize(width: framedImage.size.width * scaleFactor, height: framedImage.size.height * scaleFactor)
            let xOffset = (originalSize.width - scaledSize.width) / 2
            let yOffset = (originalSize.height - scaledSize.height) / 2
            
            // Draw the framed image
            context.draw(framedImage.asCGImage()!, in: CGRect(origin: CGPoint(x: xOffset, y: yOffset), size: scaledSize))
            
            // Save the resulting image
            if let pngData = bitmapRep?.representation(using: .png, properties: [:]) {
                try pngData.write(to: outputURL)
                print("Saved framed screenshot: \(outputURL)")
            } else {
                print("Failed to create PNG data for \(outputURL)")
            }
            
            // Clear the framed image to free up memory
            framedImage.removeRepresentation(framedImage.representations.first!)
        }
    }
    
    private func prepareRenderingData(images: [NSImage], originalSizes: [CGSize], urls: [URL], with config: FrameitConfiguration) throws -> [(screenshot: RenderableScreenshotData, framedImage: NSImage)] {
        var renderableData: [(screenshot: RenderableScreenshotData, framedImage: NSImage)] = []
        
        for index in 0..<images.count {
            let image = images[index]
            let originalSize = originalSizes[index]
            let url = urls[index]
            
            // Find matching device configuration based on original image size
            guard let (deviceName, deviceConfig) = config.devices.first(where: { 
                $0.value.size == originalSize 
            }) else {
                print("Warning: No matching device configuration found for image size: \(originalSize)")
                continue
            }
            
            // Use the framed image directly
            let trimmedImage = image // No need to trim if we are just using the framed image
            
            // Extract locale and view ID from the URL using the URL extension
            let localeCode = url.localeCode
            let viewID = url.viewID
            
            // Check if the extracted values are valid
            guard let validLocaleCode = localeCode, let validViewID = viewID,
                  let textData = config.texts.first(where: {
                      $0.localeCode == validLocaleCode && $0.viewID == validViewID
                  }) else { 
                print("Warning: No valid text configuration found for URL: \(url)")
                continue 
            }
            
            let renderableScreenshot = RenderableScreenshotData(
                text: textData.title,
                localeCode: textData.localeCode,
                url: url,
                screenshotSize: originalSize,  // Use original size for final output
                horizontalPadding: deviceConfig.horizontalPadding,
                topImageOffset: deviceConfig.topScreenshotOffset,
                fontSize: CGFloat(deviceConfig.fontSize)
            )
            
            renderableData.append((renderableScreenshot, trimmedImage))
            print("Prepared rendering data for device \(deviceName), language: \(textData.localeCode)")
        }
        
        return renderableData
    }
    
    @MainActor
    private func generateFinalScreenshots(from framedScreenshots: [(screenshot: RenderableScreenshotData, framedImage: NSImage)]) async throws {
        for (screenshotData, framedImage) in framedScreenshots {
            // Save framed image temporarily
            let temporaryURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString + ".png")
            if let tiffData = framedImage.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiffData),
               let pngData = bitmap.representation(using: .png, properties: [:]) {
                try? pngData.write(to: temporaryURL)
            }
            
            // Create and render the final screenshot with text
            guard let screenshotView = await ScreenshotView(
                imageURL: temporaryURL,
                title: screenshotData.text,
                fontSize: screenshotData.fontSize,
                size: screenshotData.screenshotSize,
                horizontalImagePadding: screenshotData.horizontalPadding,
                topImageOffset: screenshotData.topImageOffset
            ) else { continue }
            
            // Create bitmap with the exact size of the original screenshot
            let bitmap = NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: Int(screenshotData.screenshotSize.width),
                pixelsHigh: Int(screenshotData.screenshotSize.height),
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: 0,
                bitsPerPixel: 0
            )
            
            // Set the size of the view to match the bitmap size
            screenshotView.frame = CGRect(origin: .zero, size: screenshotData.screenshotSize)
            
            // Render the view into the bitmap
            await screenshotView.cacheDisplay(in: screenshotView.bounds, to: bitmap!)
            
            // Save the final screenshot
            let directoryURL = URL(fileURLWithPath: outputDirectory).appendingPathComponent(screenshotData.localeCode)
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
            
            let outputURL = directoryURL.appendingPathComponent(screenshotData.url.lastPathComponent)
            if let pngData = bitmap?.representation(using: .png, properties: [:]) {
                try pngData.write(to: outputURL)
                print("Saved final screenshot: \(outputURL)")
            }
            
            // Clean up temporary file
            try? FileManager.default.removeItem(at: temporaryURL)
        }
    }
    
    // Move extensions inside the struct
    private struct Extensions {

    }
    
    // Move error types inside the struct
    private enum FrameitError: Error {
        case missingDeviceConfiguration(String)
        case invalidConfigurationFormat
        case cannotReadConfiguration
        
        var localizedDescription: String {
            switch self {
            case .missingDeviceConfiguration(let diagonal):
                return "Missing configuration for device with screen size \(diagonal)"
            case .invalidConfigurationFormat:
                return "Invalid configuration format"
            case .cannotReadConfiguration:
                return "Cannot read configuration file"
            }
        }
    }

    private func loadScreenshots(fromDirectory directory: String) throws -> [URL] {
        guard let baseUrl = URL(string: directory) else { return [] }
        let items = FileManager.default.subpaths(atPath: baseUrl.path) ?? []
        
        return items.compactMap { item in
            guard item.hasSuffix(".png") else { return nil }
            guard let encodedItemPath = item.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
            let url = URL(fileURLWithPath: baseUrl.path + "/" + encodedItemPath)
            
            // Verify it's a valid image file
            guard NSImage(contentsOf: url) != nil else { return nil }
            return url
        }
    }
}
