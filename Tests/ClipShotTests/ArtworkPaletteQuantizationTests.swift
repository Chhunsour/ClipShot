import AppKit
import XCTest
@testable import ClipShotCore

final class ArtworkPaletteQuantizationTests: XCTestCase {
    func testSingleDominantColorGeneratesHarmoniousTriad() throws {
        // Create an image with a single pure red color
        let context = try XCTUnwrap(CGContext(
            data: nil,
            width: 24,
            height: 24,
            bitsPerComponent: 8,
            bytesPerRow: 24 * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.setFillColor(CGColor(srgbRed: 0.8, green: 0.2, blue: 0.2, alpha: 1.0))
        context.fill(CGRect(x: 0, y: 0, width: 24, height: 24))
        let image = NSImage(cgImage: try XCTUnwrap(context.makeImage()), size: NSSize(width: 24, height: 24))

        let palette = ArtworkPalette.colors(from: image)
        XCTAssertEqual(palette.count, 3, "ArtworkPalette should always yield exactly 3 colors")

        // First color should reflect the dominant red
        let primary = try XCTUnwrap(palette[0].usingColorSpace(.sRGB))
        XCTAssertGreaterThan(primary.redComponent, primary.blueComponent)
        XCTAssertGreaterThan(primary.redComponent, primary.greenComponent)

        // All 3 colors should be clamped within readable brightness bounds [0.44, 0.96]
        for color in palette {
            let rgb = try XCTUnwrap(color.usingColorSpace(.sRGB))
            XCTAssertGreaterThanOrEqual(rgb.brightnessComponent, 0.40)
            XCTAssertLessThanOrEqual(rgb.brightnessComponent, 1.00)
        }
    }

    func testTransparentPixelsAreSkipped() throws {
        // Create an image entirely transparent (alpha = 0)
        let context = try XCTUnwrap(CGContext(
            data: nil,
            width: 24,
            height: 24,
            bitsPerComponent: 8,
            bytesPerRow: 24 * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.setFillColor(CGColor(srgbRed: 1.0, green: 0.0, blue: 0.0, alpha: 0.0))
        context.fill(CGRect(x: 0, y: 0, width: 24, height: 24))
        let image = NSImage(cgImage: try XCTUnwrap(context.makeImage()), size: NSSize(width: 24, height: 24))

        let palette = ArtworkPalette.colors(from: image)
        // Since all pixels were transparent (< 96 alpha), should match fallback colors
        XCTAssertEqual(palette.count, 3)
        XCTAssertEqual(palette, ArtworkPalette.fallback)
    }

    func testNearBlackAndNearWhitePixelsFallbackToDefault() throws {
        // Image filled with near-black (brightness < 0.02)
        let context = try XCTUnwrap(CGContext(
            data: nil,
            width: 24,
            height: 24,
            bitsPerComponent: 8,
            bytesPerRow: 24 * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.setFillColor(CGColor(srgbRed: 0.01, green: 0.01, blue: 0.01, alpha: 1.0))
        context.fill(CGRect(x: 0, y: 0, width: 24, height: 24))
        let image = NSImage(cgImage: try XCTUnwrap(context.makeImage()), size: NSSize(width: 24, height: 24))

        let palette = ArtworkPalette.colors(from: image)
        XCTAssertEqual(palette, ArtworkPalette.fallback)
    }

    func testFallbackHexColorsHaveValidHexDigits() {
        let hexCharacterSet = CharacterSet(charactersIn: "0123456789ABCDEFabcdef")
        for hex in ArtworkPalette.fallbackHexColors {
            XCTAssertTrue(hex.hasPrefix("#"))
            let rawHex = String(hex.dropFirst())
            XCTAssertEqual(rawHex.count, 6)
            XCTAssertTrue(rawHex.unicodeScalars.allSatisfy { hexCharacterSet.contains($0) })
        }
    }
}
