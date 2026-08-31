import XCTest
import AppKit
@testable import ClipShotCore

final class ImageUtilsTests: XCTestCase {

    func testSupportedExtensions() {
        XCTAssertTrue(ImageUtils.isImageFile(at: URL(fileURLWithPath: "test.png")))
        XCTAssertTrue(ImageUtils.isImageFile(at: URL(fileURLWithPath: "test.jpg")))
        XCTAssertTrue(ImageUtils.isImageFile(at: URL(fileURLWithPath: "test.jpeg")))
        XCTAssertTrue(ImageUtils.isImageFile(at: URL(fileURLWithPath: "test.heic")))
        XCTAssertTrue(ImageUtils.isImageFile(at: URL(fileURLWithPath: "test.tiff")))

        XCTAssertFalse(ImageUtils.isImageFile(at: URL(fileURLWithPath: "test.txt")))
        XCTAssertFalse(ImageUtils.isImageFile(at: URL(fileURLWithPath: "test.pdf")))
        XCTAssertFalse(ImageUtils.isImageFile(at: URL(fileURLWithPath: "test.zip")))
    }

    func testPNGConversion() {
        let size = NSSize(width: 50, height: 50)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.blue.drawSwatch(in: NSRect(origin: .zero, size: size))
        image.unlockFocus()

        let pngData = ImageUtils.pngData(from: image)
        XCTAssertNotNil(pngData)
        XCTAssertGreaterThan(pngData?.count ?? 0, 0)
    }
}
