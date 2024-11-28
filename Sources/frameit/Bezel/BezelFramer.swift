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

struct BezelFramer {
    
    static func addBezel(screenshotImage: NSImage, skipContentBox: Bool = false, noClip: Bool = false, frame: String? = nil) throws -> NSImage {
        // Load the frame
        let bezelImage: CGImage
        
        if let framePath = frame {
            guard let loadedFrame = CGImage.loadImage(filename: framePath) else {
                throw BezelFramerError.failedToLoadLocalBezel
            }
            bezelImage = loadedFrame
        } else {
            // Try to find matching bezel
            let bezelResolver = try BezelResolver()
            
            let size = CGSize(width: screenshotImage.size.width, height: screenshotImage.size.height)
            guard let bezelPath = try bezelResolver.findBezel(forScreenshotSize: size) else {
                throw BezelFramerError.noMatchingBezelFound
            }
            
            guard let loadedBezel = CGImage.loadImage(url: bezelPath) else {
                throw BezelFramerError.failedToLoadRemoteBezel
            }
            bezelImage = loadedBezel
        }
        
        // Load the composite class.
        let compTool = CompositeImage()
        compTool.noClip = noClip
        compTool.skipContentBox = skipContentBox
        
        guard let screenshot = screenshotImage.asCGImage() else {
            throw BezelFramerError.failedToConvertImage
        }
        
        // Create the bezeled image using the bezel dimensions
        guard let cgImage = compTool.create(bezel: bezelImage, screenshot: screenshot) else {
            throw BezelFramerError.failedToAddBezelToScreenshot
        }
        
        guard let nsImage = cgImage.asNSImage() else {
            throw BezelFramerError.failedToConvertImage
        }
        
        return nsImage
    }
}
