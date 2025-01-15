//
//  File.swift
//
//  Created by Sascha Thöni on 26.11.2024.
//

import AppKit

extension NSImage {
    /// Create a CIImage using the best representation available
    ///
    /// - Returns: Converted image, or nil
    func asCIImage() -> CIImage? {
        if let cgImage = self.asCGImage() {
            return CIImage(cgImage: cgImage)
        }
        return nil
    }
    
    /// Create a CGImage using the best representation of the image available in the NSImage for the image size
    ///
    /// - Returns: Converted image, or nil
    func asCGImage() -> CGImage? {
        var rect = NSRect(origin: CGPoint(x: 0, y: 0), size: self.size)
        return self.cgImage(forProposedRect: &rect, context: NSGraphicsContext.current, hints: nil)
    }
}
