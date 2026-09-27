#!/usr/bin/env swift
import Foundation
import CoreGraphics
import AppKit

print("--- ClipShot: In-Memory Diagnostic Test Pattern Generator ---")

func generateTestPattern(size: CGSize, gridSpacing: CGFloat = 20) -> CGImage? {
    let width = Int(size.width)
    let height = Int(size.height)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

    guard let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: colorSpace,
        bitmapInfo: bitmapInfo
    ) else {
        return nil
    }

    // 1. Dark background
    context.setFillColor(CGColor(srgbRed: 0.08, green: 0.08, blue: 0.10, alpha: 1.0))
    context.fill(CGRect(origin: .zero, size: size))

    // 2. Subtle grid lines
    context.setStrokeColor(CGColor(srgbRed: 0.20, green: 0.20, blue: 0.24, alpha: 1.0))
    context.setLineWidth(1.0)

    for x in stride(from: 0, through: size.width, by: gridSpacing) {
        context.move(to: CGPoint(x: x, y: 0))
        context.addLine(to: CGPoint(x: x, y: size.height))
    }
    for y in stride(from: 0, through: size.height, by: gridSpacing) {
        context.move(to: CGPoint(x: 0, y: y))
        context.addLine(to: CGPoint(x: size.width, y: y))
    }
    context.strokePath()

    // 3. Primary color corner anchors
    let corners: [(color: CGColor, rect: CGRect)] = [
        (CGColor(srgbRed: 1.0, green: 0.2, blue: 0.2, alpha: 1.0), CGRect(x: 10, y: 10, width: 30, height: 30)),
        (CGColor(srgbRed: 0.2, green: 0.8, blue: 0.2, alpha: 1.0), CGRect(x: size.width - 40, y: 10, width: 30, height: 30)),
        (CGColor(srgbRed: 0.2, green: 0.5, blue: 1.0, alpha: 1.0), CGRect(x: 10, y: size.height - 40, width: 30, height: 30)),
        (CGColor(srgbRed: 1.0, green: 0.8, blue: 0.0, alpha: 1.0), CGRect(x: size.width - 40, y: size.height - 40, width: 30, height: 30))
    ]

    for (color, rect) in corners {
        context.setFillColor(color)
        context.fill(rect)
    }

    return context.makeImage()
}

let testSize = CGSize(width: 320, height: 240)
if let patternImage = generateTestPattern(size: testSize) {
    let rep = NSBitmapImageRep(cgImage: patternImage)
    let pngBytes = rep.representation(using: .png, properties: [:])?.count ?? 0

    print("Successfully generated diagnostic test pattern:")
    print("  Pixel Width:      \(patternImage.width) px")
    print("  Pixel Height:     \(patternImage.height) px")
    print("  Bits Per Pixel:   \(patternImage.bitsPerPixel)")
    print("  Bytes Per Row:    \(patternImage.bytesPerRow)")
    print("  PNG Encoded Size: \(pngBytes) bytes")
} else {
    print("Failed to initialize CGContext for test pattern.")
}
