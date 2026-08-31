import Foundation
import AppKit
import CoreGraphics

/// Service for discovering, highlighting, and capturing individual application windows.
public final class WindowCaptureService: @unchecked Sendable {
    public static let shared = WindowCaptureService()

    public init() {}

    /// Returns a list of visible on-screen windows.
    public func getVisibleWindows() -> [WindowInfo] {
        guard let windowListInfo = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[CFString: Any]] else {
            return []
        }

        var windows: [WindowInfo] = []

        for info in windowListInfo {
            guard let windowID = info[kCGWindowNumber] as? CGWindowID,
                  let layer = info[kCGWindowLayer] as? Int,
                  layer == 0, // Normal window layer (exclude menu bar, wallpaper, dock)
                  let boundsDict = info[kCGWindowBounds] as? [String: Any],
                  let bounds = CGRect(dictionaryRepresentation: boundsDict as CFDictionary),
                  bounds.width > 50 && bounds.height > 50 else {
                continue
            }

            let ownerName = info[kCGWindowOwnerName] as? String ?? ""
            let windowName = info[kCGWindowName] as? String ?? ""

            // Skip ClipShot's own overlay windows
            if ownerName.caseInsensitiveCompare(AppConfig.appName) == .orderedSame {
                continue
            }

            let window = WindowInfo(
                id: windowID,
                windowName: windowName,
                ownerName: ownerName,
                bounds: bounds,
                windowLayer: layer
            )
            windows.append(window)
        }

        return windows
    }

    /// Finds the top-most visible window under a given global coordinate point.
    public func window(at point: CGPoint) -> WindowInfo? {
        let windows = getVisibleWindows()
        return windows.first { $0.bounds.contains(point) }
    }

    /// Captures a specific window by its CGWindowID.
    public func captureWindow(_ windowInfo: WindowInfo, includeShadow: Bool = true) -> NSImage? {
        var options: CGWindowImageOption = [.bestResolution]
        if !includeShadow {
            options.insert(.boundsIgnoreFraming)
        }

        guard let cgImage = CGWindowListCreateImage(
            .null,
            .optionIncludingWindow,
            windowInfo.id,
            options
        ) else {
            // Fallback: capture by rect
            return ScreenCaptureEngine.shared.captureRect(windowInfo.bounds)
        }

        return NSImage(cgImage: cgImage, size: windowInfo.bounds.size)
    }
}
