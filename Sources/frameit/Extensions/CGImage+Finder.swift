//
//  CGImage+Finder.swift
//
//  Created by Josh Luongo on 14/12/2022.
//

import Foundation
import CoreImage
import CoreGraphics

extension CGImage {
    
    /// Find a content box from a reference point.
    ///
    /// - Parameter ref: Reference Point
    /// - Returns: CGRect of the position of the content box.
    public func findContentBox(ref: CGPoint) -> CGRect? {
        guard let dataProvider = self.dataProvider,
              let cfData = dataProvider.data,
              let pointer = CFDataGetBytePtr(cfData) else {
            return nil
        }
        
        let bytesPerRow = self.bytesPerRow
        
        let width = self.width
        let height = self.height
        
        // Helper to calculate pixel index
        func pixelAddress(x: Int, y: Int) -> Int {
            return y * bytesPerRow + x * 4 // Assuming RGBA
        }
        
        // Find preliminary edges
        guard let prelimMinY = findYEdge(pointer: pointer, x: Int(ref.x), startingY: Int(ref.y), negative: true, width: width, bytesPerRow: bytesPerRow),
              let prelimMaxY = findYEdge(pointer: pointer, x: Int(ref.x), startingY: Int(ref.y), negative: false, width: width, bytesPerRow: bytesPerRow),
              let prelimMinX = findXEdge(pointer: pointer, y: Int(ref.y), startingX: Int(ref.x), negative: true, width: width, bytesPerRow: bytesPerRow),
              let prelimMaxX = findXEdge(pointer: pointer, y: Int(ref.y), startingX: Int(ref.x), negative: false, width: width, bytesPerRow: bytesPerRow) else {
            return nil
        }
        
        var finalMinY = prelimMinY
        var finalMaxY = prelimMaxY
        var finalMinX = prelimMinX
        var finalMaxX = prelimMaxX
        
        // Refine Y boundaries by iterating over X
        for x in finalMinX..<finalMaxX {
            if let yMin = findYEdge(pointer: pointer, x: x, startingY: Int(ref.y), negative: true, width: width, bytesPerRow: bytesPerRow),
               yMin < finalMinY {
                finalMinY = yMin
            }
            if let yMax = findYEdge(pointer: pointer, x: x, startingY: Int(ref.y), negative: false, width: width, bytesPerRow: bytesPerRow),
               yMax > finalMaxY {
                finalMaxY = yMax
            }
        }
        
        // Refine X boundaries by iterating over Y
        for y in finalMinY..<finalMaxY {
            if let xMin = findXEdge(pointer: pointer, y: y, startingX: Int(ref.x), negative: true, width: width, bytesPerRow: bytesPerRow),
               xMin < finalMinX {
                finalMinX = xMin
            }
            if let xMax = findXEdge(pointer: pointer, y: y, startingX: Int(ref.x), negative: false, width: width, bytesPerRow: bytesPerRow),
               xMax > finalMaxX {
                finalMaxX = xMax
            }
        }
        
        // Calculate width and height
        let boxWidth = finalMaxX - finalMinX
        let boxHeight = finalMaxY - finalMinY
        
        // Ensure positive dimensions
        guard boxWidth > 0, boxHeight > 0 else {
            return nil
        }
        
        // Flip the Y axis to compensate for macOS being Lower Left Origin
        let flippedMinY = height - finalMaxY
        
        return CGRect(x: finalMinX, y: flippedMinY, width: boxWidth, height: boxHeight)
    }
    
    /// Find the X edge in a direction.
    ///
    /// - Parameters:
    ///   - pointer: Data Pointer
    ///   - y: The Y position
    ///   - startingX: Starting X position
    ///   - negative: Should we search to the left (true) or right (false)?
    ///   - width: Image width
    ///   - bytesPerRow: Bytes per row
    /// - Returns: The X position of the edge.
    fileprivate func findXEdge(pointer: UnsafePointer<UInt8>, y: Int, startingX xPos: Int, negative: Bool, width: Int, bytesPerRow: Int) -> Int? {
        let start = negative ? xPos - 1 : xPos
        let end = negative ? -1 : width
        let step = negative ? -1 : 1
        
        for x in stride(from: start, through: end, by: step) {
            if x < 0 || x >= width {
                break
            }
            let addr = y * bytesPerRow + x * 4 // Assuming RGBA
            if pointer[addr + 3] == 255 { // Alpha channel
                return x + 1
            }
        }
        return nil
    }
    
    /// Find the Y edge in a direction.
    ///
    /// - Parameters:
    ///   - pointer: Data Pointer
    ///   - x: The X position
    ///   - startingY: Starting Y position
    ///   - negative: Should we search upwards (true) or downwards (false)?
    ///   - width: Image width
    ///   - bytesPerRow: Bytes per row
    /// - Returns: The Y position of the edge.
    fileprivate func findYEdge(pointer: UnsafePointer<UInt8>, x: Int, startingY yPos: Int, negative: Bool, width: Int, bytesPerRow: Int) -> Int? {
        let start = negative ? yPos - 1 : yPos
        let end = negative ? -1 : height
        let step = negative ? -1 : 1
        
        for y in stride(from: start, through: end, by: step) {
            if y < 0 || y >= height {
                break
            }
            let addr = y * bytesPerRow + x * 4 // Assuming RGBA
            if pointer[addr + 3] == 255 { // Alpha channel
                return y + 1
            }
        }
        return nil
    }
}

struct XYPosHolder {
    var minY: Int?
    var maxY: Int?
    var minX: Int?
    var maxX: Int?
}
