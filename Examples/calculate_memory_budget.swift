#!/usr/bin/env swift
import Foundation

print("--- ClipShot: Display Resolution Uncompressed Bitmap Memory Budget Calculator ---")

struct DisplayProfile {
    let name: String
    let width: Int
    let height: Int
    let scaleFactor: Double
}

let displays: [DisplayProfile] = [
    DisplayProfile(name: "Full HD (1080p)", width: 1920, height: 1080, scaleFactor: 1.0),
    DisplayProfile(name: "QHD / 2K Display", width: 2560, height: 1440, scaleFactor: 1.0),
    DisplayProfile(name: "4K UHD Monitor", width: 3840, height: 2160, scaleFactor: 1.0),
    DisplayProfile(name: "14\" MacBook Pro Liquid Retina XDR", width: 3024, height: 1964, scaleFactor: 2.0),
    DisplayProfile(name: "16\" MacBook Pro Liquid Retina XDR", width: 3456, height: 2234, scaleFactor: 2.0),
    DisplayProfile(name: "27\" Apple Studio Display (5K)", width: 5120, height: 2880, scaleFactor: 2.0),
    DisplayProfile(name: "32\" Pro Display XDR (6K)", width: 6016, height: 3384, scaleFactor: 2.0)
]

func formatMegabytes(_ bytes: Int64) -> String {
    let mb = Double(bytes) / (1024.0 * 1024.0)
    return String(format: "%.2f MB", mb)
}

print(String(format: "%-36@ %-14@ %-12@ %-14@ %-14@", "Display Model", "Resolution", "8-bit RGBA", "16-bit HDR", "10-Frame Undo"))
print(String(repeating: "-", count: 96))

for d in displays {
    let totalPixels = Int64(d.width) * Int64(d.height)
    
    // 8-bit per channel RGBA (4 bytes per pixel)
    let bytes8Bit = totalPixels * 4
    
    // 16-bit half-float per channel HDR RGBA (8 bytes per pixel)
    let bytes16Bit = totalPixels * 8
    
    // 10-frame undo history buffer in standard 8-bit RGBA
    let undoBuffer10 = bytes8Bit * 10

    let resString = "\(d.width)×\(d.height)"
    print(String(format: "%-36@ %-14@ %-12@ %-14@ %-14@",
                 d.name,
                 resString,
                 formatMegabytes(bytes8Bit),
                 formatMegabytes(bytes16Bit),
                 formatMegabytes(undoBuffer10)))
}

print("\n--- Video Capture Buffer Analysis (60 FPS @ 8-bit RGBA) ---")
for d in [displays[0], displays[2], displays[5]] {
    let totalPixels = Int64(d.width) * Int64(d.height)
    let frameBytes = totalPixels * 4
    let oneSecBytes = frameBytes * 60
    let fiveSecBytes = oneSecBytes * 5

    print("• \(d.name) (\(d.width)×\(d.height)):")
    print("  1 Second Buffer (60 frames): \(formatMegabytes(oneSecBytes))")
    print("  5 Second Circular Ring Buffer: \(formatMegabytes(fiveSecBytes))")
}
