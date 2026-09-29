#!/usr/bin/env swift
import Foundation

print("--- ClipShot: Screenshot Regex Performance Benchmark ---")

let pattern = #"^Screen\s+Shot\s+(\d{4}-\d{2}-\d{2})\s+at\s+(\d{1,2}\.\d{2}\.\d{2})\.png$"#
let sampleFilenames = [
    "Screen Shot 2026-09-29 at 09.30.15.png",
    "Screen Shot 2026-09-29 at 9.04.12.png",
    "Document_Invoice_Final_2026.pdf",
    "Presentation_Deck_Draft.key",
    "Screen Shot 2026-01-01 at 00.00.00.png"
]

let iterations = 5_000

print("Benchmarking \(iterations) iterations across \(sampleFilenames.count) sample filenames...\n")

// Test 1: Naive (Re-compiling NSRegularExpression on every check)
let startNaive = DispatchTime.now()
var naiveMatches = 0
for _ in 0..<iterations {
    for filename in sampleFilenames {
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(filename.startIndex..<filename.endIndex, in: filename)
            if regex.firstMatch(in: filename, options: [], range: range) != nil {
                naiveMatches += 1
            }
        }
    }
}
let endNaive = DispatchTime.now()
let nanoNaive = endNaive.uptimeNanoseconds - startNaive.uptimeNanoseconds
let msNaive = Double(nanoNaive) / 1_000_000.0

// Test 2: Optimized (Pre-compiled NSRegularExpression, identical to ScreenshotDetector.swift)
let startOptimized = DispatchTime.now()
let precompiledRegex = try! NSRegularExpression(pattern: pattern, options: [])
var optimizedMatches = 0
for _ in 0..<iterations {
    for filename in sampleFilenames {
        let range = NSRange(filename.startIndex..<filename.endIndex, in: filename)
        if precompiledRegex.firstMatch(in: filename, options: [], range: range) != nil {
            optimizedMatches += 1
        }
    }
}
let endOptimized = DispatchTime.now()
let nanoOptimized = endOptimized.uptimeNanoseconds - startOptimized.uptimeNanoseconds
let msOptimized = Double(nanoOptimized) / 1_000_000.0

let speedup = msNaive / msOptimized
let totalEvaluations = iterations * sampleFilenames.count

print("Results:")
print(String(format: "  Total Filename Evaluations: %d", totalEvaluations))
print(String(format: "  Naive (Recompiled every time):  %8.2f ms (avg %6.2f µs/eval)", msNaive, (msNaive * 1000.0) / Double(totalEvaluations)))
print(String(format: "  Optimized (Pre-compiled once):  %8.2f ms (avg %6.2f µs/eval)", msOptimized, (msOptimized * 1000.0) / Double(totalEvaluations)))
print(String(format: "  🚀 Performance Improvement:     %.1fx faster using precompiled regexes\n", speedup))
print("Architectural Rationale: During massive batch bursts (e.g. rapid multi-display screenshots), precompiling regexes avoids thread thrashing and memory allocations in FSEvents listener threads.")
