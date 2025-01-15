//
//  BezelManager.swift
//  BezelManager
//
//  Created by Josh Luongo on 13/12/2022.
//

import Foundation
import CoreImage
import ArgumentParser
import ObjectiveC
import AppKit

/// BezelFramer is responsible for adding device bezels (frames) to screenshot images
struct BezelFramer {
    
    /// Shared instance of CompositeImage used for combining screenshots with bezels
    static let compTool: CompositeImage = CompositeImage()
    
    /// Adds a device bezel (frame) to a screenshot image
    /// - Parameters:
    ///   - bezelID: Optional identifier for the specific bezel to use
    ///   - bezelColor: Optional color of the bezel (e.g. "gold", "silver")
    ///   - screenshotImage: The screenshot image to be framed
    ///   - skipContentBox: If true, skips content box validation
    ///   - noClip: If true, prevents image clipping during composition
    ///   - frame: Optional path to a local frame image file
    /// - Returns: NSImage with the screenshot composited inside the device bezel
    /// - Throws: BezelFramerError if any step of the process fails
    ///
    /// The bezel will be automatically identified by the resolution of the screenshot image.
    /// For fine-grained control over device selection, you can specify:
    /// - bezelID: to target a specific device model
    /// - bezelColor: to specify the device color (e.g. "gold", "silver")
    ///
    static func addBezel(bezelID: String?, bezelColor: String?, screenshotImage: NSImage, skipContentBox: Bool = false, noClip: Bool = false, frame: String? = nil) throws -> NSImage {
        // Load the frame
        var bezelImage: CGImage!
        
            if let framePath = frame {
                guard let loadedFrame = CGImage.loadImage(filename: framePath) else {
                    throw BezelFramerError.failedToLoadLocalBezel
                }
                bezelImage = loadedFrame
            } else {
                // Try to find matching bezel
                let bezelResolver = try BezelResolver()
                
                guard let bezelPath = try bezelResolver.findBezel(bezelID: bezelID, bezelColor: bezelColor, forScreenshotSize: screenshotImage.resolution) else {
                    throw BezelFramerError.noMatchingBezelFound
                }
                
                guard let loadedBezel = CGImage.loadImage(url: bezelPath) else {
                    throw BezelFramerError.failedToLoadRemoteBezel
                }
                bezelImage = loadedBezel
            }
        
        
        
        var cgImage: CGImage!
        
            // Load the composite class.
            compTool.noClip = noClip
            compTool.skipContentBox = skipContentBox
            
            guard let screenshot = screenshotImage.asCGImage() else {
                throw BezelFramerError.failedToConvertImage
            }
            
            // Create the bezeled image using the bezel dimensions
            guard let outputImage = compTool.create(bezel: bezelImage, screenshot: screenshot) else {
                throw BezelFramerError.failedToAddBezelToScreenshot
            }
            cgImage = outputImage
        
   
        
        guard let nsImage = cgImage.asNSImage() else {
            throw BezelFramerError.failedToConvertImage
        }
        
        return nsImage
    }
}


// MARK: - Helper for getting the pixel resolution for an NSImage

private extension NSImage {
    /// Computes the actual pixel resolution of the image
    /// - Returns: CGSize containing the width and height in pixels
    var resolution: CGSize {
        
        guard let representation = self.representations.first else {
            return CGSize(width: self.size.width, height: self.size.height)
        }
        
        return CGSize(width: representation.pixelsWide, height: representation.pixelsHigh)
    }
}
