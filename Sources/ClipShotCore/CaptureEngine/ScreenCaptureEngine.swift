import Foundation
import AppKit
import CoreGraphics
import ScreenCaptureKit

/// High-performance display capture engine capable of capturing exact rects, screens, and multi-display regions.
public final class ScreenCaptureEngine: @unchecked Sendable {
    public static let shared = ScreenCaptureEngine()

    public init() {}

    /// Captures a global virtual coordinate rect across any connected display.
    public func captureRect(_ rect: CGRect) -> NSImage? {
        guard rect.width > 0 && rect.height > 0 else { return nil }

        // Use CGWindowListCreateImage for instantaneous capture of composite desktop
        guard let cgImage = CGWindowListCreateImage(
            rect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            [.bestResolution]
        ) else {
            return nil
        }

        return NSImage(cgImage: cgImage, size: rect.size)
    }

    /// Captures a specific NSScreen display in full resolution.
    public func captureScreen(_ screen: NSScreen) -> NSImage? {
        let frame = screen.frame
        // Convert AppKit screen coordinate (bottom-left origin) to CoreGraphics global coordinate (top-left origin)
        let primaryScreenHeight = NSScreen.screens.first?.frame.height ?? frame.height
        let cgRect = CGRect(
            x: frame.origin.x,
            y: primaryScreenHeight - frame.origin.y - frame.height,
            width: frame.width,
            height: frame.height
        )
        return captureRect(cgRect)
    }

    /// Captures all connected displays combined into one image.
    public func captureAllDisplays() -> NSImage? {
        var unionRect = CGRect.null
        let primaryScreenHeight = NSScreen.screens.first?.frame.height ?? 0

        for screen in NSScreen.screens {
            let frame = screen.frame
            let cgRect = CGRect(
                x: frame.origin.x,
                y: primaryScreenHeight - frame.origin.y - frame.height,
                width: frame.width,
                height: frame.height
            )
            unionRect = unionRect.union(cgRect)
        }

        guard !unionRect.isNull else { return nil }
        return captureRect(unionRect)
    }

    /// Captures a single pixel color at the given global screen point.
    public func sampleColor(at globalPoint: CGPoint) -> NSColor? {
        let sampleRect = CGRect(x: globalPoint.x, y: globalPoint.y, width: 1, height: 1)
        guard let cgImage = CGWindowListCreateImage(
            sampleRect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            [.nominalResolution]
        ) else {
            return nil
        }

        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        return bitmapRep.colorAt(x: 0, y: 0)
    }

    /// Captures a 21x21 pixel magnifying region centered on globalPoint for precision loupe.
    public func captureMagnifierRegion(at globalPoint: CGPoint, size: Int = 21) -> CGImage? {
        let half = CGFloat(size / 2)
        let rect = CGRect(x: globalPoint.x - half, y: globalPoint.y - half, width: CGFloat(size), height: CGFloat(size))
        return CGWindowListCreateImage(rect, .optionOnScreenOnly, kCGNullWindowID, [.bestResolution])
    }
}
