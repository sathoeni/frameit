//
//  File.swift
//  frameit
//
//  Created by Sascha Thöni on 28.11.2024.
//

import Foundation

extension URL {
    /// A computed property to extract the locale code from the URL's last path component.
    /// Returns a locale code in the format "xx-XX", or `nil` if not found.
    var localeCode: String? {
        let filename = self.lastPathComponent
        print("Extracting locale code from filename: \(filename)")
        if let match = filename.range(of: "([a-z]{2}-[A-Z]{2})", options: .regularExpression) {
            let localeCode = String(filename[match])
            print("Extracted locale code: \(localeCode)")
            return localeCode
        }
        return nil // Return nil if not found
    }
    
    /// A computed property to extract the view ID from the URL's last path component.
    /// Returns a view ID matching the pattern "_[a-z]+", or `nil` if not found.
    var viewID: String? {
        let filename = self.lastPathComponent
        print("Extracting view ID from filename: \(filename)")
        if let match = filename.range(of: "_([a-z]+)", options: .regularExpression) {
            let viewID = String(filename[match]).replacingOccurrences(of: "_", with: "")
            print("Extracted view ID: \(viewID)")
            return viewID
        }
        return nil // Return nil if not found
    }
}
