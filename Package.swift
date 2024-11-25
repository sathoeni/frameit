// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "frameit",
    platforms: [
            .macOS(.v10_12)
        ],
    products: [
        .executable(name: "frameit", targets: ["frameit"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "frameit",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            resources: [
                .copy("Roboto-Regular.ttf")
            ]
        )
    ]
)
