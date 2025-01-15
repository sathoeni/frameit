//
//  GenericError.swift
//  BezelManager
//
//  Created by Josh Luongo on 16/12/2022.
//

import Foundation

enum BezelFramerError: Error {
    case failedToLoadLocalBezel
    case failedToLoadRemoteBezel
    case failedToConvertImage
    case failedToAddBezelToScreenshot
    case couldNotParseBezelData
    case noMatchingBezelFound
}
