//
//  File.swift
//  frameit
//
//  Created by Sascha Thöni on 28.11.2024.
//

import Foundation

extension URL {
    /// Extracts the locale code from the URL's path components.
    /// Assumes the locale code is the last directory name before the filename.
    var localeCode: String? {
        // Get the parent directory name (which should be the locale code)
        let localeCode = self.deletingLastPathComponent().lastPathComponent
        print("Extracted locale code: \(localeCode)")
        return localeCode
    }
    
    /// Extracts the view ID from the URL's filename.
    /// Assumes the view ID is the last component 
    var viewID: String? {
        // Remove the file extension from the filename
        let filenameWithoutExtension = self.deletingPathExtension().lastPathComponent
        print("Filename without extension: \(filenameWithoutExtension)")
        
        // Split the filename by dots
        let components = filenameWithoutExtension.components(separatedBy: ".")
        
        // Assume the view ID is the last component after the last dot
        if let viewID = components.last, components.count > 1 {
            print("Extracted view ID: \(viewID)")
            return viewID
        } else {
            print("View ID not found in filename.")
            return nil
        }
    }
}
