import XCTest
@testable import ClipShotCore

final class ClipNotchMotionTests: XCTestCase {

    func testMotionProfilesCountIsFive() {
        XCTAssertEqual(ClipNotchMotion.allCases.count, 5)
    }

    func testOrbitDurationsArePositive() {
        for motion in ClipNotchMotion.allCases {
            XCTAssertGreaterThan(motion.orbitDuration, 0)
            XCTAssertGreaterThan(motion.musicOrbHoverScale, 1.0)
        }
    }

    func testIdentifiableMatchesRawValue() {
        for motion in ClipNotchMotion.allCases {
            XCTAssertEqual(motion.id, motion.rawValue)
        }
    }
}
