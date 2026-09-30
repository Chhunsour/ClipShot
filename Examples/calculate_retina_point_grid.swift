#!/usr/bin/env swift
import Foundation
import CoreGraphics

print("--- ClipShot: Retina Subpixel Point Grid Snapping Calculator ---")

func snapToPixelGrid(value: CGFloat, scale: CGFloat) -> CGFloat {
    guard scale > 0 else { return value }
    return round(value * scale) / scale
}

func snapPointToGrid(_ point: CGPoint, scale: CGFloat) -> CGPoint {
    CGPoint(
        x: snapToPixelGrid(value: point.x, scale: scale),
        y: snapToPixelGrid(value: point.y, scale: scale)
    )
}

func hairlineOffset(scale: CGFloat) -> CGFloat {
    guard scale > 0 else { return 0 }
    return (0.5 / scale)
}

let testCoordinates: [CGFloat] = [
    10.0,
    10.23,
    10.49,
    10.50,
    10.74,
    10.88,
    25.333
]

let displayScales: [(label: String, scale: CGFloat)] = [
    ("1.0x Non-Retina (1pt = 1px)", 1.0),
    ("2.0x Retina (1pt = 2px, 0.5pt grid)", 2.0),
    ("3.0x Super Retina (1pt = 3px, 0.333pt grid)", 3.0)
]

for display in displayScales {
    print("\nScale: [\(display.label)]")
    print(String(format: "  Hairline Border Offset: %.4f pt (1 physical px)", hairlineOffset(scale: display.scale)))
    print(String(format: "  %-12@ %-16@ %-16@ %-12@", "Raw Point", "Snapped Point", "Backing Pixel", "Status"))
    print("  " + String(repeating: "-", count: 56))

    for raw in testCoordinates {
        let snapped = snapToPixelGrid(value: raw, scale: display.scale)
        let backingPixel = snapped * display.scale
        let isIntegerPixel = (backingPixel == round(backingPixel))
        let status = isIntegerPixel ? "Crisp ✅" : "Blurry ⚠️"

        print(String(format: "  %-12.3f %-16.3f %-16.1f %-12@",
                     raw, snapped, backingPixel, status))
    }
}

print("\n--- Summary Rationale ---")
print("On modern macOS Retina screens (2x), UI guide lines and selection boundaries must align to 0.5pt boundaries.")
print("Drawing a 1px border at an integer coordinate (e.g. x=100.0) causes the border to bleed 0.5px onto both sides.")
print("Applying `x = round(x * scale) / scale + (0.5 / scale)` guarantees razor-sharp 1-pixel borders without anti-aliasing fuzz.")
