//
//  CompositeImage.swift
//  FrameMe
//
//  Created by Josh Luongo on 13/12/2022.
//

import Foundation
import CoreImage
import ImageIO
import CoreGraphics

class CompositeImage {
    /// Don't do content box finding for screenshot positioning.
    var skipContentBox = false

    /// Don't clip the screenshot to the device frame.
    var noClip = false

    // Cached properties associated with bezel resolutions
    private var cachedScreenshotPositions: [String: CGRect] = [:]
    private var cachedOuterMattes: [String: CGImage] = [:]
    private let cacheQueue = DispatchQueue(label: "com.yourapp.CompositeImage.cacheQueue", attributes: .concurrent)
    
    /// Create a composite image from a frame and a screenshot.
    ///
    /// - Parameters:
    ///   - bezel: Device bezel
    ///   - screenshot: Screenshot
    /// - Returns: Composited Result
    func create(bezel: CGImage, screenshot: CGImage) -> CGImage? {
        return autoreleasepool {
            // Create a unique key for the bezel based on its resolution
            let bezelKey = "\(bezel.width)x\(bezel.height)"
            
            // Start a context with bezel dimensions
            guard let context = CGContext(
                data: nil,
                width: bezel.width,
                height: bezel.height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
                return nil
            }
            
            // Determine screenshot position
            let screenshotPosition: CGRect
            if skipContentBox {
                // Center the screenshot if skipping content box calculation
                screenshotPosition = CGRect(
                    x: (bezel.width - screenshot.width) / 2,
                    y: (bezel.height - screenshot.height) / 2,
                    width: screenshot.width,
                    height: screenshot.height
                )
            } else {
                // Retrieve or calculate the content box position
                if let cachedPosition = cacheQueue.sync(execute: { cachedScreenshotPositions[bezelKey] }) {
                    screenshotPosition = cachedPosition
                } else {
                    if let position = bezel.findContentBox(ref: CGPoint(x: bezel.width / 2, y: bezel.height / 2)) {
                        cacheQueue.async(flags: .barrier) {
                            self.cachedScreenshotPositions[bezelKey] = position
                        }
                        screenshotPosition = position
                    } else {
                        // Fallback to centered position if content box not found
                        screenshotPosition = CGRect(
                            x: (bezel.width - screenshot.width) / 2,
                            y: (bezel.height - screenshot.height) / 2,
                            width: screenshot.width,
                            height: screenshot.height
                        )
                    }
                }
            }
            
            if noClip {
                // Draw screenshot without clipping
                context.draw(screenshot, in: screenshotPosition)
            } else {
                // Clip the screenshot and draw it
                if let clippedImage = clipImage(mask: bezel, image: screenshot, frame: screenshotPosition, bezelKey: bezelKey) {
                    context.draw(clippedImage, in: CGRect(
                        origin: .zero,
                        size: CGSize(width: bezel.width, height: bezel.height)
                    ))
                }
            }
            
            // Draw the device frame over the screenshot
            context.draw(bezel, in: CGRect(
                origin: .zero,
                size: CGSize(width: bezel.width, height: bezel.height)
            ))
            
            return context.makeImage()
        }
    }
    
    /// Clip the image using the bezel's mask.
    ///
    /// - Parameters:
    ///   - mask: The bezel mask.
    ///   - image: The screenshot image.
    ///   - frame: The frame where the screenshot should be placed.
    ///   - bezelKey: Unique key for caching.
    /// - Returns: Clipped CGImage.
    private func clipImage(mask: CGImage, image: CGImage, frame: CGRect, bezelKey: String) -> CGImage? {
        return autoreleasepool {
            // Retrieve or create the outer matte mask
            let matteMask: CGImage = cacheQueue.sync {
                if let cachedMatte = cachedOuterMattes[bezelKey] {
                    return cachedMatte
                } else {
                    let matte = mask.createOuterMatte()
                    if let matte = matte {
                        cacheQueue.async(flags: .barrier) {
                            self.cachedOuterMattes[bezelKey] = matte
                        }
                        return matte
                    } else {
                        return mask // Fallback to mask if matte creation fails
                    }
                }
            }
            
            // Start a context for clipping
            guard let context = CGContext(
                data: nil,
                width: mask.width,
                height: mask.height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
                return nil
            }
            
            // Apply the matte mask
            context.clip(to: CGRect(x: 0, y: 0, width: mask.width, height: mask.height), mask: matteMask)
            
            // Draw the screenshot within the clipped context
            context.draw(image, in: frame)
            
            return context.makeImage()
        }
    }
}
