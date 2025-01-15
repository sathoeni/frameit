//
//  main.swift
//  frameit
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

struct FramingData {
    var originalPixelSize: CGSize // Original size in pixels
    var framedPath: String?
}

struct RenderableScreenshot {
    let data: RenderableScreenshotData
    let framedImagePath: String
}

@main
struct AppStoreScreenshotGenerator: AsyncParsableCommand {

    @Option(name: .customShort("i"), help: "The directory of the framed screenshots.")
    var screenshotsDirectory: String

    @Option(name: .customShort("o"), help: "The output directory for the appstore screenshots.")
    var outputDirectory: String
    
    @Option(name: .customShort("c"), help: "Path to the configuration file (optional, only needed for adding text)")
    var configPath: String?

    private var frameitConfig: Configuration?
    
    mutating func validate() throws { 

        // Expand "~" to home path
        screenshotsDirectory = NSString(string: screenshotsDirectory).expandingTildeInPath

        // Missing screenshots directory is an unrecoverable error
        if !FileManager.default.fileExists(atPath: screenshotsDirectory) {
            throw ValidationError("Screenshots directory does not exist")
        }
        
        // EXPAND "~" to home path
        outputDirectory = NSString(string: outputDirectory).expandingTildeInPath

        // Create output directory (if necessary)
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
            guard let config = try? decoder.decode(Configuration.self, from: configData) else {
                throw FrameitError.invalidConfigurationFormat
            }
            
            frameitConfig = config
        }
    }

    mutating func run() async throws {
        FontLoader.loadFromBundle(fontFile: "Roboto-Regular.ttf")
        
        // 1. Load all screenshots
        let screenshotURLs = try loadScreenshots(fromDirectory: screenshotsDirectory)
        
        let framedScreenshotsDir = outputDirectory.appending("/framed")
        
        // 2. Add bezels
        let framingDataList = try await addBezelsToScreenshots(inputDirectory: screenshotsDirectory, framedScreenshotsDir: framedScreenshotsDir, urls: screenshotURLs, keepOriginalSize: frameitConfig == nil)
        
        guard let config = frameitConfig else {
            print("No configuration file provided. Labeling the screenshot will be skipped")
            return
        }
        
        // 3. Otherwise prepare rendering data and generate final screenshots with text
        let renderableDataList = try prepareRenderingData(framingDataList: framingDataList, with: config)

        try await generateFinalScreenshots(from: renderableDataList)
    }

    private func addBezelsToScreenshots(
        inputDirectory: String,
        framedScreenshotsDir: String,
        urls: [URL],
        keepOriginalSize: Bool = false
    ) async throws -> [FramingData] {
        let fileManager = FileManager.default
        var framingDataList: [FramingData] = []
        
        for url in urls {
            
            print("Processing: \(url.lastPathComponent)")
            
            guard let originalImage = NSImage(contentsOf: url),
                  let originalBitmapRep = originalImage.representations.first as? NSBitmapImageRep else {
                continue
            }
            
            autoreleasepool {
                
                originalImage.cacheMode = .never
                
                
                // Get original pixel dimensions
                let originalPixelSize = CGSize(width: originalBitmapRep.pixelsWide, height: originalBitmapRep.pixelsHigh)
                
                // Add bezel to the original image
                do {
                    var framedImage = try BezelFramer.addBezel(
                        bezelID: bezelID(for: originalPixelSize),
                        bezelColor: bezelColor(for: originalPixelSize), 
                        screenshotImage: originalImage
                    )
                    
                    // Resize the framed image if keepOriginalSize is true
                    if keepOriginalSize, let resizedImage = resizeImageToOriginalPixelSize(framedImage, originalPixelSize: originalPixelSize) {
                        framedImage = resizedImage
                    }
                    
                    // Calculate the relative path of the file from the input directory
                    let relativePath = url.deletingLastPathComponent().path.replacingOccurrences(of: inputDirectory, with: "")
                    
                    // Create the corresponding subdirectory in the output directory
                    let targetDirectory = URL(fileURLWithPath: framedScreenshotsDir).appendingPathComponent(relativePath).path
                    try fileManager.createDirectory(atPath: targetDirectory, withIntermediateDirectories: true)
                    
                    // Save the framed image
                    let filename = url.lastPathComponent
                    let framedImageURL = URL(fileURLWithPath: targetDirectory).appendingPathComponent(filename)
                    
                    if let tiffData = framedImage.tiffRepresentation,
                       let bitmapImageRep = NSBitmapImageRep(data: tiffData),
                       let pngData = bitmapImageRep.representation(using: .png, properties: [:]) {
                        try pngData.write(to: framedImageURL)
                    } else {
                        throw NSError(domain: "ImageProcessingError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to save framed image to disk."])
                    }
                    
                    // Append the framing data
                    let framingData = FramingData(
                        originalPixelSize: originalPixelSize,
                        framedPath: framedImageURL.path
                    )
                    framingDataList.append(framingData)
                    
                    // Clear images to free up memory
                    originalImage.removeRepresentation(originalImage.representations.first!)
                    framedImage.removeRepresentation(framedImage.representations.first!)
                    
                    
                    
                } catch {
                    print(error)
                }
            }
        }
        return framingDataList
    }


    private func resizeImageToOriginalPixelSize(_ image: NSImage, originalPixelSize: CGSize) -> NSImage? {
        let pixelsWide = Int(originalPixelSize.width)
        let pixelsHigh = Int(originalPixelSize.height)

        // Create a bitmap representation with the original pixel dimensions
        let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixelsWide,
            pixelsHigh: pixelsHigh,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )

        // Create a CGContext from the bitmap representation
        guard let context = CGContext(
            data: bitmapRep?.bitmapData,
            width: pixelsWide,
            height: pixelsHigh,
            bitsPerComponent: 8,
            bytesPerRow: bitmapRep?.bytesPerRow ?? 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            print("Failed to create CGContext")
            return nil
        }

        // Clear the context
        context.clear(CGRect(x: 0, y: 0, width: pixelsWide, height: pixelsHigh))

        // Calculate the scaling and offsets to center the image
        let scaleFactor = min(CGFloat(pixelsWide) / image.size.width, CGFloat(pixelsHigh) / image.size.height)
        let scaledSize = NSSize(width: image.size.width * scaleFactor, height: image.size.height * scaleFactor)
        let xOffset = (CGFloat(pixelsWide) - scaledSize.width) / 2
        let yOffset = (CGFloat(pixelsHigh) - scaledSize.height) / 2

        // Draw the input image in the resized context
        context.draw(image.asCGImage()!, in: CGRect(origin: CGPoint(x: xOffset, y: yOffset), size: scaledSize))

        // Create a new NSImage from the bitmap representation
        let resizedImage = NSImage(size: originalPixelSize)
        resizedImage.addRepresentation(bitmapRep!)
    
        
        return resizedImage
    }
    
    private func prepareRenderingData(
        framingDataList: [FramingData],
        with config: Configuration
    ) throws -> [RenderableScreenshot] {
        var renderableDataList: [RenderableScreenshot] = []
        
        for framingData in framingDataList {
            // Ensure we have a valid framed image path
            guard let framedPath = framingData.framedPath else {
                print("Warning: Framed path is nil in framingData")
                continue
            }
            
            // Convert framedPath to URL
            let framedURL = URL(fileURLWithPath: framedPath)
            
            // Extract localeCode and viewID from the framed image URL
            guard let localeCode = framedURL.localeCode,
                  let viewID = framedURL.viewID else {
                print("Warning: Unable to extract localeCode or viewID from framed image path: \(framedPath)")
                continue
            }
            
            // Find matching device configuration based on original image size
            guard let (deviceName, deviceConfig) = config.devices.first(where: {
                $0.value.size == framingData.originalPixelSize
            }) else {
                print("Warning: No matching device configuration found for image size: \(framingData.originalPixelSize)")
                continue
            }
            
            // Find the corresponding text data
            guard let textData = config.titles.first(where: {
                $0.localeCode.lowercased() == localeCode.lowercased() && $0.viewID.lowercased() == viewID.lowercased()
            }) else {
                print("Warning: No valid text configuration found for locale: \(localeCode), viewID: \(viewID)")
                continue
            }
            
            let insets = deviceConfig.layoutConfiguration?.deviceFrameInsets ?? .init(top: 0, left: 0, bottom: 0, right: 0)
            let fontSize = deviceConfig.layoutConfiguration?.fontSize ?? 48
            
            // Create the renderable screenshot data
            let renderableScreenshotData = RenderableScreenshotData(
                text: textData.text,
                localeCode: textData.localeCode,
                url: framedURL,
                screenshotSize: framingData.originalPixelSize,  // Use original pixel size
                insets: insets,
                fontSize: CGFloat(fontSize)
            )
            
            // Create the RenderableScreenshot instance
            let renderableScreenshot = RenderableScreenshot(
                data: renderableScreenshotData,
                framedImagePath: framedPath
            )
            
            // Append to the renderable data array
            renderableDataList.append(renderableScreenshot)
            print("Prepared rendering data for device \(deviceName), language: \(textData.localeCode)")
        }
        
        return renderableDataList
    }
    
    private func bezelColor(for size: CGSize) -> String? {
        guard let configuration = frameitConfig else { return nil }
        // Iterate through all devices in the configuration
        for (_, deviceSpecification) in configuration.devices {
            // Compare the input size with the device size
            if deviceSpecification.size == size {
                // Return the optional bezel color
                return deviceSpecification.bezelColor
            }
        }
        // Return nil if no matching device is found
        return nil
    }
    
    private func bezelID(for size: CGSize) -> String? {
        guard let configuration = frameitConfig else { return nil }
        // Iterate through all devices in the configuration
        for (deviceName, deviceSpecification) in configuration.devices {
            // Compare the input size with the device size
            if deviceSpecification.size == size {
                // Return the device name as the bezelID
                return deviceSpecification.bezelID
            }
        }
        // Return nil if no matching device is found
        return nil
    }
    
    @MainActor
    private func generateFinalScreenshots(from renderableScreenshots: [RenderableScreenshot]) async throws {
        for renderableScreenshot in renderableScreenshots {
            let screenshotData = renderableScreenshot.data
            let framedImagePath = renderableScreenshot.framedImagePath

            // Load the framed image from disk
            guard let framedImage = NSImage(contentsOfFile: framedImagePath) else {
                print("Warning: Could not load framed image from path: \(framedImagePath)")
                continue
            }

            // Create and render the final screenshot with text
            guard let screenshotView = ScreenshotView(
                image: framedImage,
                title: screenshotData.text,
                fontSize: screenshotData.fontSize,
                size: screenshotData.screenshotSize,
                insets: screenshotData.insets
            ) else {
                print("Warning: Failed to create ScreenshotView for image at path: \(framedImagePath)")
                continue
            }

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
            guard let bitmapRep = bitmap else {
                print("Warning: Failed to create bitmap representation for screenshot")
                continue
            }

            let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmapRep)
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = graphicsContext

            screenshotView.displayIgnoringOpacity(screenshotView.bounds, in: graphicsContext!)

            NSGraphicsContext.restoreGraphicsState()

            // Save the final screenshot
            let directoryURL = URL(fileURLWithPath: outputDirectory).appendingPathComponent("labeled").appendingPathComponent(screenshotData.localeCode)
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)

            let outputURL = directoryURL.appendingPathComponent(screenshotData.url.lastPathComponent)
            if let pngData = bitmapRep.representation(using: .png, properties: [:]) {
                try pngData.write(to: outputURL)
                print("Saved final screenshot: \(outputURL)")
            } else {
                print("Warning: Failed to create PNG data for final screenshot at path: \(outputURL)")
            }
        }
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
