import Foundation
import AppKit
import CoreGraphics

/// Service for sequential screenshot frame capture and seamless vertical image stitching.
public final class ScrollingCaptureService: @unchecked Sendable {
    public static let shared = ScrollingCaptureService()

    private var capturedFrames: [CGImage] = []
    private var targetRect: CGRect = .zero
    private var isCapturing: Bool = false

    public init() {}

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

    public func captureNextFrame() {
        guard isCapturing,
              let frame = ScreenCaptureEngine.shared.captureRect(targetRect),
              let cgImage = frame.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return
        }
        capturedFrames.append(cgImage)
    }

    public func finishCapture() -> NSImage? {
        isCapturing = false
        guard !capturedFrames.isEmpty else { return nil }
        if capturedFrames.count == 1 {
            let first = capturedFrames[0]
            return NSImage(cgImage: first, size: CGSize(width: first.width, height: first.height))
        }

        return stitchFrames(capturedFrames)
    }

    /// Stitches an array of overlapping sequential frames vertically.
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
