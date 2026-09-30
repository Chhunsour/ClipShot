#!/usr/bin/env swift
import Foundation
import CoreGraphics

print("--- ClipShot: Boundary-Safe Bitmap Cropping Math Analyzer ---")

struct ImageBoundaryClamping {
    let sourceWidth: Int
    let sourceHeight: Int
    let scale: CGFloat

    var pixelWidth: CGFloat { CGFloat(sourceWidth) }
    var pixelHeight: CGFloat { CGFloat(sourceHeight) }
    var logicalWidth: CGFloat { CGFloat(sourceWidth) / scale }
    var logicalHeight: CGFloat { CGFloat(sourceHeight) / scale }

    /// Clamps an arbitrary user selection rectangle (in logical points) to valid, safe pixel crop coordinates.
    func computeSafeCropRect(selectionRect: CGRect) -> (safeCropPixelRect: CGRect, wasAdjusted: Bool)? {
        // Standardize rect in case user dragged from bottom-right to top-left (negative width/height)
        let standardized = selectionRect.standardized

        // Convert points to physical pixels
        let pixelSelection = CGRect(
            x: standardized.origin.x * scale,
            y: standardized.origin.y * scale,
            width: standardized.width * scale,
            height: standardized.height * scale
        )

        let imageBounds = CGRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight)

        // Calculate intersection
        let clamped = pixelSelection.intersection(imageBounds)

        // If rect is empty, null, or has zero width/height, return nil
        if clamped.isNull || clamped.isEmpty || clamped.width < 1.0 || clamped.height < 1.0 {
            return nil
        }

        // Align coordinates to integer pixel boundaries to avoid subpixel blur or partial row copies
        let integralCrop = clamped.integral

        let adjusted = integralCrop != pixelSelection
        return (integralCrop, adjusted)
    }
}

// 14-inch MacBook Pro Retina image: 3024x1964 pixels at 2.0x scale (1512x982 logical points)
let clamper = ImageBoundaryClamping(sourceWidth: 3024, sourceHeight: 1964, scale: 2.0)

let testCases: [(name: String, rect: CGRect)] = [
    ("Fully Inside", CGRect(x: 100, y: 100, width: 400, height: 300)),
    ("Negative Drag Origin (Inverted)", CGRect(x: 500, y: 400, width: -200, height: -150)),
    ("Overhanging Right Edge", CGRect(x: 1300, y: 200, width: 400, height: 200)),
    ("Overhanging Top/Left (-x, -y)", CGRect(x: -50, y: -50, width: 200, height: 200)),
    ("Completely Outside Bounds", CGRect(x: 2000, y: 2000, width: 300, height: 300)),
    ("Zero Dimension Selection", CGRect(x: 100, y: 100, width: 0, height: 100)),
    ("Fractional Points Snapping", CGRect(x: 10.3, y: 20.7, width: 100.4, height: 50.8))
]

print("Source Image: \(clamper.sourceWidth)x\(clamper.sourceHeight) px (Logical: \(clamper.logicalWidth)x\(clamper.logicalHeight) pt @ \(clamper.scale)x)\n")

print(String(format: "%-30@ %-24@ %-30@ %-12@", "Test Case", "Input Rect (pt)", "Pixel Crop Rect (px)", "Clamped?"))
print(String(repeating: "-", count: 100))

for test in testCases {
    let inputStr = "(\(Int(test.rect.origin.x)),\(Int(test.rect.origin.y)), \(Int(test.rect.width))x\(Int(test.rect.height)))"
    if let result = clamper.computeSafeCropRect(selectionRect: test.rect) {
        let r = result.safeCropPixelRect
        let outputStr = "(\(Int(r.origin.x)),\(Int(r.origin.y)), \(Int(r.size.width))x\(Int(r.size.height)))"
        print(String(format: "%-30@ %-24@ %-30@ %-12@", test.name, inputStr, outputStr, result.wasAdjusted ? "Yes (Clamped)" : "No (Exact)"))
    } else {
        print(String(format: "%-30@ %-24@ %-30@ %-12@", test.name, inputStr, "[REJECTED: Null/Empty]", "Yes"))
    }
}

print("\nArchitectural Rationale: Pre-computing standardized integral intersections against source image bounds prevents CoreGraphics 'invalid crop rect' crashes and eliminates edge-bleeding artifacts in custom crop overlays.")
