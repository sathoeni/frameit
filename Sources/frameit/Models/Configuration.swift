struct DeviceConfiguration: Codable {
    let horizontalPadding: Double
    let topScreenshotOffset: Double
    let fontSize: Double
}

struct TextConfiguration: Codable {
    let localeCode: String
    let viewID: String
    let title: String
}

struct FrameitConfiguration: Codable {
    let devices: [String: DeviceConfiguration]
    let texts: [TextConfiguration]
} 