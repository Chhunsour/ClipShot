import XCTest
@testable import ClipShotCore

final class RecordingFormatTests: XCTestCase {

    func testRecordingDefaults() {
        let testDefaults = UserDefaults(suiteName: "com.clipshot.tests.\(UUID().uuidString)")!
        let settings = AppSettings(defaults: testDefaults)

        XCTAssertEqual(settings.recordingFormat, "MP4")
        XCTAssertEqual(settings.recordingFPS, 60)
        XCTAssertFalse(settings.recordMicrophone)
        XCTAssertEqual(settings.captureDelaySeconds, 0)
    }

    func testRecordingFPSFallback() {
        let suiteName = "com.clipshot.tests.\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        testDefaults.set(0, forKey: "recordingFPS")

        let settings = AppSettings(defaults: testDefaults)
        XCTAssertEqual(settings.recordingFPS, 60)

        testDefaults.set(-10, forKey: "recordingFPS")
        let settingsNegative = AppSettings(defaults: testDefaults)
        XCTAssertEqual(settingsNegative.recordingFPS, 60)
    }

    func testRecordingFormatPersistence() {
        let suiteName = "com.clipshot.tests.\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        let settings = AppSettings(defaults: testDefaults)

        settings.recordingFormat = "GIF"
        settings.recordingFPS = 30
        settings.recordMicrophone = true

        let reloaded = AppSettings(defaults: testDefaults)
        XCTAssertEqual(reloaded.recordingFormat, "GIF")
        XCTAssertEqual(reloaded.recordingFPS, 30)
        XCTAssertTrue(reloaded.recordMicrophone)
    }
}
