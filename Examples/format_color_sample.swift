#!/usr/bin/env swift
import Foundation
import AppKit

print("--- ClipShot: Color Format Conversions ---")

let sampleColor = NSColor(srgbRed: 0.18, green: 0.80, blue: 0.44, alpha: 1.0)

// 1. HEX
let r = Int(round(sampleColor.redComponent * 255.0))
let g = Int(round(sampleColor.greenComponent * 255.0))
let b = Int(round(sampleColor.blueComponent * 255.0))
let hex = String(format: "#%02X%02X%02X", r, g, b)
print("1. HEX:        \(hex)")

// 2. RGB
let rgb = "rgb(\(r), \(g), \(b))"
print("2. RGB:        \(rgb)")

// 3. HSL
var h: CGFloat = 0
var s: CGFloat = 0
var l: CGFloat = 0
let maxVal = max(sampleColor.redComponent, sampleColor.greenComponent, sampleColor.blueComponent)
let minVal = min(sampleColor.redComponent, sampleColor.greenComponent, sampleColor.blueComponent)
let delta = maxVal - minVal

l = (maxVal + minVal) / 2.0
if delta > 0 {
    s = l > 0.5 ? delta / (2.0 - maxVal - minVal) : delta / (maxVal + minVal)
    if maxVal == sampleColor.redComponent {
        h = ((sampleColor.greenComponent - sampleColor.blueComponent) / delta).truncatingRemainder(dividingBy: 6)
    } else if maxVal == sampleColor.greenComponent {
        h = ((sampleColor.blueComponent - sampleColor.redComponent) / delta) + 2.0
    } else {
        h = ((sampleColor.redComponent - sampleColor.greenComponent) / delta) + 4.0
    }
    h *= 60.0
    if h < 0 { h += 360.0 }
}
let hsl = String(format: "hsl(%.0f, %.0f%%, %.0f%%)", h, s * 100.0, l * 100.0)
print("3. HSL:        \(hsl)")

// 4. Display P3
let p3 = String(format: "color(display-p3 %.2f %.2f %.2f)", sampleColor.redComponent, sampleColor.greenComponent, sampleColor.blueComponent)
print("4. Display P3: \(p3)")
