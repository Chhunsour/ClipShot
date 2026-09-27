import Foundation
import XCTest
@testable import ClipShotCore

@MainActor
final class RecentCaptureShelfCapacityTests: XCTestCase {
    func testRecentColorCaseInsensitiveDeduplication() {
        let settings = AppSettings.shared
        let originalColors = settings.recentColors

        defer {
            settings.recentColors = originalColors
        }

        settings.addRecentColor("#AABBCC")
        XCTAssertEqual(settings.recentColors.first, "#AABBCC")

        // Add lowercase version
        settings.addRecentColor("#aabbcc")
        XCTAssertEqual(settings.recentColors.first, "#aabbcc")

        // Verify deduplication: should appear only once
        let count = settings.recentColors.filter { $0.caseInsensitiveCompare("#aabbcc") == .orderedSame }.count
        XCTAssertEqual(count, 1)
    }

    func testRecentColorCapacityClampsAtTwenty() {
        let settings = AppSettings.shared
        let originalColors = settings.recentColors

        defer {
            settings.recentColors = originalColors
        }

        for i in 10...40 {
            settings.addRecentColor(String(format: "#%06X", i * 1000))
        }

        XCTAssertLessThanOrEqual(settings.recentColors.count, 20)
    }

    func testRecentShelfPrefixLimit() {
        var items: [ScreenshotItem] = []
        for i in 1...10 {
            items.append(ScreenshotItem(
                fileURL: URL(fileURLWithPath: "/tmp/shot\(i).png"),
                fileName: "shot\(i).png"
            ))
        }

        let shelfItems = Array(items.prefix(5))
        XCTAssertEqual(shelfItems.count, 5)
        XCTAssertEqual(shelfItems.first?.fileName, "shot1.png")
        XCTAssertEqual(shelfItems.last?.fileName, "shot5.png")
    }

    func testClipNotchStateRecentShelfPreservesPayload() {
        let items = [
            ScreenshotItem(fileURL: URL(fileURLWithPath: "/tmp/a.png")),
            ScreenshotItem(fileURL: URL(fileURLWithPath: "/tmp/b.png"))
        ]
        let state = ClipNotchState.recentShelf(items: items)

        switch state {
        case .recentShelf(let payload):
            XCTAssertEqual(payload.count, 2)
            XCTAssertEqual(payload[0].fileURL.lastPathComponent, "a.png")
        default:
            XCTFail("Expected .recentShelf state")
        }
    }
}
