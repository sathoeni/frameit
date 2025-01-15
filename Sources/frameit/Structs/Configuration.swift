//
//  Configuration.swift
//  frameit
//
//  Created by Sascha Thöni on 26.11.2024.
//

import Foundation

import Foundation

/// Represents the specifications of a device for a screenshot, including its dimensions and optional bezel color.
struct DeviceSpecification: Codable {
    
    // Optinal ID to identify the bezel
    var bezelID: String?
    
    // Optional color for the device's bezel (frame)
    var bezelColor: String?
    
    // The width of the device screenshot
    let width: Double
    // The height of the device screenshot
    let height: Double
    
    // Optional configuration for the label's position and font size
    var layoutConfiguration: LayoutConfiguration?
    
    // Computed property that returns the CGSize representation of the device screenshot dimensions
    var size: CGSize {
        CGSize(width: width, height: height)
    }
}

/// Configuration for the layout of a label within the device's frame, including position and font size.
struct LayoutConfiguration: Codable {
    // Insets to adjust the position of the device frame within the screenshot
    var deviceFrameInsets: Insets
    // Font size for the label text
    let fontSize: Int
}

/// Defines a textual title to be shown on the screenshot, including localization and view-specific information.
struct TitleConfiguration: Codable {
    // The locale code for the language of the title, e.g., "en-US"
    let localeCode: String
    // The identifier of the view, e.g., "home"
    let viewID: String
    // The content of the title text to be displayed
    let text: String
}

/// Top-level configuration for processing device screenshots, including device specifications and title configurations.
struct Configuration: Codable {
    // A dictionary of devices (by device type or identifier) and their corresponding specifications
    let devices: [String: DeviceSpecification]
    
    // A collection of title configurations for different locales and views
    let titles: [TitleConfiguration]
}
