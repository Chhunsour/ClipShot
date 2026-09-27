#!/usr/bin/env swift
import Foundation

print("--- ClipShot: Humanized Relative Timestamp Formatter ---")

func formatRelativeTimestamp(from date: Date, relativeTo reference: Date = Date()) -> String {
    let delta = reference.timeIntervalSince(date)

    if delta < 0 {
        return "in the future"
    } else if delta < 5 {
        return "just now"
    } else if delta < 60 {
        return String(format: "%.0fs ago", delta)
    } else if delta < 3600 {
        let minutes = Int(delta / 60)
        return "\(minutes)m ago"
    } else if delta < 86400 {
        let hours = Int(delta / 3600)
        return "\(hours)h ago"
    } else if delta < 604800 {
        let days = Int(delta / 86400)
        return "\(days)d ago"
    } else {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

let now = Date()
let intervals: [(seconds: TimeInterval, label: String)] = [
    (2, "Sub-5-second capture"),
    (25, "Recent quick capture"),
    (180, "Three minutes past"),
    (1800, "Half an hour past"),
    (7200, "Two hours past"),
    (86400, "One day past"),
    (259200, "Three days past"),
    (1209600, "Two weeks past")
]

for item in intervals {
    let pastDate = now.addingTimeInterval(-item.seconds)
    let formatted = formatRelativeTimestamp(from: pastDate, relativeTo: now)
    print("Interval: [\(item.label)]")
    print(String(format: "  Elapsed Seconds: %.0fs", item.seconds))
    print("  Humanized Output: \"\(formatted)\"\n")
}
