import XCTest
@testable import ClipShotCore

final class AppSettingsDefaultsExtendedTests: XCTestCase {

    func testExtendedDefaultValues() {
        let testDefaults = UserDefaults(suiteName: "com.clipshot.tests.\(UUID().uuidString)")!
        let settings = AppSettings(defaults: testDefaults)

        XCTAssertFalse(settings.playSoundOnCopy)
        XCTAssertTrue(settings.notifyOnError)
        XCTAssertTrue(settings.preferPNG)
        XCTAssertTrue(settings.preserveTransparency)
        XCTAssertTrue(settings.preserveOriginalResolution)
        XCTAssertTrue(settings.pausePreviewOnHover)
        XCTAssertTrue(settings.showMagnifier)
        XCTAssertTrue(settings.showDimensions)
        XCTAssertTrue(settings.includeWindowShadow)
        XCTAssertTrue(settings.freezeScreenOnCapture)
        XCTAssertFalse(settings.storeDeletedScreenshotCopies)
    }

    func testAppearancePersistence() {
        let suiteName = "com.clipshot.tests.\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        let settings = AppSettings(defaults: testDefaults)

        settings.appearance = .dark
        XCTAssertEqual(settings.appearance, .dark)

        let reloaded = AppSettings(defaults: testDefaults)
        XCTAssertEqual(reloaded.appearance, .dark)
    }

    func testDetectionSensitivityPersistence() {
        let suiteName = "com.clipshot.tests.\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        let settings = AppSettings(defaults: testDefaults)

        settings.detectionSensitivity = .permissive
        XCTAssertEqual(settings.detectionSensitivity, .permissive)

        let reloaded = AppSettings(defaults: testDefaults)
        XCTAssertEqual(reloaded.detectionSensitivity, .permissive)
    }

    func testClipboardModePersistence() {
        let suiteName = "com.clipshot.tests.\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        let settings = AppSettings(defaults: testDefaults)

        settings.clipboardMode = .fileOnly
        XCTAssertEqual(settings.clipboardMode, .fileOnly)

        let reloaded = AppSettings(defaults: testDefaults)
        XCTAssertEqual(reloaded.clipboardMode, .fileOnly)
    }
}
