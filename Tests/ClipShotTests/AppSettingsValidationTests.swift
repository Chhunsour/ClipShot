import XCTest
import CoreGraphics
@testable import ClipShotCore

final class AppSettingsValidationTests: XCTestCase {

    func testRecentColorsDeduplicationAndCapping() {
        let testDefaults = UserDefaults(suiteName: "com.clipshot.tests.\(UUID().uuidString)")!
        let settings = AppSettings(defaults: testDefaults)

        // Add 25 distinct colors
        for i in 0..<25 {
            let hex = String(format: "#%06X", i * 1000)
            settings.addRecentColor(hex)
        }

        XCTAssertEqual(settings.recentColors.count, 20)

        // Add case-insensitive duplicate of the first color
        let topColor = settings.recentColors.first!
        settings.addRecentColor(topColor.lowercased())
        XCTAssertEqual(settings.recentColors.count, 20)
        XCTAssertEqual(settings.recentColors.first, topColor.lowercased())
    }

    func testLastSelectedAreaPersistence() {
        let suiteName = "com.clipshot.tests.\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        let settings = AppSettings(defaults: testDefaults)

        let testRect = CGRect(x: 120, y: 240, width: 800, height: 600)
        settings.lastSelectedArea = testRect
        XCTAssertEqual(settings.lastSelectedArea, testRect)

        let reloaded = AppSettings(defaults: testDefaults)
        XCTAssertNotNil(reloaded.lastSelectedArea)
        XCTAssertEqual(reloaded.lastSelectedArea?.origin.x, 120)
        XCTAssertEqual(reloaded.lastSelectedArea?.origin.y, 240)
        XCTAssertEqual(reloaded.lastSelectedArea?.size.width, 800)
        XCTAssertEqual(reloaded.lastSelectedArea?.size.height, 600)

        settings.lastSelectedArea = nil
        XCTAssertNil(settings.lastSelectedArea)
        XCTAssertNil(AppSettings(defaults: testDefaults).lastSelectedArea)
    }

    func testPreviewDurationNonPositiveFallback() {
        let testDefaults = UserDefaults(suiteName: "com.clipshot.tests.\(UUID().uuidString)")!
        testDefaults.set(0.0, forKey: "previewDuration")

        let settings = AppSettings(defaults: testDefaults)
        XCTAssertEqual(settings.previewDuration, 5.0)

        testDefaults.set(-3.5, forKey: "previewDuration")
        let settingsNegative = AppSettings(defaults: testDefaults)
        XCTAssertEqual(settingsNegative.previewDuration, 5.0)
    }
}
