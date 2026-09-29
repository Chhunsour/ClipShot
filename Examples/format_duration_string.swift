#!/usr/bin/env swift
import Foundation

print("--- ClipShot: Screen Recording Duration String Formatter ---")

func formatRecordingDuration(_ totalSeconds: TimeInterval, includeHoursAlways: Bool = false) -> String {
    let clamped = max(0, totalSeconds)
    let totalInt = Int(clamped)
    
    let hours = totalInt / 3600
    let minutes = (totalInt % 3600) / 60
    let seconds = totalInt % 60

    if hours > 0 || includeHoursAlways {
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    } else {
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

func formatPreciseDuration(_ totalSeconds: TimeInterval) -> String {
    let clamped = max(0, totalSeconds)
    let totalInt = Int(clamped)
    let tenths = Int((clamped - Double(totalInt)) * 10)
    
    let minutes = (totalInt % 3600) / 60
    let seconds = totalInt % 60
    let hours = totalInt / 3600

    if hours > 0 {
        return String(format: "%02d:%02d:%02d.%d", hours, minutes, seconds, tenths)
    } else {
        return String(format: "%02d:%02d.%d", minutes, seconds, tenths)
    }
}

let testDurations: [(seconds: TimeInterval, description: String)] = [
    (0.0, "Zero initial state"),
    (0.85, "Sub-second opening tick"),
    (4.2, "Quick 4-second GIF capture"),
    (59.9, "One minute boundary"),
    (60.0, "Exactly one minute"),
    (83.4, "1 minute 23 seconds"),
    (3599.0, "59 minutes 59 seconds"),
    (3600.0, "Exactly one hour"),
    (3665.1, "1 hour 1 minute 5 seconds"),
    (43200.0, "12 hours continuous recording session"),
    (-10.0, "Negative clock skew guard")
]

print(String(format: "%-16@ %-14@ %-16@ %-32@", "Seconds", "Standard", "High-Precision", "Scenario"))
print(String(repeating: "-", count: 78))

for item in testDurations {
    let standard = formatRecordingDuration(item.seconds)
    let precise = formatPreciseDuration(item.seconds)
    print(String(format: "%-16.1f %-14@ %-16@ %-32@", item.seconds, standard, precise, item.description))
}

print("\n--- DateComponentsFormatter Comparison ---")
let formatter = DateComponentsFormatter()
formatter.allowedUnits = [.hour, .minute, .second]
formatter.zeroFormattingBehavior = [.pad]

let benchmarkSeconds: TimeInterval = 3723.0
let customFormatted = formatRecordingDuration(benchmarkSeconds)
let systemFormatted = formatter.string(from: benchmarkSeconds) ?? ""

print("Custom Format:  \(customFormatted)")
print("System Format:  \(systemFormatted)")
print("Matches expectation: \(customFormatted == systemFormatted ? "YES ✅" : "NO ❌")")
