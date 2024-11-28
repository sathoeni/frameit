// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "frameit",
    platforms: [
            .macOS(.v12)
        ],
    products: [
        .executable(name: "frameit", targets: ["frameit"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0")
    ],
    targets: [
        .executableTarget(
            name: "frameit",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            resources: [
                .copy("Resources/Roboto-Regular.ttf")
            ]
        )
    ]
)
