import XCTest
@testable import ClipShotCore

final class ClipNotchColorwayTests: XCTestCase {

    func testColorwayCountIsFourteen() {
        XCTAssertEqual(ClipNotchColorway.allCases.count, 14)
    }

    func testHexColorsCountIsThreeForStaticPalettes() {
        for colorway in ClipNotchColorway.allCases {
            XCTAssertEqual(colorway.hexColors.count, 3, "Colorway \(colorway.rawValue) should define 3 colors")
        }
    }

    func testColorwayIdentifiableMatchesRawValue() {
        for colorway in ClipNotchColorway.allCases {
            XCTAssertEqual(colorway.id, colorway.rawValue)
        }
    }
}
