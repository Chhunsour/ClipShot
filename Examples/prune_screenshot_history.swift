#!/usr/bin/env swift
import Foundation

print("--- ClipShot: History Pruning Simulation ---")

enum HistoryRetention: String, CaseIterable {
    case oneDay = "1 Day"
    case threeDays = "3 Days"
    case oneWeek = "1 Week"
    case oneMonth = "1 Month"
    case keepForever = "Keep Forever"

    var timeInterval: TimeInterval? {
        switch self {
        case .oneDay: return 86_400
        case .threeDays: return 86_400 * 3
        case .oneWeek: return 86_400 * 7
        case .oneMonth: return 86_400 * 30
        case .keepForever: return nil
        }
    }
}

struct MockItem {
    let name: String
    let ageInDays: Double
    var date: Date {
        Date().addingTimeInterval(-ageInDays * 86_400)
    }
}

let mockCaptures: [MockItem] = [
    MockItem(name: "screenshot_today.png", ageInDays: 0.1),
    MockItem(name: "screenshot_yesterday.png", ageInDays: 1.2),
    MockItem(name: "screenshot_4_days_ago.png", ageInDays: 4.0),
    MockItem(name: "screenshot_10_days_ago.png", ageInDays: 10.0),
    MockItem(name: "screenshot_45_days_ago.png", ageInDays: 45.0)
]

for retention in HistoryRetention.allCases {
    print("\nRetention Setting: \(retention.rawValue)")
    if let interval = retention.timeInterval {
        let cutoff = Date().addingTimeInterval(-interval)
        let kept = mockCaptures.filter { $0.date >= cutoff }
        let pruned = mockCaptures.filter { $0.date < cutoff }
        print("  Cutoff: \(cutoff)")
        print("  Kept:   \(kept.map { $0.name }.joined(separator: ", "))")
        print("  Pruned: \(pruned.isEmpty ? "(none)" : pruned.map { $0.name }.joined(separator: ", "))")
    } else {
        print("  Keep Forever: All \(mockCaptures.count) captures retained.")
    }
}
