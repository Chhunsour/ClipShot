#!/usr/bin/env swift
import Foundation

print("--- ClipShot: WCAG 2.1 Relative Luminance & Contrast Analyzer ---")

struct RGBColor {
    let name: String
    let r: Double // 0.0 - 1.0
    let g: Double
    let b: Double

    init(name: String, hex: String) {
        self.name = name
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") { cleaned.removeFirst() }
        let scanner = Scanner(string: cleaned)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        self.r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        self.g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        self.b = Double(rgbValue & 0x0000FF) / 255.0
    }

    /// Calculate linearized sRGB channel according to WCAG 2.1 definition
    private func linearize(_ channel: Double) -> Double {
        if channel <= 0.04045 {
            return channel / 12.92
        } else {
            return pow((channel + 0.055) / 1.055, 2.4)
        }
    }

    /// Computes the relative luminance of a color, normalized to 0.0 for darkest black and 1.0 for lightest white
    var relativeLuminance: Double {
        let rLin = linearize(r)
        let gLin = linearize(g)
        let bLin = linearize(b)
        return 0.2126 * rLin + 0.7152 * gLin + 0.0722 * bLin
    }

    /// Computes contrast ratio against another color (WCAG formula: (L1 + 0.05) / (L2 + 0.05))
    func contrastRatio(against other: RGBColor) -> Double {
        let l1 = self.relativeLuminance
        let l2 = other.relativeLuminance
        let lighter = max(l1, l2)
        let darker = min(l1, l2)
        return (lighter + 0.05) / (darker + 0.05)
    }

    /// Determines optimal label text color (White or Black) for loupe readout
    var recommendedOverlayText: (text: String, ratio: Double) {
        let white = RGBColor(name: "White", hex: "#FFFFFF")
        let black = RGBColor(name: "Black", hex: "#000000")
        let whiteRatio = self.contrastRatio(against: white)
        let blackRatio = self.contrastRatio(against: black)

        if whiteRatio >= blackRatio {
            return ("#FFFFFF (White)", whiteRatio)
        } else {
            return ("#000000 (Black)", blackRatio)
        }
    }
}

let sampleColors: [RGBColor] = [
    RGBColor(name: "Pure White", hex: "#FFFFFF"),
    RGBColor(name: "Near Black", hex: "#111111"),
    RGBColor(name: "ClipShot Navy", hex: "#1E293B"),
    RGBColor(name: "Vibrant Cyan", hex: "#06B6D4"),
    RGBColor(name: "Electric Violet", hex: "#8B5CF6"),
    RGBColor(name: "Warning Amber", hex: "#F59E0B"),
    RGBColor(name: "Emerald Green", hex: "#10B981"),
    RGBColor(name: "Midtone Slate Gray", hex: "#64748B"),
    RGBColor(name: "Soft Canary Yellow", hex: "#FEF08A"),
    RGBColor(name: "Deep Crimson", hex: "#991B1B")
]

print(String(format: "%-20@ %-12@ %-14@ %-18@ %-16@", "Color Sample", "Luminance", "Contrast (W)", "Contrast (B)", "Optimal Overlay"))
print(String(repeating: "-", count: 84))

for c in sampleColors {
    let lum = c.relativeLuminance
    let white = RGBColor(name: "White", hex: "#FFFFFF")
    let black = RGBColor(name: "Black", hex: "#000000")
    let contrastW = c.contrastRatio(against: white)
    let contrastB = c.contrastRatio(against: black)
    let optimal = c.recommendedOverlayText

    print(String(format: "%-20@ %-12.4f %-14.2f %-18.2f %-18@",
                 c.name, lum, contrastW, contrastB, "\(optimal.text) (\(String(format: "%.1f:1", optimal.ratio)))"))
}

print("\n--- WCAG Compliance Check (4.5:1 AA threshold) ---")
for c in sampleColors {
    let optimal = c.recommendedOverlayText
    let meetsAA = optimal.ratio >= 4.5
    let status = meetsAA ? "✓ PASS" : "⚠ CAUTION (Needs text stroke / drop shadow)"
    print("• \(c.name): \(status) [\(String(format: "%.1f:1", optimal.ratio))]")
}

print("\nArchitectural Rationale: Dynamic relative luminance calculation in LoupeOverlayView ensures crosshair hexadecimal labels remain legible across arbitrary desktop pixel backgrounds without clipping or contrast inversion.")
