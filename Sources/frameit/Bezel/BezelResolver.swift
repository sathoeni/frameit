import Foundation

class BezelResolver {
    private let bezelsURL = "https://raw.githubusercontent.com/sathoeni/frameit-bezels/develop"
    private let cacheDirectory: URL
    private var bezelsData: DeviceBezelsData?
    
    init() throws {
        let fileManager = FileManager.default
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDirectory.appendingPathComponent("frameit-bezels")
        
        try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func findBezel(forScreenshotSize size: CGSize) throws -> URL? {
        if bezelsData == nil {
            try loadBezels()
        }
        
        guard let bezelsData = bezelsData else {
            throw BezelFramerError.couldNotParseBezelData
        }
        
        // Determine the orientation of the screenshot
        let orientation: DeviceBezelsData.DeviceModel.Orientation = 
            size.width > size.height ? .landscape : .portrait
        
        // Find matching device model based on resolution
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
                // Default to first color (usually black/black-titanium)
                if let frame = device.frames.first(where: { frame in
                    frame.orientation == orientation && 
                    frame.color == device.frames[0].color  // Use first available color
                }) {
                    print("> Found matching device: \(device.name) (\(frame.color))")
                    return try ensureBezelDownloaded(path: frame.path)
                }
            }
        }
        
        // If exact match not found, try finding a device with matching aspect ratio
        for device in bezelsData.devices {
            let resolutionAspectRatio = Double(device.resolution.width) / Double(device.resolution.height)
            let screenshotAspectRatio = orientation == .portrait ? 
                size.width / size.height : 
                size.height / size.width
            
            // Allow for small differences in aspect ratio (0.1% tolerance)
            if abs(resolutionAspectRatio - screenshotAspectRatio) < 0.001 {
                if let frame = device.frames.first(where: { frame in
                    frame.orientation == orientation && 
                    frame.color == device.frames[0].color
                }) {
                    print("> No exact resolution match found. Using \(device.name) (\(frame.color)) based on aspect ratio")
                    return try ensureBezelDownloaded(path: frame.path)
                }
            }
        }
        
        return nil
    }
    
    private func loadBezels() throws {
        let jsonURL = URL(string: "\(bezelsURL)/device-bezels.json")!
        let jsonData = try Data(contentsOf: jsonURL)
        bezelsData = try JSONDecoder().decode(DeviceBezelsData.self, from: jsonData)
    }
    
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
