#!/usr/bin/env swift
import Foundation
import CoreGraphics

print("--- ClipShot: WCAG 2.1 Relative Luminance & Contrast Ratio Calculator ---")

struct RGBColor {
    let r: Double // 0...1
    let g: Double // 0...1
    let b: Double // 0...1

    var relativeLuminance: Double {
        func sRGBtoLinear(_ c: Double) -> Double {
            c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        let lr = sRGBtoLinear(r)
        let lg = sRGBtoLinear(g)
        let lb = sRGBtoLinear(b)
        return 0.2126 * lr + 0.7152 * lg + 0.0722 * lb
    }

    static func contrastRatio(between c1: RGBColor, and c2: RGBColor) -> Double {
        let l1 = c1.relativeLuminance
        let l2 = c2.relativeLuminance
        let lighter = max(l1, l2)
        let darker = min(l1, l2)
        return (lighter + 0.05) / (darker + 0.05)
    }
}

let white = RGBColor(r: 1.0, g: 1.0, b: 1.0)
let black = RGBColor(r: 0.0, g: 0.0, b: 0.0)
let macAccentBlue = RGBColor(r: 0.0, g: 0.478, b: 1.0)
let darkNotchBackground = RGBColor(r: 14.0/255.0, g: 15.0/255.0, b: 18.0/255.0)
let secondaryTextGray = RGBColor(r: 0.6, g: 0.6, b: 0.6)

let comparisons: [(name: String, foreground: RGBColor, background: RGBColor)] = [
    ("White Text on Dark Notch Surface", white, darkNotchBackground),
    ("Secondary Gray Text on Dark Notch Surface", secondaryTextGray, darkNotchBackground),
    ("Accent Blue on Dark Notch Surface", macAccentBlue, darkNotchBackground),
    ("Accent Blue on White Background", macAccentBlue, white),
    ("Black Text on White Background", black, white)
]

for item in comparisons {
    let ratio = RGBColor.contrastRatio(between: item.foreground, and: item.background)
    let passesAA = ratio >= 4.5
    let passesAAA = ratio >= 7.0
    print("Pair: [\(item.name)]")
    print(String(format: "  Contrast Ratio: %.2f:1", ratio))
    print("  WCAG AA (≥ 4.5:1):  [\(passesAA ? "PASS" : "FAIL")]")
    print("  WCAG AAA (≥ 7.0:1): [\(passesAAA ? "PASS" : "FAIL")]\n")
}
