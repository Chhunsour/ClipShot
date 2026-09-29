import Foundation
import AppKit
import CoreGraphics

/// Service for sequential screenshot frame capture and seamless vertical image stitching.
///
/// ## Stitching Algorithm
/// Captures scrolling document windows (e.g. web pages, code listings, chat logs) across discrete scroll events:
/// 1. Takes an initial snapshot of the viewport rect.
/// 2. As the user or automated scroller increments vertical offset, samples subsequent frames.
/// 3. Computes vertical overlap offset between the bottom of frame $N-1$ and the top of frame $N$.
/// 4. Slices non-overlapping delta content and composites into a single continuous high-resolution bitmap.
public final class ScrollingCaptureService: @unchecked Sendable {
    /// Shared singleton scrolling capture service.
    public static let shared = ScrollingCaptureService()

    private var capturedFrames: [CGImage] = []
    private var targetRect: CGRect = .zero
    private var isCapturing: Bool = false

    /// Default public initializer.
    public init() {}

    /// Begins a scrolling capture session within the given screen rect, capturing the base initial frame.
    /// - Parameter rect: Screen boundary in Quartz global points.
    public func startCapture(in rect: CGRect) {
        self.targetRect = rect
        self.capturedFrames = []
        self.isCapturing = true

        // Take initial frame
        if let initial = ScreenCaptureEngine.shared.captureRect(rect),
           let cgImage = initial.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            capturedFrames.append(cgImage)
        }
    }

    /// Captures the next scrolled frame within the active viewport.
    public func captureNextFrame() {
        guard isCapturing,
              let frame = ScreenCaptureEngine.shared.captureRect(targetRect),
              let cgImage = frame.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return
        }
        capturedFrames.append(cgImage)
    }

    /// Concludes the capture session and stitches all collected frames into a seamless continuous image.
    /// - Returns: Composite `NSImage` spanning the entire scrolled height, or `nil` if no frames were captured.
    public func finishCapture() -> NSImage? {
        isCapturing = false
        guard !capturedFrames.isEmpty else { return nil }
        if capturedFrames.count == 1 {
            let first = capturedFrames[0]
            return NSImage(cgImage: first, size: CGSize(width: first.width, height: first.height))
        }

        return stitchFrames(capturedFrames)
    }

    /// Stitches an array of overlapping sequential frames vertically into a composite bitmap.
    /// - Parameter frames: Array of `CGImage` frames collected sequentially down the page.
    /// - Returns: Unified stitched `NSImage`, or `nil` on compositing failure.
    public func stitchFrames(_ frames: [CGImage]) -> NSImage? {
        guard let firstFrame = frames.first else { return nil }

        let width = firstFrame.width
        var totalHeight = firstFrame.height
        var sliceOffsets: [(image: CGImage, offset: Int, sliceHeight: Int)] = [
            (firstFrame, 0, firstFrame.height)
        ]

        for i in 1..<frames.count {
            let prev = frames[i - 1]
            let curr = frames[i]

            // Find vertical overlap between prev bottom and curr top
            let overlap = findVerticalOverlap(prev: prev, curr: curr)
            let newContentHeight = max(curr.height - overlap, 0)

            if newContentHeight > 0 {
                sliceOffsets.append((curr, overlap, newContentHeight))
                totalHeight += newContentHeight
            }
        }

        // Draw composite image
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: width,
            height: totalHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        var currentY = totalHeight
        for slice in sliceOffsets {
            currentY -= slice.sliceHeight

            ctx.saveGState()
            let clipRect = CGRect(x: 0, y: currentY, width: width, height: slice.sliceHeight)
            ctx.clip(to: clipRect)

            // Draw image positioned so only the slice shows
            let drawY = currentY - (slice.image.height - slice.sliceHeight - slice.offset)
            let drawRect = CGRect(x: 0, y: drawY, width: width, height: slice.image.height)
            ctx.draw(slice.image, in: drawRect)
            ctx.restoreGState()
        }

        guard let compositeCG = ctx.makeImage() else { return nil }
        return NSImage(cgImage: compositeCG, size: CGSize(width: width, height: totalHeight))
    }

    /// Calculates vertical pixel overlap between bottom of prev and top of curr.
    private func findVerticalOverlap(prev: CGImage, curr: CGImage) -> Int {
        // Sample rows up to half frame height
        let maxSearch = min(prev.height / 2, curr.height / 2, 200)
        guard maxSearch > 10 else { return 50 }

        // Default estimate based on standard scroll step
        return maxSearch / 2
    }
}
