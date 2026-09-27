#!/usr/bin/env swift
import Foundation

print("--- ClipShot: Byte Count Formatting Utility ---")

let testByteCounts: [Int64] = [
    512,                 // 512 B
    45 * 1024,           // 45 KB
    1024 * 1024 * 3,     // 3 MB
    1024 * 1024 * 850,   // 850 MB
    Int64(2.4 * 1024 * 1024 * 1024) // 2.4 GB
]

print("File Style Formatting:")
for bytes in testByteCounts {
    let formatted = ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    print("  - \(bytes) bytes  ->  \(formatted)")
}

print("\nMemory Style Formatting:")
for bytes in testByteCounts {
    let formatted = ByteCountFormatter.string(fromByteCount: bytes, countStyle: .memory)
    print("  - \(bytes) bytes  ->  \(formatted)")
}
