#!/usr/bin/env swift
import Foundation
import CoreGraphics
import ImageIO

print("--- ClipShot: ImageIO DPI & Scale Factor Analyzer ---")

struct ImageResolutionProfile {
    let filename: String
    let pixelWidth: Int
    let pixelHeight: Int
    let dpiX: Double
    let dpiY: Double

    var scaleFactor: Double {
        // Standard macOS 1x baseline is 72.0 DPI
        dpiX / 72.0
    }

    var pointSize: CGSize {
        CGSize(
            width: Double(pixelWidth) / scaleFactor,
            height: Double(pixelHeight) / scaleFactor
        )
    }

    var isRetina: Bool {
        scaleFactor >= 1.9
    }
}

let simulatedProfiles: [ImageResolutionProfile] = [
    ImageResolutionProfile(filename: "screenshot_standard_1x.png", pixelWidth: 1440, pixelHeight: 900, dpiX: 72.0, dpiY: 72.0),
    ImageResolutionProfile(filename: "screenshot_retina_2x.png", pixelWidth: 2880, pixelHeight: 1800, dpiX: 144.0, dpiY: 144.0),
    ImageResolutionProfile(filename: "screenshot_liquid_xdr_2x.png", pixelWidth: 3456, pixelHeight: 2234, dpiX: 144.0, dpiY: 144.0),
    ImageResolutionProfile(filename: "screenshot_iphone_3x.png", pixelWidth: 1170, pixelHeight: 2532, dpiX: 216.0, dpiY: 216.0),
    ImageResolutionProfile(filename: "print_proof_300dpi.tiff", pixelWidth: 2550, pixelHeight: 3300, dpiX: 300.0, dpiY: 300.0)
]

for profile in simulatedProfiles {
    print("File: [\(profile.filename)]")
    print("  Pixel Buffer: \(profile.pixelWidth) × \(profile.pixelHeight) px")
    print(String(format: "  Resolution:   %.1f × %.1f DPI", profile.dpiX, profile.dpiY))
    print(String(format: "  Scale Factor: %.1fx (%@)", profile.scaleFactor, profile.isRetina ? "Retina / HiDPI" : "Standard 1x"))
    print(String(format: "  Point Canvas: %.1f × %.1f pt\n", profile.pointSize.width, profile.pointSize.height))
}
