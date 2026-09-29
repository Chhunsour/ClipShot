import XCTest
@testable import ClipShotCore

final class DetectionSensitivityTests: XCTestCase {

    func testDetectionSensitivityCases() {
        XCTAssertEqual(DetectionSensitivity.allCases.count, 3)
        XCTAssertEqual(DetectionSensitivity.allCases, [.strict, .balanced, .permissive])
        XCTAssertEqual(DetectionSensitivity.strict.rawValue, "strict")
        XCTAssertEqual(DetectionSensitivity.balanced.rawValue, "balanced")
        XCTAssertEqual(DetectionSensitivity.permissive.rawValue, "permissive")
    }

    func testIdentifiableIDsMatchRawValues() {
        for sensitivity in DetectionSensitivity.allCases {
            XCTAssertEqual(sensitivity.id, sensitivity.rawValue)
        }
    }

    func testTitlesAreDescriptive() {
        XCTAssertEqual(DetectionSensitivity.strict.title, "Strict")
        XCTAssertEqual(DetectionSensitivity.balanced.title, "Balanced")
        XCTAssertEqual(DetectionSensitivity.permissive.title, "Permissive")
    }

    func testCodableSerializationRoundtrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for original in DetectionSensitivity.allCases {
            let data = try encoder.encode(original)
            let decoded = try decoder.decode(DetectionSensitivity.self, from: data)
            XCTAssertEqual(decoded, original)
        }
    }

    func testInvalidRawValuesReturnNil() {
        XCTAssertNil(DetectionSensitivity(rawValue: "ultra_strict"))
        XCTAssertNil(DetectionSensitivity(rawValue: ""))
        XCTAssertNil(DetectionSensitivity(rawValue: "default"))
    }
}
