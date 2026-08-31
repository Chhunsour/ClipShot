import XCTest
@testable import ClipShotCore

final class ScreenshotDetectorTests: XCTestCase {

    func testScreenshotNamingPatterns() {
        let detector = ScreenshotDetector.shared

        // Standard English macOS patterns
        XCTAssertTrue(detector.matchesScreenshotNamingPattern(filename: "Screen Shot 2026-08-31 at 11.04.22.png"))
        XCTAssertTrue(detector.matchesScreenshotNamingPattern(filename: "Screenshot 2026-08-31 at 14.15.00.png"))
        XCTAssertTrue(detector.matchesScreenshotNamingPattern(filename: "Screen Shot 2026-01-01 at 00.00.00.heic"))

        // Multi-language macOS patterns
        XCTAssertTrue(detector.matchesScreenshotNamingPattern(filename: "Capture d’écran 2026-08-31 à 11.04.22.png"))
        XCTAssertTrue(detector.matchesScreenshotNamingPattern(filename: "Captura de pantalla 2026-08-31 a las 11.04.22.png"))
        XCTAssertTrue(detector.matchesScreenshotNamingPattern(filename: "Bildschirmfoto 2026-08-31 um 11.04.22.png"))
        XCTAssertTrue(detector.matchesScreenshotNamingPattern(filename: "Schermata 2026-08-31 alle 11.04.22.png"))
        XCTAssertTrue(detector.matchesScreenshotNamingPattern(filename: "Schermafbeelding 2026-08-31 om 11.04.22.png"))
        XCTAssertTrue(detector.matchesScreenshotNamingPattern(filename: "スクリーンショット 2026-08-31 11.04.22.png"))
        XCTAssertTrue(detector.matchesScreenshotNamingPattern(filename: "屏幕快照 2026-08-31 11.04.22.png"))
        XCTAssertTrue(detector.matchesScreenshotNamingPattern(filename: "CleanShot 2026-08-31 at 11.04.22.png"))

        // Non-screenshot filenames
        XCTAssertFalse(detector.matchesScreenshotNamingPattern(filename: "photo_vacation.jpg"))
        XCTAssertFalse(detector.matchesScreenshotNamingPattern(filename: "document.pdf"))
        XCTAssertFalse(detector.matchesScreenshotNamingPattern(filename: "app_icon.png"))
        XCTAssertFalse(detector.matchesScreenshotNamingPattern(filename: "logo.svg"))
    }

    func testNonImageExtensionRejection() {
        let detector = ScreenshotDetector.shared
        let settings = AppSettings()

        let txtURL = URL(fileURLWithPath: "/tmp/Screenshot 2026-08-31 at 11.04.22.txt")
        XCTAssertFalse(detector.isScreenshot(url: txtURL, settings: settings))

        let pdfURL = URL(fileURLWithPath: "/tmp/Screenshot 2026-08-31 at 11.04.22.pdf")
        XCTAssertFalse(detector.isScreenshot(url: pdfURL, settings: settings))
    }
}
