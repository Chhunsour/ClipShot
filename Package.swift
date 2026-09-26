// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClipShot",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        // Main macOS menu bar application executable
        .executable(
            name: "ClipShot",
            targets: ["ClipShot"]
        ),
        // Modular core framework containing capture engine, ClipNotch, and clipboard services
        .library(
            name: "ClipShotCore",
            targets: ["ClipShotCore"]
        )
    ],
    dependencies: [],
    targets: [
        // Core functionality: FSEvents monitor, ScreenCaptureKit, Vision OCR, ClipNotch
        .target(
            name: "ClipShotCore",
            dependencies: [],
            path: "Sources/ClipShotCore",
            resources: []
        ),
        // App lifecycle, menu bar controller, and application entry point
        .executableTarget(
            name: "ClipShot",
            dependencies: ["ClipShotCore"],
            path: "Sources/ClipShotApp",
            exclude: ["Resources"]
        ),
        // Unit and integration test suite
        .testTarget(
            name: "ClipShotTests",
            dependencies: ["ClipShotCore"],
            path: "Tests/ClipShotTests"
        )
    ]
)
