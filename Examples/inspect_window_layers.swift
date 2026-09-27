#!/usr/bin/env swift
import Foundation
import AppKit

print("--- ClipShot: macOS Window Level & Layer Hierarchy Inspector ---")

struct WindowLayerSpec {
    let name: String
    let level: NSWindow.Level
    let description: String
    let usedForInClipShot: String
}

let layers: [WindowLayerSpec] = [
    WindowLayerSpec(
        name: "normal",
        level: .normal,
        description: "Standard document and utility windows",
        usedForInClipShot: "Settings window, History browser"
    ),
    WindowLayerSpec(
        name: "floating",
        level: .floating,
        description: "Floats above standard application windows",
        usedForInClipShot: "FloatingToolPanel (quick annotations/copy)"
    ),
    WindowLayerSpec(
        name: "statusBar",
        level: .statusBar,
        description: "Level of macOS status bar items and menu extras",
        usedForInClipShot: "ClipNotch collapsed header bar"
    ),
    WindowLayerSpec(
        name: "modalPanel",
        level: .modalPanel,
        description: "Above floating windows, blocks input to normal windows",
        usedForInClipShot: "Command palette modal sheet"
    ),
    WindowLayerSpec(
        name: "screenSaver",
        level: .screenSaver,
        description: "Top-most layer above virtually all system UI",
        usedForInClipShot: "CaptureOverlayController (full-screen crosshair overlay)"
    )
]

for spec in layers.sorted(by: { $0.level.rawValue < $1.level.rawValue }) {
    print("Layer: [NSWindow.Level.\(spec.name)]")
    print("  Raw CGWindowLevel: \(spec.level.rawValue)")
    print("  System Role:       \(spec.description)")
    print("  ClipShot Usage:    \(spec.usedForInClipShot)\n")
}
