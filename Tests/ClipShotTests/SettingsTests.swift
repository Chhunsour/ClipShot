import XCTest
@testable import ClipShotCore

final class SettingsTests: XCTestCase {

    func testDefaultSettings() {
        let testDefaults = UserDefaults(suiteName: "com.clipshot.tests.\(UUID().uuidString)")!
        let settings = AppSettings(defaults: testDefaults)

        XCTAssertTrue(settings.autoCopyEnabled)
        XCTAssertTrue(settings.instantPasteEnabled)
        XCTAssertTrue(settings.monitoringActive)
        XCTAssertFalse(settings.showDockIcon)
        XCTAssertTrue(settings.showMenuBarIcon)
        XCTAssertEqual(settings.detectionMode, .screenshotsOnly)
        XCTAssertEqual(settings.clipboardMode, .imageOnly)
        XCTAssertEqual(settings.afterCopyAction, .keep)
        XCTAssertTrue(settings.showFloatingPreview)
        XCTAssertEqual(settings.previewDuration, 5.0)
        XCTAssertEqual(settings.previewCorner, .bottomRight)
        XCTAssertTrue(settings.historyEnabled)
        XCTAssertEqual(settings.historyLimit, .hundred)
        XCTAssertEqual(settings.historyRetention, .thirtyDays)
        XCTAssertTrue(settings.clipNotchEnabled)
        XCTAssertEqual(settings.clipNotchPlacementMode, .topHeader)
        XCTAssertEqual(settings.clipNotchIdleContent, .minimalIcon)
        XCTAssertEqual(settings.clipNotchSize, .normal)
    }

    func testResetToDefaults() {
        let testDefaults = UserDefaults(suiteName: "com.clipshot.tests.\(UUID().uuidString)")!
        let settings = AppSettings(defaults: testDefaults)

        settings.autoCopyEnabled = false
        settings.instantPasteEnabled = false
        settings.previewDuration = 12.0
        settings.detectionMode = .allImages

        settings.resetToDefaults()

        XCTAssertTrue(settings.autoCopyEnabled)
        XCTAssertTrue(settings.instantPasteEnabled)
        XCTAssertEqual(settings.previewDuration, 5.0)
        XCTAssertEqual(settings.detectionMode, .screenshotsOnly)
    }
}
