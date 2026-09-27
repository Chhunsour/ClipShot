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
        for content in ClipNotchIdleContent.allCases {
            XCTAssertEqual(content.id, content.rawValue)
        }
    }

    func testPlacementModeCodableRoundTrip() throws {
        for mode in ClipNotchPlacementMode.allCases {
            let data = try JSONEncoder().encode(mode)
            let decoded = try JSONDecoder().decode(ClipNotchPlacementMode.self, from: data)
            XCTAssertEqual(mode, decoded)
        }
    }

    func testIdleContentCodableRoundTrip() throws {
        for content in ClipNotchIdleContent.allCases {
            let data = try JSONEncoder().encode(content)
            let decoded = try JSONDecoder().decode(ClipNotchIdleContent.self, from: data)
            XCTAssertEqual(content, decoded)
        }
    }
}
