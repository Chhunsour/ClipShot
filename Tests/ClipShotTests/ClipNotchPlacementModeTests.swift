import XCTest
@testable import ClipShotCore

final class ClipNotchPlacementModeTests: XCTestCase {

    func testPlacementModeCountIsThree() {
        XCTAssertEqual(ClipNotchPlacementMode.allCases.count, 3)
    }

    func testPlacementModeIdentifiersMatchRawValues() {
        for mode in ClipNotchPlacementMode.allCases {
            XCTAssertEqual(mode.id, mode.rawValue)
        }
    }

    func testIdleContentOptions() {
        XCTAssertEqual(ClipNotchIdleContent.allCases.count, 2)
        XCTAssertEqual(ClipNotchIdleContent.minimalIcon.rawValue, "Minimal Icon")
        XCTAssertEqual(ClipNotchIdleContent.empty.rawValue, "Completely Empty")
    }
}
