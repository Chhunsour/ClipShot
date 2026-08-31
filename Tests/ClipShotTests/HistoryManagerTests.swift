import XCTest
import AppKit
@testable import ClipShotCore

final class HistoryManagerTests: XCTestCase {

    func testHistoryItemModel() {
        let url = URL(fileURLWithPath: "/Users/test/Desktop/Screen Shot 2026-08-31 at 11.00.00.png")
        let item = ScreenshotItem(
            fileURL: url,
            fileSize: 1024 * 1024 * 2, // 2MB
            pixelWidth: 1920,
            pixelHeight: 1080
        )

        XCTAssertEqual(item.dimensionsString, "1920 × 1080")
        XCTAssertEqual(item.fileName, "Screen Shot 2026-08-31 at 11.00.00.png")
        XCTAssertFalse(item.isDeletedFromDisk)
        XCTAssertTrue(item.formattedFileSize.contains("MB") || item.formattedFileSize.contains("2"))
    }

    func testHistoryPruningLimits() {
        let historyManager = HistoryManager()
        let settings = AppSettings.shared
        settings.historyLimit = .twenty

        // Prune check
        historyManager.pruneHistory()
        XCTAssertLessThanOrEqual(historyManager.items.count, 20)
    }
}
