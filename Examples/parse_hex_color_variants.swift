#!/usr/bin/env swift
import Foundation

print("--- ClipShot: Multi-Format Hex Color Parser & Normalizer ---")

struct ParsedColor {
    let r: Double
    let g: Double
    let b: Double
    let a: Double

    var hex6: String {
        String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }

    var hex8: String {
        String(format: "#%02X%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255), Int(a * 255))
    }

    var cssRgba: String {
        String(format: "rgba(%d, %d, %d, %.2f)", Int(r * 255), Int(g * 255), Int(b * 255), a)
    }
}

func parseHexColor(_ hex: String) -> ParsedColor? {
    var clean = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    if clean.hasPrefix("#") {
        clean.removeFirst()
    }

    var hexNumber: UInt64 = 0
    guard Scanner(string: clean).scanHexInt64(&hexNumber) else { return nil }

    switch clean.count {
    case 3: // #RGB -> #RRGGBB
        let r = Double((hexNumber & 0xF00) >> 8) / 15.0
        let g = Double((hexNumber & 0x0F0) >> 4) / 15.0
        let b = Double(hexNumber & 0x00F) / 15.0
        return ParsedColor(r: r, g: g, b: b, a: 1.0)

    case 6: // #RRGGBB
        let r = Double((hexNumber & 0xFF0000) >> 16) / 255.0
        let g = Double((hexNumber & 0x00FF00) >> 8) / 255.0
        let b = Double(hexNumber & 0x0000FF) / 255.0
        return ParsedColor(r: r, g: g, b: b, a: 1.0)

    case 8: // #RRGGBBAA
        let r = Double((hexNumber & 0xFF000000) >> 24) / 255.0
        let g = Double((hexNumber & 0x00FF0000) >> 16) / 255.0
        let b = Double((hexNumber & 0x0000FF00) >> 8) / 255.0
        let a = Double(hexNumber & 0x000000FF) / 255.0
        return ParsedColor(r: r, g: g, b: b, a: a)

    default:
        return nil
    }
}

let testInputs = [
    "#F00",
    "#00FF00",
    "#007AFF",
    "#FF008080",
    "#123",
    "AABBCC",
    "#INVALID"
]

for input in testInputs {
    if let parsed = parseHexColor(input) {
        print("Input: \"\(input)\"")
        print("  Normalized HEX6: \(parsed.hex6)")
        print("  Normalized HEX8: \(parsed.hex8)")
        print("  CSS RGBA:        \(parsed.cssRgba)\n")
    } else {
        print("Input: \"\(input)\" -> [INVALID FORMAT]\n")
    }
}
