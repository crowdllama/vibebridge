// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VibeBridge",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "vibebridge",
            targets: ["VibeBridge"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/httpswift/swifter.git", from: "1.5.0")
    ],
    targets: [
        .executableTarget(
            name: "VibeBridge",
            dependencies: [
                .product(name: "Swifter", package: "swifter")
            ],
            path: "Sources/VibeBridge",
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"])
            ]
        ),
        .testTarget(
            name: "VibeBridgeTests",
            dependencies: ["VibeBridge"],
            path: "Tests/VibeBridgeTests"
        ),
    ]
) 