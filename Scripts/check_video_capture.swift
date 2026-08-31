#!/usr/bin/env swift

import AppKit
import CoreGraphics
import Foundation
import ScreenCaptureKit

_ = NSApplication.shared

let content = try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: true)
guard let window = content.windows.first(where: {
    $0.windowLayer == 0 &&
    $0.frame.width > 100 &&
    $0.frame.height > 100 &&
    $0.owningApplication?.applicationName != "ClipShot"
}) else {
    fputs("No capturable window found.\n", stderr)
    exit(1)
}

let configuration = SCStreamConfiguration()
configuration.width = Int(window.frame.width)
configuration.height = Int(window.frame.height)
configuration.showsCursor = false
let filter = SCContentFilter(desktopIndependentWindow: window)
let frame: CGImage = try await withCheckedThrowingContinuation { continuation in
    SCScreenshotManager.captureImage(contentFilter: filter, configuration: configuration) { image, error in
        if let image {
            continuation.resume(returning: image)
        } else {
            continuation.resume(throwing: error ?? CocoaError(.fileReadUnknown))
        }
    }
}

print("Captured \(window.owningApplication?.applicationName ?? "Unknown"): \(frame.width)x\(frame.height)")
