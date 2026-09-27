#!/usr/bin/env swift
import Foundation
import AppKit

print("--- ClipShot: macOS Display Topology Inspector ---")

let screens = NSScreen.screens
print("Detected \(screens.count) connected screen(s):\n")

for (index, screen) in screens.enumerated() {
    let frame = screen.frame
    let visible = screen.visibleFrame
    let scale = screen.backingScaleFactor
    let isMain = (screen == NSScreen.main)

    let physicalW = Int(round(frame.width * scale))
    let physicalH = Int(round(frame.height * scale))

    print("Screen [\(index + 1)]: \(screen.localizedName)")
    print("  Role:           \(isMain ? "Main Display" : "Secondary Display")")
    print("  Frame:          Origin (\(Int(frame.origin.x)), \(Int(frame.origin.y))), Size (\(Int(frame.width)) × \(Int(frame.height)) pt)")
    print("  Visible Frame:  Origin (\(Int(visible.origin.x)), \(Int(visible.origin.y))), Size (\(Int(visible.width)) × \(Int(visible.height)) pt)")
    print("  Backing Scale:  \(scale)x")
    print("  Native Pixels:  \(physicalW) × \(physicalH) px")

    if #available(macOS 12.0, *) {
        let topInset = screen.safeAreaInsets.top
        print("  Top Safe Inset: \(topInset) pt \(topInset > 0 ? "(Hardware Notch Present)" : "(No Hardware Notch)")")
    }
    print("")
}
