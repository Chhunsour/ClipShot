import XCTest
@testable import ClipShotCore

final class AfterCopyActionTests: XCTestCase {

    func testAllCasesCountAndOrder() {
        let cases = AfterCopyAction.allCases
        XCTAssertEqual(cases.count, 4)
        XCTAssertEqual(cases, [.keep, .trash, .deleteAfterDelay, .ask])
    }

    func testRawValuesAndIDs() {
        XCTAssertEqual(AfterCopyAction.keep.rawValue, "keep")
        XCTAssertEqual(AfterCopyAction.trash.rawValue, "trash")
        XCTAssertEqual(AfterCopyAction.deleteAfterDelay.rawValue, "delete_after_delay")
        XCTAssertEqual(AfterCopyAction.ask.rawValue, "ask")

        for action in AfterCopyAction.allCases {
            XCTAssertEqual(action.id, action.rawValue)
        }
    }

    func testUserFacingTitles() {
        XCTAssertEqual(AfterCopyAction.keep.title, "Keep screenshot file")
        XCTAssertEqual(AfterCopyAction.trash.title, "Move screenshot to Trash")
        XCTAssertEqual(AfterCopyAction.deleteAfterDelay.title, "Delete automatically after delay")
        XCTAssertEqual(AfterCopyAction.ask.title, "Ask from preview")
    }

    func testCodableSerializationRoundtrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for original in AfterCopyAction.allCases {
            let data = try encoder.encode(original)
            let decoded = try decoder.decode(AfterCopyAction.self, from: data)
            XCTAssertEqual(decoded, original)
        }
    }

    func testInvalidRawValueReturnsNil() {
        XCTAssertNil(AfterCopyAction(rawValue: "unknown_action"))
        XCTAssertNil(AfterCopyAction(rawValue: ""))
        XCTAssertNil(AfterCopyAction(rawValue: "delete"))
    }
}
