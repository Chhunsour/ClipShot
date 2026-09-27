import Foundation
import XCTest
@testable import ClipShotCore

final class HistoryRetentionPruningTests: XCTestCase {
    func testHistoryRetentionCasesAndTitles() {
        XCTAssertEqual(HistoryRetention.allCases.count, 5)
        XCTAssertEqual(HistoryRetention.unlimited.rawValue, 0)
        XCTAssertEqual(HistoryRetention.unlimited.title, "Never")

        XCTAssertEqual(HistoryRetention.oneDay.rawValue, 1)
        XCTAssertEqual(HistoryRetention.oneDay.title, "1 day")

        XCTAssertEqual(HistoryRetention.sevenDays.rawValue, 7)
        XCTAssertEqual(HistoryRetention.sevenDays.title, "7 days")

        XCTAssertEqual(HistoryRetention.thirtyDays.rawValue, 30)
        XCTAssertEqual(HistoryRetention.thirtyDays.title, "30 days")

        XCTAssertEqual(HistoryRetention.ninetyDays.rawValue, 90)
        XCTAssertEqual(HistoryRetention.ninetyDays.title, "90 days")

        for ret in HistoryRetention.allCases {
            XCTAssertEqual(ret.id, ret.rawValue)
        }
    }

    func testHistoryLimitCasesAndTitles() {
        XCTAssertEqual(HistoryLimit.allCases.count, 5)
        XCTAssertEqual(HistoryLimit.twenty.rawValue, 20)
        XCTAssertEqual(HistoryLimit.fifty.rawValue, 50)
        XCTAssertEqual(HistoryLimit.hundred.rawValue, 100)
        XCTAssertEqual(HistoryLimit.fiveHundred.rawValue, 500)
        XCTAssertEqual(HistoryLimit.unlimited.rawValue, 0)

        XCTAssertEqual(HistoryLimit.twenty.title, "20 screenshots")
        XCTAssertEqual(HistoryLimit.unlimited.title, "Unlimited")

        for limit in HistoryLimit.allCases {
            XCTAssertEqual(limit.id, limit.rawValue)
        }
    }

    func testRetentionCutoffDateCalculations() {
        let now = Date()

        for retention in [HistoryRetention.oneDay, .sevenDays, .thirtyDays, .ninetyDays] {
            let days = Double(retention.rawValue)
            let cutoff = now.addingTimeInterval(-days * 86400.0)
            let interval = now.timeIntervalSince(cutoff)
            XCTAssertEqual(interval, days * 86400.0, accuracy: 0.001)
        }
    }

    func testExpiredItemFilteringLogic() {
        let now = Date()
        let cutoffDate = now.addingTimeInterval(-7 * 86400.0) // 7 days ago

        let freshItem = ScreenshotItem(
            fileURL: URL(fileURLWithPath: "/tmp/fresh.png"),
            createdAt: now.addingTimeInterval(-2 * 86400.0) // 2 days ago
        )
        let boundaryItem = ScreenshotItem(
            fileURL: URL(fileURLWithPath: "/tmp/boundary.png"),
            createdAt: cutoffDate.addingTimeInterval(60.0) // 1 minute fresher than cutoff
        )
        let expiredItem = ScreenshotItem(
            fileURL: URL(fileURLWithPath: "/tmp/expired.png"),
            createdAt: now.addingTimeInterval(-10 * 86400.0) // 10 days ago
        )

        let items = [freshItem, boundaryItem, expiredItem]
        let retained = items.filter { $0.createdAt >= cutoffDate }
        let expired = items.filter { $0.createdAt < cutoffDate }

        XCTAssertEqual(retained.count, 2)
        XCTAssertEqual(expired.count, 1)
        XCTAssertEqual(expired.first?.fileName, "expired.png")
    }

    func testCodableRoundtrips() throws {
        for ret in HistoryRetention.allCases {
            let data = try JSONEncoder().encode(ret)
            let decoded = try JSONDecoder().decode(HistoryRetention.self, from: data)
            XCTAssertEqual(decoded, ret)
        }

        for limit in HistoryLimit.allCases {
            let data = try JSONEncoder().encode(limit)
            let decoded = try JSONDecoder().decode(HistoryLimit.self, from: data)
            XCTAssertEqual(decoded, limit)
        }
    }
}
