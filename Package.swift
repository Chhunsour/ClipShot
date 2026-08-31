// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClipShot",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "ClipShot",
            targets: ["ClipShot"]
        ),
        .library(
            name: "ClipShotCore",
            targets: ["ClipShotCore"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ClipShotCore",
            dependencies: [],
            path: "Sources/ClipShotCore",
            resources: []
        ),
        .executableTarget(
            name: "ClipShot",
            dependencies: ["ClipShotCore"],
            path: "Sources/ClipShotApp",
            exclude: ["Resources"]
        ),
        .testTarget(
            name: "ClipShotTests",
            dependencies: ["ClipShotCore"],
            path: "Tests/ClipShotTests"
        )
    ]
)
