#!/usr/bin/env swift

import AppKit
import CoreGraphics
import Darwin
import Foundation

let desktop = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
let existingFiles = Set((try? FileManager.default.contentsOfDirectory(atPath: desktop.path)) ?? [])
let pasteboard = NSPasteboard.general
let initialChangeCount = pasteboard.changeCount
let startedAt = ProcessInfo.processInfo.systemUptime

let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: 20, keyDown: true)!
keyDown.flags = [.maskCommand, .maskShift]
keyDown.post(tap: .cghidEventTap)

let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: 20, keyDown: false)!
keyUp.flags = [.maskCommand, .maskShift]
keyUp.post(tap: .cghidEventTap)

while pasteboard.changeCount == initialChangeCount,
      ProcessInfo.processInfo.systemUptime - startedAt < 8 {
    usleep(5_000)
}

let latency = (ProcessInfo.processInfo.systemUptime - startedAt) * 1_000
usleep(500_000)

let currentFiles = Set((try? FileManager.default.contentsOfDirectory(atPath: desktop.path)) ?? [])
for fileName in currentFiles.subtracting(existingFiles) {
    try? FileManager.default.trashItem(
        at: desktop.appendingPathComponent(fileName),
        resultingItemURL: nil
    )
}

print(String(format: "Keyboard screenshot clipboard latency: %.0f ms", latency))
guard latency <= 750 else {
    fputs("Expected clipboard update within 750 ms.\n", stderr)
    exit(1)
}
