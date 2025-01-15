//
//  DeviceBezelsData.swift
//  frameit
//
//  Created by Sascha Thöni on 26.11.2024.
//

import Foundation

struct DeviceBezelsData: Codable {
    let devices: [DeviceModel]
    let metadata: Metadata
    
    struct DeviceModel: Codable {
        let name: String            // e.g. "iPhone 16 Pro"
        let id: String
        let resolution: Resolution
        let frames: [Frame]
        
        struct Resolution: Codable {
            let width: Int
            let height: Int
        }
        
        struct Frame: Codable {
            let color: String       // e.g. "black-titanium"
            let orientation: Orientation
            let path: String        // e.g. "bezels/apple/iphone/..."
        }
        
        enum Orientation: String, Codable {
            case portrait
            case landscape
        }
    }
    
    struct Metadata: Codable {
        let version: String
        let lastUpdated: String
        let description: String
        let sources: [String]
    }
}
