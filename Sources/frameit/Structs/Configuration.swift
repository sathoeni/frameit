//
//  Configuration.swift
//  frameit
//
//  Created by Sascha Thöni on 26.11.2024.
//

import Foundation

/// Configuration for a specific device screenshot
struct DeviceConfiguration: Codable {
    // The horiztonal insets of the screenshot
    let horizontalPadding: Double
    // The top offset of the screenshot
    let topScreenshotOffset: Double
    // The font size of the text
    let fontSize: Double
}

/// Represents the configuration for a text
struct TextConfiguration: Codable {
    // The locale code of the text e.g. de-DE
    let localeCode: String
    // The id of the view e.g. home
    let viewID: String
    // The content of the text that will be rendered
    let title: String
}

struct FrameitConfiguration: Codable {
    let devices: [String: DeviceConfiguration]
    let texts: [TextConfiguration]
}
