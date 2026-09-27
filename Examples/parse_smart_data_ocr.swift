#!/usr/bin/env swift
import Foundation

print("--- ClipShot: OCR Smart Data Parser ---")

let sampleRecognizedText = """
Order confirmation: please check https://github.com/Chhunsour/ClipShot
Contact support at support@example.com or call +1 (555) 234-5678.
Brand accent color detected: #007AFF and background #F2F2F7.
"""

// 1. Detect URLs using NSDataDetector
if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) {
    let matches = detector.matches(in: sampleRecognizedText, options: [], range: NSRange(location: 0, length: sampleRecognizedText.utf16.count))
    print("Detected URLs (\(matches.count)):")
    for match in matches {
        if let url = match.url {
            print("  - \(url.absoluteString)")
        }
    }
}

// 2. Detect Hex Color Codes
let hexRegex = try? NSRegularExpression(pattern: "#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})\\b")
if let regex = hexRegex {
    let matches = regex.matches(in: sampleRecognizedText, options: [], range: NSRange(location: 0, length: sampleRecognizedText.utf16.count))
    print("Detected Hex Colors (\(matches.count)):")
    for match in matches {
        if let range = Range(match.range, in: sampleRecognizedText) {
            print("  - \(sampleRecognizedText[range])")
        }
    }
}

// 3. Detect Phone Numbers
if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.phoneNumber.rawValue) {
    let matches = detector.matches(in: sampleRecognizedText, options: [], range: NSRange(location: 0, length: sampleRecognizedText.utf16.count))
    print("Detected Phone Numbers (\(matches.count)):")
    for match in matches {
        if let phone = match.phoneNumber {
            print("  - \(phone)")
        }
    }
}
