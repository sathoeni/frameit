//
//  ScreenshotView.swift
//  AppStoreScreenshotGenerator
//
//  Created by Sascha Thöni on 12.06.21.
//  Copyright © 2021 Helsana Versicherungen AG. All rights reserved.
//

import AppKit

// MARK: - ScreenshotView

final class ScreenshotView: NSView {

    private var imageURL: URL
    private var title: String
    private var horizontalPadding: CGFloat
    private var topImageOffset: CGFloat
    private let font: NSFont

    private let fontName = "Roboto-Regular"
    private let textColor = NSColor(calibratedRed: 0.604, green: 0.035, blue: 0.255, alpha: 1.0)

    // MARK: Lifecycle

    init?(imageURL: URL, title: String, fontSize: CGFloat, size: CGSize, horizontalImagePadding: Double, topImageOffset: Double) {
        self.imageURL = imageURL
        self.title = title
        self.topImageOffset = CGFloat(topImageOffset)
        horizontalPadding = CGFloat(horizontalImagePadding)

        guard let customFont = NSFont(name: fontName, size: fontSize) else {
            print("*** ERROR: Font \"\(fontName)\" not found. Check if font is installed with the font book app. You can find the app in the resource folder. Install it by double click")
            return nil
        }
        font = customFont

        super.init(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height))

        // frame = convertFromBacking(frame)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {

        // Draw background
        NSColor.white.set()
        NSBezierPath.fill(dirtyRect)

        // Draw Image
        guard let image = NSImage(contentsOfFile: imageURL.path) else { return }

        let imagePreferredWidth = frame.width - CGFloat(horizontalPadding * 2)
        let imageScaleFactor = imagePreferredWidth / image.size.width
        image.size = CGSize(width: image.size.width * imageScaleFactor, height: image.size.height * imageScaleFactor)

        // Calculate position of topLeft edge
        let xImagePosition = (frame.width - image.size.width) / 2
        let yImagePosition = -topImageOffset

        let imagePosition = CGPoint(x: xImagePosition, y: yImagePosition)
        image.draw(at: imagePosition, from: CGRect.zero, operation: NSCompositingOperation.sourceOver, fraction: 1)

        // Draw Text
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let textAttributes = [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: textColor, NSAttributedString.Key.paragraphStyle: paragraphStyle]

        let attributedString = NSAttributedString(string: title, attributes: textAttributes)
        let maxTextWidth = frame.width - 2 * horizontalPadding
        var textRect = attributedString.boundingRect(with: CGSize(width: maxTextWidth, height: 0.0), options: .usesLineFragmentOrigin)

        // Position the Text centered between top edge and screenshots top edge
        let xTextPosition = (frame.width - textRect.width) / 2
        let imageTopPosition = imagePosition.y + image.size.height
        let yTextPosition = imageTopPosition + (frame.height - imageTopPosition - textRect.height) / 2

        textRect.origin = CGPoint(x: xTextPosition, y: yTextPosition)

        attributedString.draw(with: textRect, options: .usesLineFragmentOrigin)
    }
}
