#!/usr/bin/env swift
import Foundation

print("--- ClipShot: Event Burst Debouncing & Deduplication Simulator ---")

final class DebounceFilter {
    private let cooldownWindow: TimeInterval
    private var lastAcceptedTimestamp: [String: Date] = [:]

    init(cooldownWindow: TimeInterval) {
        self.cooldownWindow = cooldownWindow
    }

    func shouldProcess(eventKey: String, at timestamp: Date) -> (accept: Bool, elapsed: TimeInterval?) {
        if let last = lastAcceptedTimestamp[eventKey] {
            let elapsed = timestamp.timeIntervalSince(last)
            if elapsed < cooldownWindow {
                return (false, elapsed)
            }
        }
        lastAcceptedTimestamp[eventKey] = timestamp
        return (true, nil)
    }
}

let filter = DebounceFilter(cooldownWindow: 0.350) // 350ms debounce window

struct SimulatedEvent {
    let offsetMs: Double
    let key: String
}

// Simulating a user holding down or mashing a capture shortcut, then pausing, then capturing another screen
let eventSequence: [SimulatedEvent] = [
    // Burst 1: Cmd+Shift+3 capture on multi-monitor generating dual events in 10ms
    SimulatedEvent(offsetMs: 0, key: "screen-main"),
    SimulatedEvent(offsetMs: 12, key: "screen-main"),
    SimulatedEvent(offsetMs: 25, key: "screen-main"),
    SimulatedEvent(offsetMs: 40, key: "screen-secondary"),
    SimulatedEvent(offsetMs: 55, key: "screen-secondary"),
    SimulatedEvent(offsetMs: 120, key: "screen-main"),
    
    // Idle pause of 500ms
    SimulatedEvent(offsetMs: 650, key: "screen-main"),
    SimulatedEvent(offsetMs: 680, key: "screen-main"),
    SimulatedEvent(offsetMs: 700, key: "screen-secondary")
]

let baseDate = Date()
var acceptedCount = 0
var suppressedCount = 0

print(String(format: "%-10@ %-18@ %-16@ %-18@", "Time(ms)", "Event Key", "Status", "Details"))
print(String(repeating: "-", count: 64))

for event in eventSequence {
    let eventTime = baseDate.addingTimeInterval(event.offsetMs / 1000.0)
    let (accepted, elapsed) = filter.shouldProcess(eventKey: event.key, at: eventTime)

    if accepted {
        acceptedCount += 1
        print(String(format: "%-10.0f %-18@ %-16@ %-18@", event.offsetMs, event.key, "ACCEPTED ✅", "Dispatched to worker"))
    } else {
        suppressedCount += 1
        let elapsedMs = (elapsed ?? 0) * 1000.0
        print(String(format: "%-10.0f %-18@ %-16@ (Suppressed: %.0fms < 350ms)", event.offsetMs, event.key, "DEBOUNCED 🛡️", elapsedMs))
    }
}

let reductionPct = Double(suppressedCount) / Double(eventSequence.count) * 100.0
print("\nSummary Statistics:")
print("  Total Raw Inbound Events:    \(eventSequence.count)")
print("  Accepted Discrete Captures:  \(acceptedCount)")
print("  Suppressed Duplicate Events: \(suppressedCount)")
print(String(format: "  Noise Reduction:             %.1f%% duplicate work prevented", reductionPct))
