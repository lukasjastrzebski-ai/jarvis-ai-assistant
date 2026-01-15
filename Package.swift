// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Jarvis",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "JarvisCore",
            targets: ["JarvisCore"]
        ),
        .library(
            name: "JarvisShared",
            targets: ["JarvisShared"]
        ),
    ],
    dependencies: [
    ],
    targets: [
        // Core library - business logic
        .target(
            name: "JarvisCore",
            dependencies: [],
            path: "src/JarvisCore"
        ),
        // Shared UI components
        .target(
            name: "JarvisShared",
            dependencies: ["JarvisCore"],
            path: "src/JarvisShared"
        ),
        // Tests
        .testTarget(
            name: "JarvisCoreTests",
            dependencies: ["JarvisCore"],
            path: "tests/JarvisCoreTests"
        ),
        .testTarget(
            name: "JarvisSharedTests",
            dependencies: ["JarvisShared"],
            path: "tests/JarvisSharedTests"
        ),
    ]
)
