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

// MARK: - Extensions

extension URL {
    var fileURL: URL {
        return URL(fileURLWithPath: path)
    }
}

extension CGSize {
    var rect: CGRect {
        CGRect(origin: CGPoint.zero, size: self)
    }
}


var frameitConfig: FrameitConfiguration!

/// Creates all screenshot items that could be later rendered as app store images.
/// It takes all screenshot in a given directory and checks if a corresponding ScreenshotText for the given region and view exists. Creates an screenshotItem item for every match.
/// - Parameter directory: path to the directory where all framed screenshots are stored. The screenshot must be framed (containing a device frame) and must have a "_framed.png" suffix
/// - Returns: All the renderable screenshot data
func createRenderableScreenshotDataForImages(inDirectory directory: String, config: FrameitConfiguration) throws -> [RenderableScreenshotData] {
    var screenshots: [RenderableScreenshotData] = []
    guard let baseUrl = URL(string: directory) else { return screenshots }
    let items = FileManager.default.subpaths(atPath: baseUrl.path) ?? []

    try items.forEach { item in
        guard item.hasSuffix("_framed.png") else { return }
        guard let encodedItemPath = item.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        let screenshotURL = URL(fileURLWithPath: baseUrl.path + "/" + encodedItemPath)

        guard let image = NSImage(contentsOf: screenshotURL),
              let deviceType = DeviceType.detect(from: image.size) else { return }
              
        // Get configuration for the device
        guard let deviceConfig = config.devices[deviceType.screenDiagonal] else {
            throw FrameitError.missingDeviceConfiguration(deviceType.screenDiagonal)
        }
        
        let screenshotTextData = config.texts.map { text in
            ScreenshotTextData(
                localeCode: LocaleCode(rawValue: text.localeCode) ?? .en,
                viewID: ViewID(rawValue: text.viewID) ?? .home,
                title: text.title
            )
        }

        guard let textData = screenshotTextData.first(where: {
            screenshotURL.path.lowercased().contains($0.viewID.rawValue.lowercased()) && 
            screenshotURL.path.contains($0.localeCode.rawValue)
        }) else { return }

        screenshots.append(RenderableScreenshotData(
            text: textData.title,
            localeCode: textData.localeCode.rawValue,
            url: screenshotURL,
            screenshotSize: deviceType.screenshotSize,
            horizontalPadding: deviceConfig.horizontalPadding,
            topImageOffset: deviceConfig.topScreenshotOffset,
            fontSize: CGFloat(deviceConfig.fontSize)
        ))

        print("Found matching device \(deviceType.id), language: \(textData.localeCode.rawValue), and text: \(textData.title)")
    }

    return screenshots
}

// Add error types
enum FrameitError: Error {
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

struct AppStoreScreenshotGenerator: ParsableCommand {

    @Option(name: .customShort("i"), help: "The directory of the framed screenshots.")
    var screenshotsDirectory: String

    @Option(name: .shortAndLong, help: "The output directory for the appstore screenshots.")
    var outputDirectory: String
    
    @Option(name: .customShort("c"), help: "Path to the configuration file")
    var configPath: String

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

        // Load and validate configuration
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

    mutating func run() throws {
        FontLoader.loadFromBundle(fontFile: "Roboto-Regular.ttf")

        let screenshots = try createRenderableScreenshotDataForImages(
            inDirectory: screenshotsDirectory, 
            config: frameitConfig
        )
        
        screenshots.forEach { screenshotData in

            guard let screenshotView = ScreenshotView(imageURL: screenshotData.url, title: screenshotData.text, fontSize: screenshotData.fontSize, size: screenshotData.screenshotSize, horizontalImagePadding: screenshotData.horizontalPadding, topImageOffset: screenshotData.topImageOffset) else { return }

            guard let bitmap = screenshotView.bitmapImageRepForCachingDisplay(in: screenshotView.bounds) else { return }

            // calls draw() function of the view
            screenshotView.cacheDisplay(in: screenshotView.bounds, to: bitmap)

            let image = NSImage(size: bitmap.size)
            image.addRepresentation(bitmap)

            let properties = [NSBitmapImageRep.PropertyKey.compressionFactor: 1.0]
            let fileData = bitmap.representation(using: .png, properties: properties)

            var directoryURL = URL(fileURLWithPath: outputDirectory)
            directoryURL.appendPathComponent(screenshotData.localeCode)

            // Create Directory for saving images
            do {
                try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("*** ERROR: \(error)")
            }

            let newImageUrl = directoryURL.appendingPathComponent(screenshotData.url.lastPathComponent)

            do {
                try fileData?.write(to: newImageUrl)
                print("Saved file: \(newImageUrl)")
            } catch {
                print("*** ERROR: \(error)")
            }
        }
    }
}

AppStoreScreenshotGenerator.main()
