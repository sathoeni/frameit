//
//  FontLoader.swift
//  
//
//  Created by Sascha Thöni on 29.12.21.
//
// Code from FontBlaster https://github.com/ArtSabintsev/FontBlaster

import Foundation
import CoreGraphics
import CoreText


/// Dynamically installs a font
/// The font could then be used within the application
final class FontLoader {
    
    /// Loads a specific font.
    ///
    /// - Parameter fontFile: The full qualified name of the font e.g. Robot-Regular.ttf
    class func loadFromBundle(fontFile: String) {
        
        guard let fontPath = Bundle.module.path(forResource: fontFile.fileName, ofType: fontFile.fileExtension) else {
            print("*** ERROR: Font file could not be found in bundle \(fontFile)")
            return
        }
        
        let fontFileURL = URL(fileURLWithPath: fontPath)
        
        var fontError: Unmanaged<CFError>?
        if let fontData = try? Data(contentsOf: fontFileURL) as CFData,
            let dataProvider = CGDataProvider(data: fontData) {

            let fontRef = CGFont(dataProvider)

            if CTFontManagerRegisterGraphicsFont(fontRef!, &fontError),
               let postScriptName = fontRef?.postScriptName {
                    print("Successfully loaded font: '\(postScriptName)'.")
            } else if let fontError = fontError?.takeRetainedValue() {
                let errorDescription = CFErrorCopyDescription(fontError)
                print("Failed to load font from url '\(fontFileURL)': \(String(describing: errorDescription))")
            }
        } else {
            guard let fontError = fontError?.takeRetainedValue() else {
                print("Failed to load font url '\(fontFileURL)'.")
                return
            }

            let errorDescription = CFErrorCopyDescription(fontError)
            print("Failed to load font url '\(fontFileURL)': \(String(describing: errorDescription))")
        }
    }
}

// MARK: Helper Extension

private extension String {
    var fileName: String {
       URL(fileURLWithPath: self).deletingPathExtension().lastPathComponent
    }

    var fileExtension: String{
       URL(fileURLWithPath: self).pathExtension
    }
}
