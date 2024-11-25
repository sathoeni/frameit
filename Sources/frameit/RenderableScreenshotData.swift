//
//  RenderableScreenshotData.swift
//  AppStoreScreenshotGenerator
//
//  Created by Sascha Thöni on 22.06.21.
//  Copyright © 2021 Helsana Versicherungen AG. All rights reserved.
//

import Foundation

struct RenderableScreenshotData {
    var text: String
    var localeCode: String
    var url: URL
    var screenshotSize: CGSize
    var horizontalPadding: Double
    var topImageOffset: Double
    var fontSize: CGFloat
}
