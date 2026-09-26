import XCTest
@testable import ClipShotCore

final class HistoryLimitTests: XCTestCase {

    func testHistoryLimitCases() {
        XCTAssertEqual(HistoryLimit.allCases.count, 5)
        XCTAssertEqual(HistoryLimit.twenty.rawValue, 20)
        XCTAssertEqual(HistoryLimit.fifty.rawValue, 50)
        XCTAssertEqual(HistoryLimit.hundred.rawValue, 100)
        XCTAssertEqual(HistoryLimit.fiveHundred.rawValue, 500)
        XCTAssertEqual(HistoryLimit.unlimited.rawValue, 0)
    }

    func testTitlesAreDescriptive() {
        XCTAssertEqual(HistoryLimit.twenty.title, "20 screenshots")
        XCTAssertEqual(HistoryLimit.fifty.title, "50 screenshots")
        XCTAssertEqual(HistoryLimit.hundred.title, "100 screenshots")
        XCTAssertEqual(HistoryLimit.fiveHundred.title, "500 screenshots")
        XCTAssertEqual(HistoryLimit.unlimited.title, "Unlimited")
    }
}
