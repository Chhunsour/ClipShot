#!/usr/bin/env swift
import Foundation
import CoreGraphics

print("--- ClipShot: Precision Keyboard Pixel Nudge Simulation ---")

enum ArrowKey: String {
    case left = "Left Arrow (123)"
    case right = "Right Arrow (124)"
    case down = "Down Arrow (125)"
    case up = "Up Arrow (126)"

    var delta: (dx: CGFloat, dy: CGFloat) {
        switch self {
        case .left: return (-1, 0)
        case .right: return (1, 0)
        case .down: return (0, 1)
        case .up: return (0, -1)
        }
    }
}

func simulateNudge(
    initialRect: CGRect,
    key: ArrowKey,
    shift: Bool,
    displayBounds: CGRect
) -> CGRect {
    let multiplier: CGFloat = shift ? 10.0 : 1.0
    let dx = key.delta.dx * multiplier
    let dy = key.delta.dy * multiplier

    var nudged = initialRect
    nudged.origin.x += dx
    nudged.origin.y += dy

    // Boundary constraint enforcement
    nudged.origin.x = max(displayBounds.minX, min(nudged.origin.x, displayBounds.maxX - nudged.width))
    nudged.origin.y = max(displayBounds.minY, min(nudged.origin.y, displayBounds.maxY - nudged.height))
    return nudged
}

let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
var rect = CGRect(x: 100, y: 100, width: 400, height: 300)

print(String(format: "Initial Selection: (x: %.0f, y: %.0f, w: %.0f, h: %.0f)", rect.origin.x, rect.origin.y, rect.width, rect.height))
print("Screen Constraints: 0, 0 to 1920, 1080\n")

let testActions: [(key: ArrowKey, shift: Bool, description: String)] = [
    (.right, false, "Micro-nudge Right (+1px)"),
    (.right, true, "Macro-nudge Right with Shift (+10px)"),
    (.down, false, "Micro-nudge Down (+1px)"),
    (.down, true, "Macro-nudge Down with Shift (+10px)"),
    (.left, true, "Macro-nudge Left with Shift (-10px)"),
    (.up, true, "Macro-nudge Up with Shift (-10px)")
]

for action in testActions {
    let before = rect
    rect = simulateNudge(initialRect: rect, key: action.key, shift: action.shift, displayBounds: screen)
    print("Action: \(action.description)")
    print(String(format: "  Before: (%.0f, %.0f) -> After: (%.0f, %.0f) [Delta: Δx=%.0f, Δy=%.0f]\n",
                 before.origin.x, before.origin.y, rect.origin.x, rect.origin.y,
                 rect.origin.x - before.origin.x, rect.origin.y - before.origin.y))
}

// Test edge clamping
print("Testing edge clamping at screen boundary:")
var edgeRect = CGRect(x: 1915, y: 500, width: 10, height: 10)
print(String(format: "Near Right Edge: x=%.0f, maxX=%.0f", edgeRect.origin.x, edgeRect.maxX))
edgeRect = simulateNudge(initialRect: edgeRect, key: .right, shift: true, displayBounds: screen)
print(String(format: "After +10px Right Nudge: x=%.0f, maxX=%.0f (Clamped to 1920 max)\n", edgeRect.origin.x, edgeRect.maxX))
