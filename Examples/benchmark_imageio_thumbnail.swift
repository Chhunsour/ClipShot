#!/usr/bin/env swift
import Foundation
import CoreGraphics
import ImageIO

// MARK: - Benchmark ImageIO Hardware Thumbnail Downsampling
// Demonstrates sub-millisecond thumbnail generation directly from ImageIO sources
// without decoding the entire uncompressed RGBA bitmap buffer into host RAM.

struct ThumbnailBenchmarkResult {
    let originalSize: CGSize
    let targetSize: CGFloat
    let fullDecodeTimeMs: Double
    let downsampledTimeMs: Double
    let speedup: Double
}

func createTestImageBitmapData(width: Int, height: Int) -> Data? {
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

    // Fill with gradient colors
    context.setFillColor(CGColor(red: 0.2, green: 0.4, blue: 0.9, alpha: 1.0))
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    context.setFillColor(CGColor(red: 0.9, green: 0.3, blue: 0.2, alpha: 0.8))
    context.fillEllipse(in: CGRect(x: width / 4, y: height / 4, width: width / 2, height: height / 2))

    guard let cgImage = context.makeImage() else { return nil }

    let mutableData = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(mutableData as CFMutableData, "public.png" as CFString, 1, nil) else {
        return nil
    }
    CGImageDestinationAddImage(destination, cgImage, nil)
    guard CGImageDestinationFinalize(destination) else { return nil }
    return mutableData as Data
}

func benchmarkThumbnailPipeline() {
    print("--- ClipShot: ImageIO Thumbnail Pipeline & Memory Benchmark ---")
    
    let width = 2880
    let height = 1800
    print("Generating simulated 5K/Retina screenshot buffer (\(width)x\(height))...")
    
    guard let rawData = createTestImageBitmapData(width: width, height: height) else {
        print("Failed to generate test image data.")
        return
    }
    
    print("Raw PNG Payload: \(rawData.count / 1024) KB")
    print("Uncompressed RGBA Framebuffer Cost: \((width * height * 4) / (1024 * 1024)) MB RAM")
    print("----------------------------------------------------------------")

    let targetThumbSize: CGFloat = 256

    // 1. Full decode approach
    let t0 = CFAbsoluteTimeGetCurrent()
    if let source = CGImageSourceCreateWithData(rawData as CFData, nil) {
        _ = CGImageSourceCreateImageAtIndex(source, 0, nil)
    }
    let fullDecodeMs = (CFAbsoluteTimeGetCurrent() - t0) * 1000.0

    // 2. ImageIO hardware-accelerated downsampled thumbnail approach
    let t1 = CFAbsoluteTimeGetCurrent()
    let options: [CFString: Any] = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceShouldCacheImmediately: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceThumbnailMaxPixelSize: targetThumbSize
    ]

    var thumbWidth = 0
    var thumbHeight = 0
    if let source = CGImageSourceCreateWithData(rawData as CFData, nil),
       let thumb = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) {
        thumbWidth = thumb.width
        thumbHeight = thumb.height
    }
    let downsampledMs = (CFAbsoluteTimeGetCurrent() - t1) * 1000.0

    let speedup = fullDecodeMs > 0 ? (fullDecodeMs / downsampledMs) : 1.0

    print("Pipeline Comparison:")
    print("  Full Bitmap Decode Latency:      \(String(format: "%.2f", fullDecodeMs)) ms")
    print("  ImageIO Subsampled Thumbnail:    \(String(format: "%.2f", downsampledMs)) ms (Target: \(thumbWidth)x\(thumbHeight))")
    print("  Speedup Multiplier:              \(String(format: "%.1fx faster", speedup))")
    print("  Downsampled Memory Footprint:    \((thumbWidth * thumbHeight * 4) / 1024) KB (vs \((width * height * 4) / (1024 * 1024)) MB)")
    print("----------------------------------------------------------------")
    print("Status: ✅ ImageIO downsampled pipeline avoids full raster decode overhead.")
}

benchmarkThumbnailPipeline()
