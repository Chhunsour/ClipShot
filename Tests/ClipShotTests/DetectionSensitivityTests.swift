import XCTest
@testable import ClipShotCore

final class DetectionSensitivityTests: XCTestCase {

    func testDetectionSensitivityCases() {
        XCTAssertEqual(DetectionSensitivity.allCases.count, 3)
        XCTAssertEqual(DetectionSensitivity.strict.rawValue, "strict")
        XCTAssertEqual(DetectionSensitivity.balanced.rawValue, "balanced")
        XCTAssertEqual(DetectionSensitivity.permissive.rawValue, "permissive")
    }

    func testTitlesAreDescriptive() {
        XCTAssertEqual(DetectionSensitivity.strict.title, "Strict")
        XCTAssertEqual(DetectionSensitivity.balanced.title, "Balanced")
        XCTAssertEqual(DetectionSensitivity.permissive.title, "Permissive")
    }
}
