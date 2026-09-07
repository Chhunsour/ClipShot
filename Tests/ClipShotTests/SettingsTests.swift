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
        XCTAssertEqual(settings.clipNotchColorway, .prism)
        XCTAssertEqual(settings.clipNotchFinish, .obsidian)
        XCTAssertEqual(settings.clipNotchMotion, .fluid)
    }

    func testResetToDefaults() {
        let testDefaults = UserDefaults(suiteName: "com.clipshot.tests.\(UUID().uuidString)")!
        let settings = AppSettings(defaults: testDefaults)

        settings.autoCopyEnabled = false
        settings.instantPasteEnabled = false
        settings.previewDuration = 12.0
        settings.detectionMode = .allImages
        settings.clipNotchColorway = .ember
        settings.clipNotchFinish = .glass
        settings.clipNotchMotion = .pulse

        settings.resetToDefaults()

        XCTAssertTrue(settings.autoCopyEnabled)
        XCTAssertTrue(settings.instantPasteEnabled)
        XCTAssertEqual(settings.previewDuration, 5.0)
        XCTAssertEqual(settings.detectionMode, .screenshotsOnly)
        XCTAssertEqual(settings.clipNotchColorway, .prism)
        XCTAssertEqual(settings.clipNotchFinish, .obsidian)
        XCTAssertEqual(settings.clipNotchMotion, .fluid)
    }

    func testClipNotchAppearancePersistenceAndFallback() {
        let suiteName = "com.clipshot.tests.\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!

        // 1. Initial defaults
        let settings = AppSettings(defaults: testDefaults)
        XCTAssertEqual(settings.clipNotchColorway, .prism)
        XCTAssertEqual(settings.clipNotchFinish, .obsidian)
        XCTAssertEqual(settings.clipNotchMotion, .fluid)

        // 2. Modify and verify persistence across new AppSettings instance
        settings.clipNotchColorway = .aurora
        settings.clipNotchFinish = .bloom
        settings.clipNotchMotion = .calm

        let reloadedSettings = AppSettings(defaults: testDefaults)
        XCTAssertEqual(reloadedSettings.clipNotchColorway, .aurora)
        XCTAssertEqual(reloadedSettings.clipNotchFinish, .bloom)
        XCTAssertEqual(reloadedSettings.clipNotchMotion, .calm)

        // 3. Robust fallback for invalid raw values
        testDefaults.set("InvalidColorway", forKey: "clipNotchColorway")
        testDefaults.set("InvalidFinish", forKey: "clipNotchFinish")
        testDefaults.set("InvalidMotion", forKey: "clipNotchMotion")

        let fallbackSettings = AppSettings(defaults: testDefaults)
        XCTAssertEqual(fallbackSettings.clipNotchColorway, .prism)
        XCTAssertEqual(fallbackSettings.clipNotchFinish, .obsidian)
        XCTAssertEqual(fallbackSettings.clipNotchMotion, .fluid)
    }

    func testAllAppearanceOptionsPersistence() {
        let suiteName = "com.clipshot.tests.\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        let settings = AppSettings(defaults: testDefaults)

        for colorway in ClipNotchColorway.allCases {
            settings.clipNotchColorway = colorway
            XCTAssertEqual(settings.clipNotchColorway, colorway)
            XCTAssertEqual(colorway.hexColors.count, 3)
        }

        for finish in ClipNotchFinish.allCases {
            settings.clipNotchFinish = finish
            XCTAssertEqual(settings.clipNotchFinish, finish)
        }

        for motion in ClipNotchMotion.allCases {
            settings.clipNotchMotion = motion
            XCTAssertEqual(settings.clipNotchMotion, motion)
        }

        settings.clipNotchColorway = .albumAura
        XCTAssertEqual(AppSettings(defaults: testDefaults).clipNotchColorway, .albumAura)
    }
}
