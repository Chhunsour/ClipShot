import Foundation
import XCTest
@testable import ClipShotCore

final class ScreenshotMetadataSanitizationTests: XCTestCase {
    func testDimensionsStringFormatting() {
        let zeroItem = ScreenshotItem(
            fileURL: URL(fileURLWithPath: "/tmp/zero.png"),
            pixelWidth: 0,
            pixelHeight: 0
        )
        XCTAssertEqual(zeroItem.dimensionsString, "Unknown size")

        let invalidItem = ScreenshotItem(
            fileURL: URL(fileURLWithPath: "/tmp/invalid.png"),
            pixelWidth: -10,
            pixelHeight: 100
        )
        XCTAssertEqual(invalidItem.dimensionsString, "Unknown size")

        let retinaItem = ScreenshotItem(
            fileURL: URL(fileURLWithPath: "/tmp/retina.png"),
            pixelWidth: 2880,
            pixelHeight: 1800
        )
        XCTAssertEqual(retinaItem.dimensionsString, "2880 × 1800")
    }

    func testFileNameDefaultsToURLLastPathComponent() {
        let url = URL(fileURLWithPath: "/Users/test/Desktop/Screen Shot 2026-09-28 at 02.00.00.png")
        let item = ScreenshotItem(fileURL: url)
        XCTAssertEqual(item.fileName, "Screen Shot 2026-09-28 at 02.00.00.png")

        let customItem = ScreenshotItem(fileURL: url, fileName: "CustomName.png")
        XCTAssertEqual(customItem.fileName, "CustomName.png")
    }

    func testDisplayPathSubstitutesTildeForHomeDirectory() {
        let home = NSHomeDirectory()
        let desktopURL = URL(fileURLWithPath: "\(home)/Desktop/Screenshots")
        let display = PathUtils.shared.displayPath(for: desktopURL)
        XCTAssertEqual(display, "~/Desktop/Screenshots")

        let rootURL = URL(fileURLWithPath: "/Library/Application Support")
        let rootDisplay = PathUtils.shared.displayPath(for: rootURL)
        XCTAssertEqual(rootDisplay, "/Library/Application Support")
    }

    func testSectionTitleForToday() {
        let item = ScreenshotItem(
            fileURL: URL(fileURLWithPath: "/tmp/today.png"),
            createdAt: Date()
        )
        XCTAssertEqual(item.sectionTitle, "Today")
    }

    func testScreenshotItemCodableRoundtrip() throws {
        let original = ScreenshotItem(
            fileURL: URL(fileURLWithPath: "/tmp/sample.png"),
            fileName: "sample.png",
            createdAt: Date(timeIntervalSince1970: 1700000000),
            fileSize: 1024 * 512,
            pixelWidth: 1920,
            pixelHeight: 1080,
            isDeletedFromDisk: true,
            thumbnailCachedPath: "/tmp/thumb.png",
            preservedCopyPath: "/tmp/preserved.png"
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ScreenshotItem.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.fileURL, original.fileURL)
        XCTAssertEqual(decoded.fileName, original.fileName)
        XCTAssertEqual(decoded.fileSize, original.fileSize)
        XCTAssertEqual(decoded.pixelWidth, original.pixelWidth)
        XCTAssertEqual(decoded.pixelHeight, original.pixelHeight)
        XCTAssertEqual(decoded.isDeletedFromDisk, original.isDeletedFromDisk)
        XCTAssertEqual(decoded.thumbnailCachedPath, original.thumbnailCachedPath)
        XCTAssertEqual(decoded.preservedCopyPath, original.preservedCopyPath)
    }
}
