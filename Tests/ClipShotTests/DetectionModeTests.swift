import XCTest
@testable import ClipShotCore

final class DetectionModeTests: XCTestCase {

    func testDetectionModeCases() {
        XCTAssertEqual(DetectionMode.allCases.count, 2)
        XCTAssertEqual(DetectionMode.allCases, [.screenshotsOnly, .allImages])
        XCTAssertEqual(DetectionMode.screenshotsOnly.rawValue, "screenshots_only")
        XCTAssertEqual(DetectionMode.allImages.rawValue, "all_images")
    }

    func testIdentifiableIDsMatchRawValues() {
        for mode in DetectionMode.allCases {
            XCTAssertEqual(mode.id, mode.rawValue)
        }
    }

    func testTitlesAreDescriptiveAndAccurate() {
        XCTAssertEqual(DetectionMode.screenshotsOnly.title, "macOS screenshots only")
        XCTAssertEqual(DetectionMode.allImages.title, "Any new image in screenshot folder")
    }

    func testCodableSerializationRoundtrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for original in DetectionMode.allCases {
            let data = try encoder.encode(original)
            let decoded = try decoder.decode(DetectionMode.self, from: data)
            XCTAssertEqual(decoded, original)
        }
    }

    func testInvalidRawValueReturnsNil() {
        XCTAssertNil(DetectionMode(rawValue: "invalid_mode"))
        XCTAssertNil(DetectionMode(rawValue: ""))
        XCTAssertNil(DetectionMode(rawValue: "screenshots"))
    }
}
