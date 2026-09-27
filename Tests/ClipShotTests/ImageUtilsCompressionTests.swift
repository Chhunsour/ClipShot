import XCTest
import AppKit
@testable import ClipShotCore

final class ImageUtilsCompressionTests: XCTestCase {

    func testPNGMagicBytes() {
        let size = NSSize(width: 32, height: 32)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.red.drawSwatch(in: NSRect(origin: .zero, size: size))
        image.unlockFocus()

        guard let data = ImageUtils.pngData(from: image) else {
            XCTFail("Failed to encode PNG")
            return
        }

        XCTAssertGreaterThan(data.count, 8)
        let header = [UInt8](data.prefix(8))
        let expectedHeader: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
        XCTAssertEqual(header, expectedHeader)
    }

    func testTIFFDataGeneration() {
        let size = NSSize(width: 16, height: 16)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.green.drawSwatch(in: NSRect(origin: .zero, size: size))
        image.unlockFocus()

        let tiff = ImageUtils.tiffData(from: image)
        XCTAssertNotNil(tiff)
        XCTAssertGreaterThan(tiff?.count ?? 0, 0)
    }

    func testAllSupportedExtensionsIncluded() {
        let expected: Set<String> = ["png", "jpg", "jpeg", "tiff", "tif", "heic", "heif", "webp"]
        XCTAssertEqual(ImageUtils.supportedExtensions, expected)
    }
}
