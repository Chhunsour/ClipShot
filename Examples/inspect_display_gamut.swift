#!/usr/bin/env swift
import Foundation
import AppKit
import CoreGraphics

print("--- ClipShot: Display P3 vs sRGB Color Gamut & Primaries Inspector ---")

struct ChromaticityPoint {
    let x: Double
    let y: Double
}

struct ColorSpaceSpec {
    let name: String
    let red: ChromaticityPoint
    let green: ChromaticityPoint
    let blue: ChromaticityPoint
    let whitePoint: ChromaticityPoint

    // Calculates 2D CIE 1931 xy triangle gamut area
    var gamutArea: Double {
        0.5 * abs(red.x * (green.y - blue.y) + green.x * (blue.y - red.y) + blue.x * (red.y - green.y))
    }
}

let sRGB = ColorSpaceSpec(
    name: "sRGB (ITU-R BT.709)",
    red: ChromaticityPoint(x: 0.640, y: 0.330),
    green: ChromaticityPoint(x: 0.300, y: 0.600),
    blue: ChromaticityPoint(x: 0.150, y: 0.060),
    whitePoint: ChromaticityPoint(x: 0.3127, y: 0.3290)
)

let displayP3 = ColorSpaceSpec(
    name: "Display P3 (Apple Wide Color)",
    red: ChromaticityPoint(x: 0.680, y: 0.320),
    green: ChromaticityPoint(x: 0.265, y: 0.690),
    blue: ChromaticityPoint(x: 0.150, y: 0.060),
    whitePoint: ChromaticityPoint(x: 0.3127, y: 0.3290)
)

print("1. CIE 1931 xy Chromaticity Coordinates:")
for spec in [sRGB, displayP3] {
    print("• \(spec.name):")
    print(String(format: "  Red:   (%.3f, %.3f)", spec.red.x, spec.red.y))
    print(String(format: "  Green: (%.3f, %.3f)", spec.green.x, spec.green.y))
    print(String(format: "  Blue:  (%.3f, %.3f)", spec.blue.x, spec.blue.y))
    print(String(format: "  White: (%.4f, %.4f)", spec.whitePoint.x, spec.whitePoint.y))
    print(String(format: "  Gamut Triangle Area: %.5f", spec.gamutArea))
}

let coverageRatio = (displayP3.gamutArea / sRGB.gamutArea - 1.0) * 100.0
print(String(format: "\nWide Color Advantage: Display P3 offers +%.1f%% wider chromatic volume than standard sRGB.\n", coverageRatio))

print("2. Connected Active macOS Screens Color Profile Query:")
for (index, screen) in NSScreen.screens.enumerated() {
    let name = screen.localizedName
    let csName = screen.colorSpace?.localizedName ?? "Generic"
    let isWide = screen.canRepresent(.p3)
    print("  Screen #\(index): \(name)")
    print("    ColorSpace: \(csName)")
    print("    Supports Display P3 Wide Gamut: \(isWide ? "YES ✅" : "NO ⚠️")")
    print("    Backing Scale Factor: \(screen.backingScaleFactor)x")
}

print("\n3. Gamut Conversion & Clipping Demonstration:")
// Saturated Display P3 Red (1.0, 0.0, 0.0) converted into sRGB
if let p3ColorSpace = CGColorSpace(name: CGColorSpace.displayP3),
   let srgbColorSpace = CGColorSpace(name: CGColorSpace.sRGB) {
    let p3Red: [CGFloat] = [1.0, 0.0, 0.0, 1.0]
    if let cgColor = CGColor(colorSpace: p3ColorSpace, components: p3Red),
       let converted = cgColor.converted(to: srgbColorSpace, intent: .defaultIntent, options: nil),
       let components = converted.components {
        print(String(format: "  Display P3 Pure Red (1.0, 0.0, 0.0) -> sRGB (r: %.3f, g: %.3f, b: %.3f)",
                     components[0], components[1], components[2]))
        if components[0] > 1.0 || components[1] < 0.0 {
            print("  ⚠️ Notice: Converted values exceed [0.0...1.0], proving the P3 red is out-of-gamut in sRGB!")
        }
    }
}
