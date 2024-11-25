//
//  ScreenshotProperties.swift
//  AppStoreScreenshotGenerator
//
//  Created by Sascha Thöni on 01.06.21.
//  Copyright © 2021 Helsana Versicherungen AG. All rights reserved.
//

import Foundation

struct ScreenshotTextData {
    var localeCode: LocaleCode
    var viewID: ViewID
    var title: String
}

enum LocaleCode: String {
    case de = "de-DE"
    case fr = "fr-FR"
    case it = "it-IT"
    case en = "en-US"
}

enum ViewID: String {
    case home, insurancecard, scan, invoices, policies
}
