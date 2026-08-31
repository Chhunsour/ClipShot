#!/usr/bin/env swift

import AppKit
import CoreGraphics
import Darwin
import Foundation

guard let app = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == "ClipShot" }) else {
    fputs("ClipShot is not running.\n", stderr)
    exit(1)
}

func notchBounds() -> CGRect? {
    let windows = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] ?? []
    return windows.compactMap { window -> CGRect? in
        guard window[kCGWindowOwnerPID as String] as? pid_t == app.processIdentifier,
              window[kCGWindowLayer as String] as? Int == 25,
              let dictionary = window[kCGWindowBounds as String] as? [String: Any] else { return nil }
        return CGRect(dictionaryRepresentation: dictionary as CFDictionary)
    }
    .filter { $0.minY < 100 }
    .max { $0.width < $1.width }
}

let originalCursor = CGEvent(source: nil)?.location ?? CGPoint(x: 100, y: 100)
defer {
    CGEvent(
        mouseEventSource: nil,
        mouseType: .mouseMoved,
        mouseCursorPosition: originalCursor,
        mouseButton: .left
    )?.post(tap: .cghidEventTap)
}

CGEvent(
    mouseEventSource: nil,
    mouseType: .mouseMoved,
    mouseCursorPosition: CGPoint(x: 100, y: 300),
    mouseButton: .left
)?.post(tap: .cghidEventTap)
var idleBounds: CGRect?
var stableIdleSamples = 0
var previousIdleWidth: CGFloat?
for _ in 0..<240 {
    if let bounds = notchBounds(), (190...270).contains(bounds.width) {
        if let previousIdleWidth, abs(bounds.width - previousIdleWidth) <= 0.5 {
            stableIdleSamples += 1
        } else {
            stableIdleSamples = 1
        }
        previousIdleWidth = bounds.width
        if stableIdleSamples >= 12 {
            idleBounds = bounds
            break
        }
    } else {
        stableIdleSamples = 0
        previousIdleWidth = nil
    }
    usleep(16_667)
}

guard let idleBounds else {
    fputs("ClipNotch did not return to idle before the hover check.\n", stderr)
    exit(1)
}

let hoverPoint = CGPoint(x: idleBounds.midX, y: idleBounds.midY)
CGEvent(
    mouseEventSource: nil,
    mouseType: .mouseMoved,
    mouseCursorPosition: hoverPoint,
    mouseButton: .left
)?.post(tap: .cghidEventTap)

func sampledWidths(count: Int) -> [Int] {
    var widths: [Int] = []
    for _ in 0..<count {
        if let width = notchBounds()?.width {
            widths.append(Int(width.rounded()))
        }
        usleep(16_667)
    }
    return widths
}

let hoverWidths = sampledWidths(count: 60)
let hoverLargestStep = zip(hoverWidths, hoverWidths.dropFirst()).map { abs($1 - $0) }.max() ?? 0
print("Hover-only widths: \(hoverWidths.reduce(into: [Int]()) { if $0.last != $1 { $0.append($1) } })")

let idleWidth = Int(idleBounds.width.rounded())
guard hoverWidths.last.map({ abs($0 - idleWidth) <= 2 }) == true, hoverLargestStep <= 5 else {
    fputs("ClipNotch resized or oscillated from hover alone.\n", stderr)
    exit(1)
}

CGEvent(
    mouseEventSource: nil,
    mouseType: .leftMouseDown,
    mouseCursorPosition: hoverPoint,
    mouseButton: .left
)?.post(tap: .cghidEventTap)
CGEvent(
    mouseEventSource: nil,
    mouseType: .leftMouseUp,
    mouseCursorPosition: hoverPoint,
    mouseButton: .left
)?.post(tap: .cghidEventTap)

var widths: [Int] = []
for _ in 0..<90 {
    if let width = notchBounds()?.width {
        widths.append(Int(width.rounded()))
    }
    usleep(16_667)
}

let stableWidths = widths.reduce(into: [Int]()) { result, width in
    if result.last != width { result.append(width) }
}
let states = widths.compactMap { width -> String? in
    if abs(width - idleWidth) <= 4 { return "idle" }
    if width > 280 { return "expanded" }
    return nil
}.reduce(into: [String]()) { result, state in
    if result.last != state { result.append(state) }
}
let largestStep = zip(widths, widths.dropFirst()).map { abs($1 - $0) }.max() ?? 0

print("Click-expand widths: \(stableWidths)")
print("Click-expand states: \(states)")
print("Largest frame-to-frame width jump: \(largestStep) px")

guard widths.last.map({ $0 > 280 }) == true, states.count <= 2, largestStep <= 40 else {
    fputs("ClipNotch snapped, oscillated, or failed to remain expanded during hover.\n", stderr)
    exit(1)
}
