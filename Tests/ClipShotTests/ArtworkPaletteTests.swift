import AppKit
import XCTest
@testable import ClipShotCore

final class ArtworkPaletteTests: XCTestCase {
    func testPaletteFindsThreeVisibleDistinctArtworkColors() throws {
        let context = try XCTUnwrap(CGContext(
            data: nil,
            width: 30,
            height: 10,
            bitsPerComponent: 8,
            bytesPerRow: 30 * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        for (index, color) in [NSColor.systemRed, .systemGreen, .systemBlue].enumerated() {
            context.setFillColor(color.cgColor)
            context.fill(CGRect(x: index * 10, y: 0, width: 10, height: 10))
        }
        let image = NSImage(cgImage: try XCTUnwrap(context.makeImage()), size: NSSize(width: 30, height: 10))

        let colors = ArtworkPalette.colors(from: image)

        XCTAssertEqual(colors.count, 3)
        XCTAssertTrue(colors.allSatisfy { ($0.usingColorSpace(.sRGB) ?? $0).brightnessComponent >= 0.58 })
        XCTAssertGreaterThan(colorDistance(colors[0], colors[1]), 0.18)
        XCTAssertGreaterThan(colorDistance(colors[1], colors[2]), 0.18)
    }

    func testBlankArtworkUsesThreeColorFallback() {
        XCTAssertEqual(ArtworkPalette.colors(from: NSImage()).count, 3)
    }

    func testPrimaryColorPreservesArtworkHue() throws {
        let source = NSColor(srgbRed: 0.12, green: 0.67, blue: 0.35, alpha: 1)
        let context = try XCTUnwrap(CGContext(
            data: nil,
            width: 12,
            height: 12,
            bitsPerComponent: 8,
            bytesPerRow: 12 * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.setFillColor(source.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: 12, height: 12))
        let image = NSImage(cgImage: try XCTUnwrap(context.makeImage()), size: NSSize(width: 12, height: 12))

        let primary = try XCTUnwrap(ArtworkPalette.colors(from: image).first?.usingColorSpace(.sRGB))
        XCTAssertEqual(primary.hueComponent, source.hueComponent, accuracy: 0.03)
        XCTAssertEqual(primary.saturationComponent, source.saturationComponent, accuracy: 0.08)
    }

    func testMonochromeArtworkDoesNotInventAColor() throws {
        let image = NSImage(size: NSSize(width: 12, height: 12), flipped: false) { rect in
            NSColor(white: 0.62, alpha: 1).setFill()
            rect.fill()
            return true
        }

        let primary = try XCTUnwrap(ArtworkPalette.colors(from: image).first?.usingColorSpace(.sRGB))
        XCTAssertLessThan(primary.saturationComponent, 0.02)
    }

    private func colorDistance(_ lhs: NSColor, _ rhs: NSColor) -> CGFloat {
        let left = lhs.usingColorSpace(.sRGB) ?? lhs
        let right = rhs.usingColorSpace(.sRGB) ?? rhs
        return hypot(hypot(left.redComponent - right.redComponent, left.greenComponent - right.greenComponent), left.blueComponent - right.blueComponent)
    }
}
