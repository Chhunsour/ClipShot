#!/usr/bin/env swift
import Foundation

print("--- ClipShot: ClipNotch State Machine Simulation ---")

enum SimulatedState: String {
    case idle = "Idle"
    case quickActions = "Quick Actions"
    case musicPlayer = "Music Player"
    case videoCapsule = "Video Capsule"
    case videoInterrupted = "Video + Screenshot Interruption"
    case ocrResult = "OCR Result"
}

struct StateMachine {
    private(set) var current: SimulatedState = .idle
    private var interruptedVideo: Bool = false

    mutating func transition(to next: SimulatedState) {
        let previous = current
        current = next
        print("  [\(previous.rawValue)]  ──▶  [\(next.rawValue)]")
    }

    mutating func triggerScreenshotWhilePlaying() {
        print("\n* Event: Screenshot taken during video playback *")
        interruptedVideo = true
        transition(to: .videoInterrupted)
    }

    mutating func dismissScreenshotPreview() {
        print("\n* Event: Screenshot preview auto-dismissed *")
        if interruptedVideo {
            interruptedVideo = false
            transition(to: .videoCapsule)
        } else {
            transition(to: .idle)
        }
    }
}

var notch = StateMachine()
print("Starting in state: [\(notch.current.rawValue)]\n")

// 1. User hovers over notch
print("* Event: User hovers *")
notch.transition(to: .quickActions)

// 2. User plays media
print("\n* Event: Now playing track detected *")
notch.transition(to: .musicPlayer)

// 3. User launches video pip
print("\n* Event: Video stream anchored to notch *")
notch.transition(to: .videoCapsule)

// 4. Screenshot interrupted
notch.triggerScreenshotWhilePlaying()

// 5. Dismissal restores video
notch.dismissScreenshotPreview()

// 6. User closes video
print("\n* Event: Video stream closed *")
notch.transition(to: .idle)
print("\nSimulation completed successfully.")
