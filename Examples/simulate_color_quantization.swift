#!/usr/bin/env swift
import Foundation

print("--- ClipShot: Color Quantization & Dominant Palette Extractor ---")

struct RGBColor: Hashable {
    let r: UInt8
    let g: UInt8
    let b: UInt8

    var hexString: String {
        String(format: "#%02X%02X%02X", r, g, b)
    }

    // Quantize 8-bit channel (0...255) to 3-bit channel (0...7) -> 512 total color buckets
    var bucketKey: Int {
        let qr = Int(r >> 5)
        let qg = Int(g >> 5)
        let qb = Int(b >> 5)
        return (qr << 6) | (qg << 3) | qb
    }
}

// Sample pixel pool simulating a typical macOS desktop screenshot:
// Dark menu bar / dock, wallpaper blue gradient, Xcode editor window, orange accent tag
let samplePixelBuffer: [RGBColor] = [
    // Dark UI window chrome (12 pixels)
    RGBColor(r: 30, g: 30, b: 32),
    RGBColor(r: 31, g: 29, b: 34),
    RGBColor(r: 28, g: 30, b: 30),
    RGBColor(r: 35, g: 35, b: 38),
    RGBColor(r: 33, g: 32, b: 34),
    RGBColor(r: 30, g: 31, b: 31),
    
    // macOS Wallpaper Deep Blue / Cyan Gradient (14 pixels)
    RGBColor(r: 10, g: 90, b: 200),
    RGBColor(r: 12, g: 95, b: 205),
    RGBColor(r: 15, g: 100, b: 210),
    RGBColor(r: 20, g: 105, b: 215),
    RGBColor(r: 18, g: 92, b: 198),
    RGBColor(r: 14, g: 88, b: 195),
    RGBColor(r: 25, g: 110, b: 220),

    // White text / foreground content (6 pixels)
    RGBColor(r: 250, g: 250, b: 252),
    RGBColor(r: 255, g: 255, b: 255),
    RGBColor(r: 248, g: 248, b: 250),

    // Orange accent notification badge (4 pixels)
    RGBColor(r: 255, g: 120, b: 30),
    RGBColor(r: 250, g: 118, b: 28)
]

print("Processing \(samplePixelBuffer.count) sample pixels across 512-bucket 3-bit color space...\n")

// Cluster pixels by bucket
var bucketMap: [Int: [RGBColor]] = [:]
for pixel in samplePixelBuffer {
    bucketMap[pixel.bucketKey, default: []].append(pixel)
}

struct DominantCluster {
    let centroid: RGBColor
    let pixelCount: Int
    let percentage: Double
}

var clusters: [DominantCluster] = []

for (_, pixels) in bucketMap {
    let sumR = pixels.reduce(0) { $0 + Int($1.r) }
    let sumG = pixels.reduce(0) { $0 + Int($1.g) }
    let sumB = pixels.reduce(0) { $0 + Int($1.b) }
    let count = pixels.count

    let centroid = RGBColor(
        r: UInt8(sumR / count),
        g: UInt8(sumG / count),
        b: UInt8(sumB / count)
    )
    let pct = (Double(count) / Double(samplePixelBuffer.count)) * 100.0
    clusters.append(DominantCluster(centroid: centroid, pixelCount: count, percentage: pct))
}

// Sort by frequency descending
clusters.sort { $0.pixelCount > $1.pixelCount }

print(String(format: "%-6@ %-12@ %-18@ %-12@ %-12@", "Rank", "Hex Code", "RGB Centroid", "Pixels", "Dominance"))
print(String(repeating: "-", count: 64))

for (index, cluster) in clusters.enumerated() {
    let rgbStr = "(\(cluster.centroid.r), \(cluster.centroid.g), \(cluster.centroid.b))"
    let pctStr = String(format: "%.1f%%", cluster.percentage)
    print(String(format: "#%-5d %-12@ %-18@ %-12d %-12@",
                 index + 1, cluster.centroid.hexString, rgbStr, cluster.pixelCount, pctStr))
}

print("\nKey Palette Colors Extracted: \(clusters.count) dominant centroids.")
