//
//  CGImage+NSImage.swift
//
//  Created by Sascha Thöni on 26.11.2024.
//

import Foundation
import AppKit

extension CGImage {
    /// Create a CIImage version of this image
    ///
    /// - Returns: Converted image, or nil
    func asCIImage() -> CIImage {
        return CIImage(cgImage: self)
    }
    
    /// Create an NSImage version of this image
    ///
    /// - Returns: Converted image, or nil
    func asNSImage() -> NSImage? {
        return NSImage(cgImage: self, size: .zero)
    }
}
