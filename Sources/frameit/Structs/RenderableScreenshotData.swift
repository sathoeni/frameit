//
//  RenderableScreenshotData.swift
//  frameit
//
//  Created by Sascha Thöni on 22.06.21.
//  Copyright © 2021 Helsana Versicherungen AG. All rights reserved.
//

import Foundation

/// Contains all information to label a screenshots
struct RenderableScreenshotData {
    var text: String
    var localeCode: String
    var url: URL
    var screenshotSize: CGSize
    var insets: Insets
    var fontSize: CGFloat
}
