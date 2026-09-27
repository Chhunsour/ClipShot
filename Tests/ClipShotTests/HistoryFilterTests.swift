import XCTest
@testable import ClipShotCore

final class HistoryFilterTests: XCTestCase {

    private func filterItems(_ items: [ScreenshotItem], query: String) -> [ScreenshotItem] {
        if query.isEmpty { return items }
        return items.filter {
            $0.fileName.localizedCaseInsensitiveContains(query) ||
            $0.dimensionsString.localizedCaseInsensitiveContains(query)
        }
    }

    func testEmptyQueryReturnsAllItems() {
        let items = [
            ScreenshotItem(fileURL: URL(fileURLWithPath: "/tmp/shot1.png")),
            ScreenshotItem(fileURL: URL(fileURLWithPath: "/tmp/shot2.png"))
        ]
        let filtered = filterItems(items, query: "")
        XCTAssertEqual(filtered.count, 2)
    }

    func testCaseInsensitiveFileNameQuery() {
        let items = [
            ScreenshotItem(fileURL: URL(fileURLWithPath: "/tmp/Dashboard_Preview.png")),
            ScreenshotItem(fileURL: URL(fileURLWithPath: "/tmp/Settings_Mockup.png")),
            ScreenshotItem(fileURL: URL(fileURLWithPath: "/tmp/dashboard_final.png"))
        ]
        let filtered = filterItems(items, query: "dashboard")
        XCTAssertEqual(filtered.count, 2)
        XCTAssertEqual(filtered.map(\.fileName), ["Dashboard_Preview.png", "dashboard_final.png"])
    }

    func testDimensionsStringQuery() {
        let items = [
            ScreenshotItem(fileURL: URL(fileURLWithPath: "/tmp/a.png"), pixelWidth: 1920, pixelHeight: 1080),
            ScreenshotItem(fileURL: URL(fileURLWithPath: "/tmp/b.png"), pixelWidth: 2560, pixelHeight: 1440),
            ScreenshotItem(fileURL: URL(fileURLWithPath: "/tmp/c.png"), pixelWidth: 1280, pixelHeight: 720)
        ]
        let filtered = filterItems(items, query: "1440")
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.fileName, "b.png")
    }

    func testNonMatchingQueryReturnsEmpty() {
        let items = [
            ScreenshotItem(fileURL: URL(fileURLWithPath: "/tmp/screen.png"))
        ]
        let filtered = filterItems(items, query: "NonExistentKey12345")
        XCTAssertTrue(filtered.isEmpty)
    }
}
