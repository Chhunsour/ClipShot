import XCTest
@testable import ClipShotCore

final class AfterCopyActionTests: XCTestCase {

    func testAfterCopyActionCases() {
        XCTAssertEqual(AfterCopyAction.allCases.count, 4)
        XCTAssertEqual(AfterCopyAction.keep.rawValue, "keep")
        XCTAssertEqual(AfterCopyAction.trash.rawValue, "trash")
        XCTAssertEqual(AfterCopyAction.deleteAfterDelay.rawValue, "delete_after_delay")
        XCTAssertEqual(AfterCopyAction.ask.rawValue, "ask")
    }

    func testTitlesAreDescriptive() {
        XCTAssertEqual(AfterCopyAction.keep.title, "Keep screenshot file")
        XCTAssertEqual(AfterCopyAction.trash.title, "Move screenshot to Trash")
    }
}
