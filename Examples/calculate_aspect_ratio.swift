#!/usr/bin/env swift
import Foundation
import CoreGraphics

print("--- ClipShot: Aspect Ratio & GCD Dimension Calculator ---")

func gcd(_ a: Int, _ b: Int) -> Int {
    var x = abs(a)
    var y = abs(b)
    while y != 0 {
        let temp = y
        y = x % y
        x = temp
    }
    return x
}

func calculateAspectRatio(width: Int, height: Int) -> (ratio: String, decimal: Double) {
    guard width > 0, height > 0 else { return ("Invalid", 0.0) }
    let divisor = gcd(width, height)
    let rw = width / divisor
    let rh = height / divisor

    // Standard aspect ratio naming conventions
    let decimal = Double(width) / Double(height)
    if rw == 16 && rh == 9 {
        return ("16:9 (Standard Widescreen)", decimal)
    } else if rw == 16 && rh == 10 || (rw == 8 && rh == 5) {
        return ("16:10 (MacBook Retina Standard)", decimal)
    } else if rw == 4 && rh == 3 {
        return ("4:3 (Classic Display / iPad)", decimal)
    } else if rw == 64 && rh == 27 || rw == 21 && rh == 9 {
        return ("21:9 (UltraWide Cinematic)", decimal)
    } else if rw == 1 && rh == 1 {
        return ("1:1 (Square)", decimal)
    } else {
        return ("\(rw):\(rh)", decimal)
    }
}

let sampleResolutions: [(width: Int, height: Int, label: String)] = [
    (1920, 1080, "Full HD Display"),
    (2560, 1440, "QHD / 2K Monitor"),
    (3840, 2160, "4K UHD Display"),
    (2880, 1800, "15.4\" MacBook Pro Retina"),
    (3024, 1964, "14\" MacBook Pro Liquid Retina XDR"),
    (3456, 2234, "16\" MacBook Pro Liquid Retina XDR"),
    (3440, 1440, "UltraWide 34\" Curved Monitor"),
    (1080, 1920, "Vertical / Portrait Video Frame"),
    (1024, 768, "Legacy 4:3 Display")
]

for sample in sampleResolutions {
    let (ratio, decimal) = calculateAspectRatio(width: sample.width, height: sample.height)
    print("Device: [\(sample.label)]")
    print("  Resolution: \(sample.width) × \(sample.height) px")
    print("  Aspect Ratio: \(ratio)")
    print(String(format: "  Decimal Ratio: %.3f\n", decimal))
}
