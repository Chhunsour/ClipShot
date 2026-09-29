#!/usr/bin/env swift
import Foundation

print("--- ClipShot: Multi-Language Screenshot Filename Detector ---")

// Comprehensive regex patterns for localized macOS screenshot naming conventions
let localizedPatterns: [(language: String, pattern: String)] = [
    ("English (Modern)", #"^Screenshot\s+(\d{4}-\d{2}-\d{2})\s+at\s+(\d{1,2}\.\d{2}\.\d{2})\.png$"#),
    ("English (Classic)", #"^Screen\s+Shot\s+(\d{4}-\d{2}-\d{2})\s+at\s+(\d{1,2}\.\d{2}\.\d{2})\.png$"#),
    ("French", #"^Capture\s+d’écran\s+(\d{4}-\d{2}-\d{2})\s+à\s+(\d{1,2}\.\d{2}\.\d{2})\.png$"#),
    ("German", #"^Bildschirmfoto\s+(\d{4}-\d{2}-\d{2})\s+um\s+(\d{1,2}\.\d{2}\.\d{2})\.png$"#),
    ("Spanish", #"^Captura\s+de\s+pantalla\s+(\d{4}-\d{2}-\d{2})\s+a\s+las?\s+(\d{1,2}\.\d{2}\.\d{2})\.png$"#),
    ("Italian", #"^Schermata\s+(\d{4}-\d{2}-\d{2})\s+alle\s+(\d{1,2}\.\d{2}\.\d{2})\.png$"#),
    ("Russian", #"^Снимок\s+экрана\s+(\d{4}-\d{2}-\d{2})\s+в\s+(\d{1,2}\.\d{2}\.\d{2})\.png$"#),
    ("Japanese", #"^スクリーンショット\s+(\d{4}-\d{2}-\d{2})\s+(\d{1,2}\.\d{2}\.\d{2})\.png$"#),
    ("Simplified Chinese", #"^屏幕快照\s+(\d{4}-\d{2}-\d{2})\s+(\d{1,2}\.\d{2}\.\d{2})\.png$"#),
    ("Korean", #"^스크린샷\s+(\d{4}-\d{2}-\d{2})\s+오[전후]\s+(\d{1,2}\.\d{2}\.\d{2})\.png$"#),
    ("iOS Simulator", #"^Simulator\s+Screen\s+Shot\s+-\s+(.+)\s+-\s+(\d{4}-\d{2}-\d{2})\s+at\s+(\d{1,2}\.\d{2}\.\d{2})\.png$"#)
]

let testFilenames = [
    "Screenshot 2026-09-29 at 09.15.30.png",
    "Screen Shot 2026-09-29 at 9.04.12.png",
    "Capture d’écran 2026-09-29 à 14.22.01.png",
    "Bildschirmfoto 2026-09-29 um 18.45.10.png",
    "Captura de pantalla 2026-09-29 a las 11.30.00.png",
    "Schermata 2026-09-29 alle 16.12.44.png",
    "Снимок экрана 2026-09-29 в 20.15.00.png",
    "スクリーンショット 2026-09-29 21.00.12.png",
    "屏幕快照 2026-09-29 10.30.15.png",
    "스크린샷 2026-09-29 오후 3.12.00.png",
    "Simulator Screen Shot - iPhone 16 Pro - 2026-09-29 at 10.00.00.png",
    "Invoice_August_2026.pdf",
    "vacation_photo.jpeg",
    "README.md"
]

print("Scanning sample filenames against localized pattern matrix:\n")

for filename in testFilenames {
    var matched = false
    for item in localizedPatterns {
        if let regex = try? NSRegularExpression(pattern: item.pattern, options: [.caseInsensitive]) {
            let range = NSRange(filename.startIndex..<filename.endIndex, in: filename)
            if let match = regex.firstMatch(in: filename, options: [], range: range) {
                print("✅ MATCH [\(item.language)]")
                print("   File: \(filename)")
                if match.numberOfRanges > 1 {
                    for i in 1..<match.numberOfRanges {
                        let subRange = match.range(at: i)
                        if let swiftRange = Range(subRange, in: filename) {
                            print("   Group \(i): \(filename[swiftRange])")
                        }
                    }
                }
                matched = true
                break
            }
        }
    }
    if !matched {
        print("❌ REJECTED (Non-screenshot or unsupported pattern): \(filename)")
    }
    print("------------------------------------------------------------")
}
