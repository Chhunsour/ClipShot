#!/usr/bin/env swift
import Foundation

// Note: To run with ClipShotCore linked:
// swift run --package-path .. (or import within an Xcode / SPM target)

print("--- ClipShot: Screenshot Directory Resolution ---")

// Standard macOS default screenshot location detection via com.apple.screencapture
if let location = CFPreferencesCopyAppValue("location" as CFString, "com.apple.screencapture" as CFString) as? String {
    let expanded = (location as NSString).expandingTildeInPath
    print("System screencapture preference: \(expanded)")
} else {
    print("System screencapture preference: (default ~/Desktop)")
}

let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
    ?? URL(fileURLWithPath: (("~/Desktop" as NSString).expandingTildeInPath))

print("Default Fallback Directory: \(desktop.path)")

let isReadable = FileManager.default.isReadableFile(atPath: desktop.path)
print("Folder is readable: \(isReadable)")

let home = NSHomeDirectory()
let displayPath = desktop.path.hasPrefix(home) ? "~" + desktop.path.dropFirst(home.count) : desktop.path
print("Display format: \(displayPath)")
