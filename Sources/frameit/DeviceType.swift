//
//  Device.swift
//  AppStoreScreenshotGenerator
//
//  Created by Sascha Thöni on 01.06.21.
//  Copyright © 2021 Helsana Versicherungen AG. All rights reserved.
//

import Foundation

struct DeviceType {
    let id: String
    let screenDiagonal: String
    let screenshotSize: CGSize
    
    static let allDevices: [DeviceType] = [
        // iPhone 16 series
        DeviceType(id: "iPhone16ProMax", screenDiagonal: "6.9", 
                  screenshotSize: CGSize(width: 1320, height: 2868)),
        DeviceType(id: "iPhone16Pro", screenDiagonal: "6.3", 
                  screenshotSize: CGSize(width: 1206, height: 2622)),
        DeviceType(id: "iPhone16Plus", screenDiagonal: "6.7", 
                  screenshotSize: CGSize(width: 1290, height: 2796)),
        DeviceType(id: "iPhone16", screenDiagonal: "6.1", 
                  screenshotSize: CGSize(width: 1179, height: 2556)),
        
        // iPhone 15 series
        DeviceType(id: "iPhone15ProMax", screenDiagonal: "6.7", 
                  screenshotSize: CGSize(width: 1290, height: 2796)),
        DeviceType(id: "iPhone15Pro", screenDiagonal: "6.1", 
                  screenshotSize: CGSize(width: 1179, height: 2556)),
        DeviceType(id: "iPhone15Plus", screenDiagonal: "6.7", 
                  screenshotSize: CGSize(width: 1290, height: 2796)),
        DeviceType(id: "iPhone15", screenDiagonal: "6.1", 
                  screenshotSize: CGSize(width: 1179, height: 2556)),
        
        // iPhone 14 series
        DeviceType(id: "iPhone14ProMax", screenDiagonal: "6.7", 
                  screenshotSize: CGSize(width: 1290, height: 2796)),
        DeviceType(id: "iPhone14Pro", screenDiagonal: "6.1", 
                  screenshotSize: CGSize(width: 1179, height: 2556)),
        
        // Older models...
        DeviceType(id: "iPhone12ProMax", screenDiagonal: "6.5", 
                  screenshotSize: CGSize(width: 1284, height: 2778)),
        DeviceType(id: "iPhone12Pro", screenDiagonal: "5.8", 
                  screenshotSize: CGSize(width: 1170, height: 2532)),
        DeviceType(id: "iPhone8Plus", screenDiagonal: "5.5", 
                  screenshotSize: CGSize(width: 1242, height: 2208)),
        DeviceType(id: "iPhone8", screenDiagonal: "4.7", 
                  screenshotSize: CGSize(width: 750, height: 1334)),
        DeviceType(id: "iPhoneSE_1thGen", screenDiagonal: "4.0", 
                  screenshotSize: CGSize(width: 640, height: 1096)),
        DeviceType(id: "iPhone4s", screenDiagonal: "3.5", 
                  screenshotSize: CGSize(width: 640, height: 920)),
        
        // iPads
        DeviceType(id: "iPadPro12_9_2ndGen", screenDiagonal: "12.9", 
                  screenshotSize: CGSize(width: 2048, height: 2732)),
        DeviceType(id: "iPadPro12_9_4thGen", screenDiagonal: "12.9_4th", 
                  screenshotSize: CGSize(width: 2048, height: 2732)),
        DeviceType(id: "iPadPro11_0", screenDiagonal: "11.0", 
                  screenshotSize: CGSize(width: 1668, height: 2388)),
        DeviceType(id: "iPadAir", screenDiagonal: "10.5", 
                  screenshotSize: CGSize(width: 1668, height: 2224)),
        DeviceType(id: "iPadMini", screenDiagonal: "9.7", 
                  screenshotSize: CGSize(width: 1536, height: 2008))
    ]
    
    static func detect(from size: CGSize) -> DeviceType? {
        return allDevices.first { device in
            device.screenshotSize.width == size.width && 
            device.screenshotSize.height == size.height
        }
    }
}

