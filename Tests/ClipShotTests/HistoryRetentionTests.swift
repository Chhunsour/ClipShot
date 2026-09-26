import XCTest
@testable import ClipShotCore

final class HistoryRetentionTests: XCTestCase {

    func testHistoryRetentionCases() {
        XCTAssertEqual(HistoryRetention.allCases.count, 5)
        XCTAssertEqual(HistoryRetention.unlimited.rawValue, 0)
        XCTAssertEqual(HistoryRetention.oneDay.rawValue, 1)
        XCTAssertEqual(HistoryRetention.sevenDays.rawValue, 7)
        XCTAssertEqual(HistoryRetention.thirtyDays.rawValue, 30)
        XCTAssertEqual(HistoryRetention.ninetyDays.rawValue, 90)
    }

    func testTitlesAreDescriptive() {
        XCTAssertEqual(HistoryRetention.unlimited.title, "Never")
        XCTAssertEqual(HistoryRetention.oneDay.title, "1 day")
        XCTAssertEqual(HistoryRetention.sevenDays.title, "7 days")
        XCTAssertEqual(HistoryRetention.thirtyDays.title, "30 days")
        XCTAssertEqual(HistoryRetention.ninetyDays.title, "90 days")
    }
}
