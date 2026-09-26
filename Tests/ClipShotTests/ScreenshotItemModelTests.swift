import XCTest
@testable import ClipShotCore

final class ScreenshotItemModelTests: XCTestCase {

    func testScreenshotItemDimensionsString() {
        let emptyItem = ScreenshotItem(fileURL: URL(fileURLWithPath: "/tmp/shot.png"))
        XCTAssertEqual(emptyItem.dimensionsString, "Unknown size")

        let dimensionedItem = ScreenshotItem(
            fileURL: URL(fileURLWithPath: "/tmp/shot.png"),
            pixelWidth: 2560,
            pixelHeight: 1440
        )
        XCTAssertEqual(dimensionedItem.dimensionsString, "2560 × 1440")
    }

    func testScreenshotItemFormattedFileSize() {
        let item = ScreenshotItem(
            fileURL: URL(fileURLWithPath: "/tmp/shot.png"),
            fileSize: 1024 * 1024 * 2 // 2 MB
        )
        XCTAssertFalse(item.formattedFileSize.isEmpty)
    }

    func testScreenshotItemSectionTitleToday() {
        let item = ScreenshotItem(
            fileURL: URL(fileURLWithPath: "/tmp/shot.png"),
            createdAt: Date()
        )
        XCTAssertEqual(item.sectionTitle, "Today")
    }

    func testScreenshotItemCodableRoundTrip() throws {
        let original = ScreenshotItem(
            fileURL: URL(fileURLWithPath: "/tmp/shot.png"),
            fileName: "shot.png",
            fileSize: 4096,
            pixelWidth: 800,
            pixelHeight: 600
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ScreenshotItem.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.fileName, decoded.fileName)
        XCTAssertEqual(original.fileSize, decoded.fileSize)
        XCTAssertEqual(original.pixelWidth, decoded.pixelWidth)
        XCTAssertEqual(original.pixelHeight, decoded.pixelHeight)
    }
}
