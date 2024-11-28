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
            try await saveFramedScreenshots(framedImages, urls: screenshotURLs, toDirectory: outputDirectory)
            return
        }
        
        // 4. Otherwise prepare rendering data and generate final screenshots with text
        let renderableData = try prepareRenderingData(images: framedImages, urls: screenshotURLs, with: config)
        try await generateFinalScreenshots(from: renderableData)
    }
    
    private func addBezelsToScreenshots(_ urls: [URL]) async throws -> [NSImage] {
        var framedImages: [NSImage] = []
        
        for url in urls {
            guard let originalImage = NSImage(contentsOf: url) else { continue }
            let framedImage = try BezelFramer.addBezel(screenshotImage: originalImage)
            framedImages.append(framedImage)
        }
        
        return framedImages
    }
    
    private func saveFramedScreenshots(_ images: [NSImage], urls: [URL], toDirectory directory: String) async throws {
        for (image, url) in zip(images, urls) {
            let outputURL = URL(fileURLWithPath: directory)
                .appendingPathComponent(url.lastPathComponent)
            
            if let tiffData = image.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiffData),
               let pngData = bitmap.representation(using: .png, properties: [:]) {
                try pngData.write(to: outputURL)
                print("Saved framed screenshot: \(outputURL)")
            }
        }
    }
    
    private func prepareRenderingData(images: [NSImage], urls: [URL], with config: FrameitConfiguration) throws -> [(screenshot: RenderableScreenshotData, framedImage: NSImage)] {
        var renderableData: [(screenshot: RenderableScreenshotData, framedImage: NSImage)] = []
        
        for (image, url) in zip(images, urls) {
            // Find matching device configuration based on image size
            guard let (deviceName, deviceConfig) = config.devices.first(where: { 
                $0.value.size == image.size 
            }) else {
                print("Warning: No matching device configuration found for image size: \(image.size)")
                continue
            }
            
            // Only trim transparent areas
            let trimmedImage = trimTransparentAreas(image)
            
            let screenshotTextData = config.texts.map { text in
                ScreenshotTextData(
                    localeCode: LocaleCode(rawValue: text.localeCode) ?? .en,
                    viewID: ViewID(rawValue: text.viewID) ?? .home,
                    title: text.title
                )
            }
            
            guard let textData = screenshotTextData.first(where: {
                url.path.lowercased().contains($0.viewID.rawValue.lowercased()) &&
                url.path.contains($0.localeCode.rawValue)
            }) else { continue }
            
            let renderableScreenshot = RenderableScreenshotData(
                text: textData.title,
                localeCode: textData.localeCode.rawValue,
                url: url,
                screenshotSize: image.size,
                horizontalPadding: deviceConfig.horizontalPadding,
                topImageOffset: deviceConfig.topScreenshotOffset,  // Pass the offset to ScreenshotView
                fontSize: CGFloat(deviceConfig.fontSize)
            )
            
            renderableData.append((renderableScreenshot, trimmedImage))
            print("Prepared rendering data for device \(deviceName), language: \(textData.localeCode.rawValue)")
        }
        
        return renderableData
    }
    
    private func trimTransparentAreas(_ image: NSImage) -> NSImage {
        guard let cgImage = image.asCGImage() else { return image }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        
        guard let context = CGContext(data: nil,
                                    width: width,
                                    height: height,
                                    bitsPerComponent: 8,
                                    bytesPerRow: bytesPerRow,
                                    space: CGColorSpaceCreateDeviceRGB(),
                                    bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue),
              let data = context.data else {
            return image
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        let pixelData = data.assumingMemoryBound(to: UInt8.self)
        
        var topY = 0
        var bottomY = height - 1
        
        // Find first non-transparent row from top
        outerTop: for y in 0..<height {
            for x in 0..<width {
                let offset = (y * bytesPerRow) + (x * bytesPerPixel) + 3 // +3 for alpha channel
                if pixelData[offset] > 0 {
                    topY = y
                    break outerTop
                }
            }
        }
        
        // Find first non-transparent row from bottom
        outerBottom: for y in (0..<height).reversed() {
            for x in 0..<width {
                let offset = (y * bytesPerRow) + (x * bytesPerPixel) + 3
                if pixelData[offset] > 0 {
                    bottomY = y
                    break outerBottom
                }
            }
        }
        
        // Create new image with trimmed height
        let trimmedHeight = bottomY - topY + 1
        guard let trimmedContext = CGContext(data: nil,
                                           width: width,
                                           height: trimmedHeight,
                                           bitsPerComponent: 8,
                                           bytesPerRow: bytesPerRow,
                                           space: CGColorSpaceCreateDeviceRGB(),
                                           bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return image
        }
        
        trimmedContext.draw(cgImage, in: CGRect(x: 0, y: -CGFloat(topY), width: CGFloat(width), height: CGFloat(height)))
        
        guard let trimmedCGImage = trimmedContext.makeImage(),
              let trimmedNSImage = trimmedCGImage.asNSImage() else {
            return image
        }
        
        return trimmedNSImage
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
