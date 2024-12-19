//
//  CGImage+PNG.swift
//
//  Created by Josh Luongo on 13/12/2022.
//

import Foundation
import CoreImage
import ImageIO
import CoreGraphics
import UniformTypeIdentifiers

extension CGImage {

    /// Write this CGImage as a PNG file.
    ///
    /// - Parameter destinationURL: Destination file.
    /// - Returns: Did the write work?
    @discardableResult func writeAsPng(_ destinationURL: URL) -> Bool {
        guard let destination = CGImageDestinationCreateWithURL(destinationURL as CFURL, UTType.png as! CFString, 1, nil) else { return false }
        CGImageDestinationAddImage(destination, self, nil)
        return CGImageDestinationFinalize(destination)
    }

}
