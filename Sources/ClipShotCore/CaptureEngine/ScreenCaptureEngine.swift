import Foundation
import AppKit
import CoreGraphics
import ScreenCaptureKit

/// High-performance display capture engine capable of capturing exact rects, screens, and multi-display regions.
///
/// ## Coordinate Systems
/// macOS uses two distinct coordinate systems:
/// - **AppKit (Cocoa)**: Origin `(0, 0)` is at the bottom-left of the primary display, with y-values increasing upwards.
/// - **CoreGraphics (Quartz)**: Origin `(0, 0)` is at the top-left of the primary display, with y-values increasing downwards.
///
/// `ScreenCaptureEngine` performs seamless bidirectional conversions to ensure that rects selected in Cocoa
/// views are translated into accurate Quartz capture regions.
public final class ScreenCaptureEngine: @unchecked Sendable {
    /// Shared singleton capture engine instance.
    public static let shared = ScreenCaptureEngine()

    /// Default public initializer.
    public init() {}

    /// Captures a global virtual coordinate rect across any connected display.
    ///
    /// Uses `CGWindowListCreateImage` with `.bestResolution` to preserve high-DPI Retina fidelity.
    ///
    /// - Parameter rect: Global CoreGraphics screen coordinates defining the region to capture.
    /// - Returns: Rendered `NSImage` sized to logical points, or `nil` if rect is empty or permissions denied.
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
    ///
    /// Translates the target display's AppKit frame into CoreGraphics top-left origin coordinates
    /// based on the primary screen's vertical bounds before capturing.
    ///
    /// - Parameter screen: The target `NSScreen` instance to snapshot.
    /// - Returns: Rendered full-screen `NSImage` or `nil` on failure.
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

    /// Captures all connected displays combined into one unified multi-screen image.
    ///
    /// Computes the minimal bounding box enclosing all active display frames in the virtual desktop layout.
    ///
    /// - Returns: Composite `NSImage` spanning all connected monitors.
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
    ///
    /// Uses `.nominalResolution` to capture a fast 1x1 bitmap rep for instant color sampling.
    ///
    /// - Parameter globalPoint: Screen coordinate in CoreGraphics points.
    /// - Returns: Sampled `NSColor` at the specified point, or `nil` if offscreen.
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

    /// Captures a centered magnifying region around globalPoint for precision pixel loupe rendering.
    ///
    /// - Parameters:
    ///   - globalPoint: Center point coordinate.
    ///   - size: Diameter/edge length of square region in pixels (defaults to 21).
    /// - Returns: `CGImage` of the magnified region.
    public func captureMagnifierRegion(at globalPoint: CGPoint, size: Int = 21) -> CGImage? {
        let half = CGFloat(size / 2)
        let rect = CGRect(x: globalPoint.x - half, y: globalPoint.y - half, width: CGFloat(size), height: CGFloat(size))
        return CGWindowListCreateImage(rect, .optionOnScreenOnly, kCGNullWindowID, [.bestResolution])
    }
}
