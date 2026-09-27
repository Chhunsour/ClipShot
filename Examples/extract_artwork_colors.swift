#!/usr/bin/env swift
import Foundation
import CoreGraphics
import AppKit

print("--- ClipShot: Extract Artwork Colors Example ---")

// Synthesize a 4x4 test bitmap with known palette colors
let width = 4
let height = 4
let bytesPerPixel = 4
let bytesPerRow = bytesPerPixel * width
var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

// Fill with some sample RGB colors: 8 pixels red, 4 pixels blue, 4 pixels green
for i in 0..<8 {
    let offset = i * bytesPerPixel
    pixelData[offset] = 255     // R
    pixelData[offset + 1] = 50  // G
    pixelData[offset + 2] = 50  // B
    pixelData[offset + 3] = 255 // A
}
for i in 8..<12 {
    let offset = i * bytesPerPixel
    pixelData[offset] = 30      // R
    pixelData[offset + 1] = 100 // G
    pixelData[offset + 2] = 240 // B
    pixelData[offset + 3] = 255 // A
}
for i in 12..<16 {
    let offset = i * bytesPerPixel
    pixelData[offset] = 40      // R
    pixelData[offset + 1] = 200 // G
    pixelData[offset + 2] = 60  // B
    pixelData[offset + 3] = 255 // A
}

// Frequency histogram for color quantization
var colorFrequency: [String: Int] = [:]
for i in 0..<(width * height) {
    let offset = i * bytesPerPixel
    let r = pixelData[offset]
    let g = pixelData[offset + 1]
    let b = pixelData[offset + 2]
    let hex = String(format: "#%02X%02X%02X", r, g, b)
    colorFrequency[hex, default: 0] += 1
}

let sortedPalette = colorFrequency.sorted { $0.value > $1.value }
print("Identified \(sortedPalette.count) dominant colors in sample:")
for (index, entry) in sortedPalette.enumerated() {
    let percentage = (Double(entry.value) / Double(width * height)) * 100.0
    print("  [\(index + 1)] \(entry.key) - \(entry.value) pixels (\(String(format: "%.1f", percentage))%)")
}
