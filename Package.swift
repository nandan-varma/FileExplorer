// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "explorer",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/inket/FullDiskAccess.git", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "explorer",
            dependencies: ["FullDiskAccess"],
            path: "Sources",
            exclude: ["Resources/Info.plist", "Resources/explorer.entitlements"]
        ),
    ]
)
