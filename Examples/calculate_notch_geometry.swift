#!/usr/bin/env swift
import Foundation
import CoreGraphics

print("--- ClipShot: ClipNotch Geometry & Dimensions ---")

struct NotchSizePreset {
    let name: String
    let baseWidth: CGFloat
    let baseHeight: CGFloat
    let bottomCornerRadius: CGFloat
    let topWingRadius: CGFloat

    var idleDimensions: CGSize {
        CGSize(width: baseWidth * 1.12, height: baseHeight * 1.12)
    }
}

let presets: [NotchSizePreset] = [
    NotchSizePreset(name: "Compact", baseWidth: 184, baseHeight: 34, bottomCornerRadius: 14 * 1.12, topWingRadius: 9 * 1.12),
    NotchSizePreset(name: "Normal", baseWidth: 224, baseHeight: 36, bottomCornerRadius: 16 * 1.12, topWingRadius: 10 * 1.12),
    NotchSizePreset(name: "Large", baseWidth: 260, baseHeight: 38, bottomCornerRadius: 17 * 1.12, topWingRadius: 11 * 1.12),
    NotchSizePreset(name: "Extra Large", baseWidth: 310, baseHeight: 41, bottomCornerRadius: 18 * 1.12, topWingRadius: 12 * 1.12),
    NotchSizePreset(name: "Ultra Wide", baseWidth: 390, baseHeight: 43, bottomCornerRadius: 19 * 1.12, topWingRadius: 13 * 1.12),
    NotchSizePreset(name: "Studio / Max", baseWidth: 480, baseHeight: 45, bottomCornerRadius: 20 * 1.12, topWingRadius: 14 * 1.12)
]

for preset in presets {
    let dims = preset.idleDimensions
    print("Preset: [\(preset.name)]")
    print(String(format: "  Dimensions: %.1f pt × %.1f pt", dims.width, dims.height))
    print(String(format: "  Bottom Corner Radius: %.1f pt", preset.bottomCornerRadius))
    print(String(format: "  Top Wing Radius:      %.1f pt", preset.topWingRadius))
}
