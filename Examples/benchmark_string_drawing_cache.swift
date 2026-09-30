#!/usr/bin/env swift
import Foundation
import CoreGraphics
import AppKit

print("--- ClipShot: Dimension String Measurement Caching Benchmark ---")

let sampleDimensionStrings = [
    "1920 × 1080 px",
    "2560 × 1440 px",
    "3840 × 2160 px",
    "800 × 600 px",
    "1280 × 720 px",
    "300 × 200 px",
    "100 × 100 px",
    "1512 × 982 px",
    "1728 × 1117 px",
    "5120 × 2880 px"
]

let font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .semibold)
let attributes: [NSAttributedString.Key: Any] = [
    .font: font
]

let iterations = 10_000
let totalCalls = iterations * sampleDimensionStrings.count

print("Benchmarking \(iterations) iterations across \(sampleDimensionStrings.count) dimension labels (\(totalCalls) total evaluations)...\n")

// Test 1: Uncached (Recomputes NSAttributedString size every single invocation)
let startUncached = DispatchTime.now()
var uncachedTotalWidth: CGFloat = 0.0

for _ in 0..<iterations {
    for str in sampleDimensionStrings {
        let attrString = NSAttributedString(string: str, attributes: attributes)
        let size = attrString.size()
        uncachedTotalWidth += size.width
    }
}

let endUncached = DispatchTime.now()
let nanoUncached = endUncached.uptimeNanoseconds - startUncached.uptimeNanoseconds
let msUncached = Double(nanoUncached) / 1_000_000.0

// Test 2: Cached (Uses string key dictionary lookup)
let startCached = DispatchTime.now()
var cache: [String: CGSize] = [:]
var cachedTotalWidth: CGFloat = 0.0

for _ in 0..<iterations {
    for str in sampleDimensionStrings {
        let size: CGSize
        if let existing = cache[str] {
            size = existing
        } else {
            let attrString = NSAttributedString(string: str, attributes: attributes)
            let calculated = attrString.size()
            cache[str] = calculated
            size = calculated
        }
        cachedTotalWidth += size.width
    }
}

let endCached = DispatchTime.now()
let nanoCached = endCached.uptimeNanoseconds - startCached.uptimeNanoseconds
let msCached = Double(nanoCached) / 1_000_000.0

let speedup = msUncached / msCached

print("Results:")
print(String(format: "  Uncached (Full layout pass):  %8.2f ms (avg %6.3f µs/eval)", msUncached, (msUncached * 1000.0) / Double(totalCalls)))
print(String(format: "  Cached (Dictionary lookup):    %8.2f ms (avg %6.3f µs/eval)", msCached, (msCached * 1000.0) / Double(totalCalls)))
print(String(format: "  🚀 Performance Improvement:    %.1fx faster rendering\n", speedup))
print("Architectural Rationale: Caching dimension badge sizes eliminates CoreText typography calculation overhead during high-speed 120 FPS selection drag interactions.")
