import XCTest
@testable import ClipShotCore

final class PreviewCornerTests: XCTestCase {

    func testPreviewCornerCases() {
        XCTAssertEqual(PreviewCorner.allCases.count, 4)
        XCTAssertEqual(PreviewCorner.bottomRight.rawValue, "bottom_right")
        XCTAssertEqual(PreviewCorner.bottomLeft.rawValue, "bottom_left")
        XCTAssertEqual(PreviewCorner.topRight.rawValue, "top_right")
        XCTAssertEqual(PreviewCorner.topLeft.rawValue, "top_left")
    }

    func testTitlesAreDescriptive() {
        XCTAssertEqual(PreviewCorner.bottomRight.title, "Bottom Right")
        XCTAssertEqual(PreviewCorner.bottomLeft.title, "Bottom Left")
    }
}
