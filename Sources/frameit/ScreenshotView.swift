//
//  ScreenshotView.swift
//  frameit
//
//  Created by Sascha Thöni on 12.06.21.
//  Copyright © 2021 Helsana Versicherungen AG. All rights reserved.
//

import AppKit

// MARK: - ScreenshotView


/// A helper view to draw an image and a text into a single view
/// The position and insets of the image and text can be customized.
/// The label will be placed centered between the top of the image and the top of the view.
final class ScreenshotView: NSView {

    private var image: NSImage
    private var title: String
    private var insets: Insets
    private let font: NSFont

    private let fontName = "Roboto-Regular"
    private let textColor = NSColor(calibratedRed: 0.604, green: 0.035, blue: 0.255, alpha: 1.0)

    // MARK: Lifecycle

    init?(image: NSImage, title: String, fontSize: CGFloat, size: CGSize, insets: Insets) {
        self.image = image
        self.title = title
        self.insets = insets

        guard let customFont = NSFont(name: fontName, size: fontSize) else {
            print("*** ERROR: Font \"\(fontName)\" not found. Check if the font is installed with the Font Book app. You can find the font in the resource folder and install it by double-clicking.")
            return nil
        }
        self.font = customFont

        super.init(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height))
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {

        // Draw background
        NSColor.white.set()
        NSBezierPath.fill(dirtyRect)

        // Draw Image
        // The insets are treated as minimum insets.
        // Priority: bottom > top > left/right
        
        var imageScaleFactor = (frame.height - insets.top - insets.bottom) / image.size.height
        var scaledImageSize = CGSize(width: image.size.width * imageScaleFactor, height: image.size.height * imageScaleFactor)
        
        // If minimum horiztonal insets could not be fullfilled, use the horiztonal insets as reference
        if scaledImageSize.width + insets.left + insets.right > frame.width {
            imageScaleFactor = (frame.width - insets.left - insets.right) / image.size.width
            scaledImageSize = CGSize(width: image.size.width * imageScaleFactor, height: image.size.height * imageScaleFactor)
        }
        

        // Calculate position of the image
        let yImagePosition = insets.bottom
        let xImagePosition = max(insets.left, (frame.width - scaledImageSize.width) / 2)

        let imageRect = CGRect(origin: CGPoint(x: xImagePosition, y: yImagePosition), size: scaledImageSize)
        image.draw(in: imageRect, from: CGRect.zero, operation: .sourceOver, fraction: 1)

        // Draw Text
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle
        ]

        let attributedString = NSAttributedString(string: title, attributes: textAttributes)
        let maxTextWidth = frame.width - insets.left - insets.right
        var textRect = attributedString.boundingRect(with: CGSize(width: maxTextWidth, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin)

        // Position the text centered between the top edge and the image's top edge
        let xTextPosition = max(insets.left, (frame.width - textRect.width) / 2)
        let imageTopPosition = yImagePosition + scaledImageSize.height
        let yTextPosition = imageTopPosition + (frame.height - imageTopPosition - textRect.height) / 2

        textRect.origin = CGPoint(x: xTextPosition, y: yTextPosition)

        attributedString.draw(with: textRect, options: .usesLineFragmentOrigin)
    }
}

