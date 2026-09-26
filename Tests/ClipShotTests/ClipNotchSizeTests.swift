import XCTest
@testable import ClipShotCore

final class ClipNotchSizeTests: XCTestCase {

    func testClipNotchSizeAllCases() {
        XCTAssertEqual(ClipNotchSize.allCases.count, 6)
        let expected: [ClipNotchSize] = [.compact, .normal, .large, .extraLarge, .ultraWide, .studio]
        XCTAssertEqual(ClipNotchSize.allCases, expected)
    }

    func testClipNotchSizeIdentifiers() {
        for size in ClipNotchSize.allCases {
            XCTAssertFalse(size.id.isEmpty)
            XCTAssertEqual(size.id, size.rawValue)
        }
    }

    func testClipNotchSizeOrdering() {
        XCTAssertTrue(ClipNotchSize.compact < ClipNotchSize.normal)
        XCTAssertTrue(ClipNotchSize.normal < ClipNotchSize.large)
        XCTAssertTrue(ClipNotchSize.large < ClipNotchSize.extraLarge)
        XCTAssertTrue(ClipNotchSize.extraLarge < ClipNotchSize.ultraWide)
        XCTAssertTrue(ClipNotchSize.ultraWide < ClipNotchSize.studio)
    }

    func testClipNotchSizeDimensionsAndRadii() {
        var previousWidth: CGFloat = 0
        for size in ClipNotchSize.allCases {
            let dims = size.idleDimensions
            XCTAssertGreaterThan(dims.width, previousWidth)
            XCTAssertGreaterThan(dims.height, 0)
            XCTAssertGreaterThan(size.bottomCornerRadius, 0)
            XCTAssertGreaterThan(size.topWingRadius, 0)
            previousWidth = dims.width
        }
    }
}
