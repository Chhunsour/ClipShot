import XCTest
@testable import ClipShotCore

final class RecentCaptureShelfModelTests: XCTestCase {

    func testRecentShelfPresentationKind() {
        let items = [
            ScreenshotItem(fileURL: URL(fileURLWithPath: "/tmp/shot1.png")),
            ScreenshotItem(fileURL: URL(fileURLWithPath: "/tmp/shot2.png"))
        ]
        let state = ClipNotchState.recentShelf(items: items)
        XCTAssertEqual(state.presentationKind, .recentShelf)
    }

    func testRecentShelfStateEquality() {
        let id1 = UUID()
        let id2 = UUID()
        let item1 = ScreenshotItem(id: id1, fileURL: URL(fileURLWithPath: "/tmp/shot1.png"))
        let item2 = ScreenshotItem(id: id2, fileURL: URL(fileURLWithPath: "/tmp/shot2.png"))

        let stateA = ClipNotchState.recentShelf(items: [item1, item2])
        let stateB = ClipNotchState.recentShelf(items: [item1, item2])
        let stateC = ClipNotchState.recentShelf(items: [item1])

        XCTAssertEqual(stateA, stateB)
        XCTAssertNotEqual(stateA, stateC)
    }

    func testRecentShelfItemsPrefixLimiting() {
        let items = (0..<10).map { index in
            ScreenshotItem(
                fileURL: URL(fileURLWithPath: "/tmp/shot\(index).png"),
                fileName: "shot\(index).png"
            )
        }
        let maxShelfDisplay = 6
        let limited = Array(items.prefix(maxShelfDisplay))
        XCTAssertEqual(limited.count, 6)
        XCTAssertEqual(limited.first?.fileName, "shot0.png")
        XCTAssertEqual(limited.last?.fileName, "shot5.png")
    }

    func testRecentShelfFilterNonDeletedItems() {
        let activeItem = ScreenshotItem(fileURL: URL(fileURLWithPath: "/tmp/active.png"), isDeletedFromDisk: false)
        let deletedItem = ScreenshotItem(fileURL: URL(fileURLWithPath: "/tmp/deleted.png"), isDeletedFromDisk: true)

        let all = [activeItem, deletedItem]
        let available = all.filter { !$0.isDeletedFromDisk }

        XCTAssertEqual(available.count, 1)
        XCTAssertEqual(available.first?.fileURL.lastPathComponent, "active.png")
    }
}
