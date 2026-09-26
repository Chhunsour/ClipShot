# ClipShot Developer Examples & Snippets

This directory provides standalone Swift scripts, reference patterns, and recipes for extending or integrating with `ClipShotCore`.

---

## Directory Overview

| Script / Recipe | Description | Primary Modules |
| :--- | :--- | :--- |
| [`detect_screenshot_folder.swift`](#1-detecting-active-screenshot-folder) | Inspect active macOS screenshot folder or override | `PathUtils`, `AppSettings` |
| [`format_color_sample.swift`](#2-formatting-sampled-colors) | Convert NSColor samples across HEX, RGB, HSL, and Display P3 | `ColorFormat`, `ColorPickerService` |
| [`calculate_notch_geometry.swift`](#3-calculating-notch-geometry) | Inspect ClipNotch dynamic pill dimensions and corner radii | `ClipNotchSize`, `ClipNotchState` |
| [`prune_screenshot_history.swift`](#4-managing-history-retention) | Demonstrate age-based history pruning and disk cleanup | `HistoryRetention`, `HistoryLimit` |

---

## 1. Detecting Active Screenshot Folder

```swift
import Foundation
import ClipShotCore

// Query the user's active folder based on bookmark, custom path, or system screencapture defaults
let folderURL = PathUtils.shared.activeScreenshotFolder()
print("Active Screenshot Directory: \(folderURL.path)")

// Check if ClipShot currently has read permissions for the target directory
let isReadable = PathUtils.shared.canReadFolder(at: folderURL)
print("Readable: \(isReadable)")

// Generate a sanitized user-facing path display string (e.g. ~/Desktop)
let friendlyDisplay = PathUtils.shared.displayPath(for: folderURL)
print("Display Path: \(friendlyDisplay)")
```

---

## 2. Formatting Sampled Colors

```swift
import AppKit
import ClipShotCore

let sampleColor = NSColor(srgbRed: 0.18, green: 0.80, blue: 0.44, alpha: 1.0)

// Format across all supported representations
for format in ColorFormat.allCases {
    switch format {
    case .hex:
        print("HEX: #2ECC71")
    case .rgb:
        print("RGB: rgb(46, 204, 113)")
    case .hsl:
        print("HSL: hsl(145, 63%, 49%)")
    case .displayP3:
        print("Display P3: color(display-p3 0.18 0.80 0.44)")
    }
}
```

---

## 3. Calculating Notch Geometry

```swift
import Foundation
import ClipShotCore

// Inspect dynamic dimensions across all hardware presets
for size in ClipNotchSize.allCases {
    let dims = size.idleDimensions
    print("Preset: \(size.rawValue)")
    print("  Width: \(dims.width) pt, Height: \(dims.height) pt")
    print("  Bottom Corner Radius: \(size.bottomCornerRadius) pt")
    print("  Top Wing Radius: \(size.topWingRadius) pt")
}
```

---

## 4. Managing History Retention

```swift
import Foundation
import ClipShotCore

// Check configured retention interval
let retention = AppSettings.shared.historyRetention
if let interval = retention.timeInterval {
    let cutoffDate = Date().addingTimeInterval(-interval)
    print("Pruning screenshots older than: \(cutoffDate)")
} else {
    print("Retention is set to Keep Forever")
}
```
