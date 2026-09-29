#!/usr/bin/env swift
import Foundation
import CoreGraphics

print("--- ClipShot: Mac Display Pixel Density (PPI) & Retina Scale Calculator ---")

struct MacDisplay {
    let name: String
    let widthPx: Int
    let heightPx: Int
    let diagonalInches: Double
    let retinaScale: Double

    var diagonalPixels: Double {
        sqrt(Double(widthPx * widthPx + heightPx * heightPx))
    }

    var ppi: Double {
        diagonalPixels / diagonalInches
    }

    var logicalWidthPt: Double {
        Double(widthPx) / retinaScale
    }

    var logicalHeightPt: Double {
        Double(heightPx) / retinaScale
    }
}

let devices: [MacDisplay] = [
    MacDisplay(name: "13.6\" MacBook Air (M2/M3)", widthPx: 2560, heightPx: 1664, diagonalInches: 13.6, retinaScale: 2.0),
    MacDisplay(name: "14.2\" MacBook Pro Liquid Retina XDR", widthPx: 3024, heightPx: 1964, diagonalInches: 14.2, retinaScale: 2.0),
    MacDisplay(name: "16.2\" MacBook Pro Liquid Retina XDR", widthPx: 3456, heightPx: 2234, diagonalInches: 16.2, retinaScale: 2.0),
    MacDisplay(name: "24\" iMac 4.5K Retina", widthPx: 4480, heightPx: 2520, diagonalInches: 23.5, retinaScale: 2.0),
    MacDisplay(name: "27\" Apple Studio Display 5K", widthPx: 5120, heightPx: 2880, diagonalInches: 27.0, retinaScale: 2.0),
    MacDisplay(name: "32\" Pro Display XDR 6K", widthPx: 6016, heightPx: 3384, diagonalInches: 32.0, retinaScale: 2.0),
    MacDisplay(name: "27\" External QHD Monitor (1x Non-Retina)", widthPx: 2560, heightPx: 1440, diagonalInches: 27.0, retinaScale: 1.0),
    MacDisplay(name: "24\" External 1080p Monitor (1x Legacy)", widthPx: 1920, heightPx: 1080, diagonalInches: 24.0, retinaScale: 1.0)
]

print(String(format: "%-36@ %-12@ %-12@ %-8@ %-8@", "Device Model", "Physical Px", "Logical Pt", "Scale", "Density"))
print(String(repeating: "-", count: 80))

for dev in devices {
    let pxString = "\(dev.widthPx)×\(dev.heightPx)"
    let ptString = "\(Int(dev.logicalWidthPt))×\(Int(dev.logicalHeightPt))"
    let scaleString = "\(Int(dev.retinaScale))x"
    let ppiString = String(format: "%.1f PPI", dev.ppi)

    print(String(format: "%-36@ %-12@ %-12@ %-8@ %-8@",
                 dev.name, pxString, ptString, scaleString, ppiString))
}

print("\n--- Coordinate Transformation Sample (Retina 2x) ---")
let testPoint = CGPoint(x: 450.5, y: 320.0)
let scale: CGFloat = 2.0
let pixelX = testPoint.x * scale
let pixelY = testPoint.y * scale

print(String(format: "Logical AppKit Point: (%.1f, %.1f) pt", testPoint.x, testPoint.y))
print(String(format: "Backing Hardware Pixel: (%.0f, %.0f) px @ %.0fx", pixelX, pixelY, scale))
print("Rule: CoreGraphics screen capture APIs return physical backing pixels, which must be scaled back by backingScaleFactor when computing point coordinates for UI overlays.")
