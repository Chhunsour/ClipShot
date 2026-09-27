#!/usr/bin/env swift
import Foundation
import AppKit

print("--- ClipShot: Image Format Transcoder Example ---")

// Synthesize an in-memory sample test image
let size = NSSize(width: 64, height: 64)
let image = NSImage(size: size)
image.lockFocus()
let gradient = NSGradient(starting: .systemBlue, ending: .systemPurple)
gradient?.draw(in: NSRect(origin: .zero, size: size), angle: 45)
image.unlockFocus()

guard let tiffData = image.tiffRepresentation,
      let bitmapRep = NSBitmapImageRep(data: tiffData) else {
    print("Error: Could not obtain bitmap representation.")
    exit(1)
}

print("Original image size: \(Int(size.width)) × \(Int(size.height)) pt")

// 1. Convert to PNG
if let png = bitmapRep.representation(using: .png, properties: [:]) {
    print("  PNG Encoded:  \(png.count) bytes (lossless, transparency supported)")
}

// 2. Convert to JPEG (90% quality)
if let jpeg = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.9]) {
    print("  JPEG Encoded: \(jpeg.count) bytes (lossy, high compression)")
}

// 3. Convert to TIFF (LZW compression)
if let tiff = bitmapRep.representation(using: .tiff, properties: [.compressionMethod: NSBitmapImageRep.TIFFCompression.lzw.rawValue]) {
    print("  TIFF Encoded: \(tiff.count) bytes (uncompressed/LZW archive)")
}
