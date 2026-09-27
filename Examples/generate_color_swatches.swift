#!/usr/bin/env swift
import Foundation
import AppKit

print("--- ClipShot: Color Swatch Palette Generator ---")

let brandHexes = ["#007AFF", "#34C759", "#FF9500", "#FF3B30", "#AF52DE", "#5856D6"]

func colorFromHex(_ hex: String) -> NSColor? {
    var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    if cleaned.hasPrefix("#") { cleaned.removeFirst() }
    guard cleaned.count == 6, let val = UInt64(cleaned, radix: 16) else { return nil }

    let r = CGFloat((val & 0xFF0000) >> 16) / 255.0
    let g = CGFloat((val & 0x00FF00) >> 8) / 255.0
    let b = CGFloat(val & 0x0000FF) / 255.0
    return NSColor(srgbRed: r, green: g, blue: b, alpha: 1.0)
}

print("Generated \(brandHexes.count) swatches:")
for hex in brandHexes {
    guard let color = colorFromHex(hex) else { continue }
    let r = Int(round(color.redComponent * 255))
    let g = Int(round(color.greenComponent * 255))
    let b = Int(round(color.blueComponent * 255))
    // ANSI truecolor escape codes for terminal color representation
    let ansiBlock = "\u{001B}[48;2;\(r);\(g);\(b)m      \u{001B}[0m"
    print("  \(ansiBlock)  \(hex)  ->  rgb(\(r), \(g), \(b))")
}
