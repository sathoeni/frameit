//
//  Insets.swift
//  frameit
//
//  Created by Sascha Thöni on 16.12.2024.
//

import Foundation

struct Insets: Codable {
    var top: CGFloat
    var left: CGFloat
    var bottom: CGFloat
    var right: CGFloat

    init(top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat) {
        self.top = top
        self.left = left
        self.bottom = bottom
        self.right = right
    }
}
