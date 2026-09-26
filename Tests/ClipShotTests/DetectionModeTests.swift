import XCTest
@testable import ClipShotCore

final class DetectionModeTests: XCTestCase {

    func testDetectionModeCases() {
        XCTAssertEqual(DetectionMode.allCases.count, 2)
        XCTAssertEqual(DetectionMode.screenshotsOnly.rawValue, "screenshots_only")
        XCTAssertEqual(DetectionMode.allImages.rawValue, "all_images")
    }

    func testTitlesAreDescriptive() {
        XCTAssertFalse(DetectionMode.screenshotsOnly.title.isEmpty)
        XCTAssertFalse(DetectionMode.allImages.title.isEmpty)
    }
}
