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

    /// Create a composite image from a frame and a screenshot.
    ///
    /// - Parameters:
    ///   - frame: Device Bezel
    ///   - screenshot: Screenshot
    /// - Returns: Composited Result
    func create(bezel: CGImage, screenshot: CGImage) -> CGImage? {
        // Start a context with bezel dimensions
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let context = CGContext(
            data: nil,
            width: bezel.width,
            height: bezel.height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        )
        
        // Should we try and find the screenshot position data?
        let screenshotPosition = skipContentBox ? nil : bezel.findContentBox(ref: CGPoint(x: bezel.width / 2, y: bezel.height / 2))

        // Draw screenshot
        if noClip {
            // Don't use the clipping tool.
            context?.draw(screenshot, in: screenshotPosition ?? CGRect(
                origin: CGPoint(x: ((bezel.width - screenshot.width) / 2), 
                                y: ((bezel.height - screenshot.height) / 2)), 
                size: CGSize(width: screenshot.width, height: screenshot.height)
            ))
        } else {
            // Clip the screenshot
            if let clippedImage = clipImage(mask: bezel, image: screenshot, frame: screenshotPosition) {
                context?.draw(clippedImage, in: CGRect(
                    origin: .zero,
                    size: CGSize(width: bezel.width, height: bezel.height)
                ))
            }
        }

        // Draw the device frame
        context?.draw(bezel, in: CGRect(
            origin: .zero,
            size: CGSize(width: bezel.width, height: bezel.height)
        ))

        return context?.makeImage()
    }

    // Keep the clipImage function as is
    private func clipImage(mask: CGImage, image: CGImage, frame: CGRect? = nil) -> CGImage? {
        // Start a context
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let context = CGContext(data: nil, width: mask.width, height: mask.height, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)

        // Create the outer matte.
        if let mask = mask.createOuterMatte() {
            // Apply the matte
            context?.clip(to: CGRect(x: 0, y: 0, width: mask.width, height: mask.height), mask: mask)
        }

        // Draw screenshot.
        context?.draw(image, in: frame ?? CGRect(origin: CGPoint(x: ((mask.width - image.width) / 2), y: ((mask.height - image.height) / 2)), size: CGSize(width: image.width, height: image.height)))

        return context?.makeImage()
    }

}
