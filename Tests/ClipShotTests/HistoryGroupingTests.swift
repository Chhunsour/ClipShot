import XCTest
@testable import ClipShotCore

final class HistoryGroupingTests: XCTestCase {

    func testSectionTitleForYesterdayAndOlder() {
        let calendar = Calendar.current
        let now = Date()

        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
              let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else {
            XCTFail("Failed to compute past dates")
            return
        }

        let itemYesterday = ScreenshotItem(fileURL: URL(fileURLWithPath: "/tmp/y.png"), createdAt: yesterday)
        XCTAssertEqual(itemYesterday.sectionTitle, "Yesterday")

        let itemOlder = ScreenshotItem(fileURL: URL(fileURLWithPath: "/tmp/old.png"), createdAt: weekAgo)
        XCTAssertFalse(itemOlder.sectionTitle.isEmpty)
        XCTAssertNotEqual(itemOlder.sectionTitle, "Today")
        XCTAssertNotEqual(itemOlder.sectionTitle, "Yesterday")
    }

    func testGroupedSectionSorting() {
        let items = [
            ScreenshotItem(fileURL: URL(fileURLWithPath: "/tmp/1.png"), createdAt: Date()),
            ScreenshotItem(fileURL: URL(fileURLWithPath: "/tmp/2.png"), createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date())!),
            ScreenshotItem(fileURL: URL(fileURLWithPath: "/tmp/3.png"), createdAt: Calendar.current.date(byAdding: .day, value: -5, to: Date())!)
        ]

        let grouped = Dictionary(grouping: items) { $0.sectionTitle }
        let sortedKeys = grouped.keys.sorted { k1, k2 in
            if k1 == "Today" { return true }
            if k2 == "Today" { return false }
            if k1 == "Yesterday" { return true }
            if k2 == "Yesterday" { return false }
            return k1 > k2
        }

        XCTAssertEqual(sortedKeys.first, "Today")
        XCTAssertEqual(sortedKeys[1], "Yesterday")
        XCTAssertEqual(sortedKeys.count, 3)
    }

    func testEffectiveImageURLPreservedFallback() throws {
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
        let preservedFile = tempDir.appendingPathComponent("preserved_\(UUID().uuidString).png")
        try "fake_data".write(to: preservedFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: preservedFile) }

        let item = ScreenshotItem(
            fileURL: URL(fileURLWithPath: "/tmp/deleted_nonexistent_\(UUID().uuidString).png"),
            isDeletedFromDisk: true,
            preservedCopyPath: preservedFile.path
        )

        XCTAssertEqual(item.effectiveImageURL?.path, preservedFile.path)
    }
}
