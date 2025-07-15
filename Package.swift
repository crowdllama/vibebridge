// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VibeBridge",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .executable(
            name: "vibebridge",
            targets: ["VibeBridge"]
        ),
    ],
    dependencies: [
        // Add any external dependencies here if needed
    ],
    targets: [
        .executableTarget(
            name: "VibeBridge",
            dependencies: [],
            path: "Sources/VibeBridge"
        ),
        .testTarget(
            name: "VibeBridgeTests",
            dependencies: ["VibeBridge"],
            path: "Tests/VibeBridgeTests"
        ),
    ]
) 