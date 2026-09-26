import XCTest
@testable import ClipShotCore

final class ClipNotchFinishTests: XCTestCase {

    func testFinishCountIsSix() {
        XCTAssertEqual(ClipNotchFinish.allCases.count, 6)
    }

    func testFinishRawValues() {
        XCTAssertEqual(ClipNotchFinish.obsidian.rawValue, "Obsidian")
        XCTAssertEqual(ClipNotchFinish.glass.rawValue, "Glass")
        XCTAssertEqual(ClipNotchFinish.bloom.rawValue, "Bloom")
        XCTAssertEqual(ClipNotchFinish.titanium.rawValue, "Titanium")
        XCTAssertEqual(ClipNotchFinish.neonAura.rawValue, "Neon Aura")
        XCTAssertEqual(ClipNotchFinish.frosted.rawValue, "Frosted")
    }

    func testIdentifiableMatchesRawValue() {
        for finish in ClipNotchFinish.allCases {
            XCTAssertEqual(finish.id, finish.rawValue)
        }
    }
}
