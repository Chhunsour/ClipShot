import XCTest
@testable import ClipShotCore

final class ScreenshotNamingPatternTests: XCTestCase {
    private let detector = ScreenshotDetector.shared

    func testEnglishScreenshotNamingPatterns() {
        XCTAssertTrue(detector.matchesScreenshotNamingPattern(filename: "Screen Shot 2026-09-29 at 09.00.00.png"))
        XCTAssertTrue(detector.matchesScreenshotNamingPattern(filename: "Screenshot 2026-09-29 09.00.00.png"))
        XCTAssertTrue(detector.matchesScreenshotNamingPattern(filename: "Screen_Shot_2026-09-29_at_09.00.00.png"))
    }

    func testRomanceLanguagesScreenshotNamingPatterns() {
        // Spanish
        XCTAssertTrue(detector.matchesScreenshotNamingPattern(filename: "Captura de pantalla 2026-09-29 a las 09.00.00.png"))
        // French (curly and straight apostrophe)
        XCTAssertTrue(detector.matchesScreenshotNamingPattern(filename: "Capture d’écran 2026-09-29 à 09.00.00.png"))
        XCTAssertTrue(detector.matchesScreenshotNamingPattern(filename: "Capture d'écran 2026-09-29 à 09.00.00.png"))
        // Italian
        XCTAssertTrue(detector.matchesScreenshotNamingPattern(filename: "Schermata 2026-09-29 alle 09.00.00.png"))
    }

    func testGermanicAndNordicScreenshotNamingPatterns() {
        // German
        XCTAssertTrue(detector.matchesScreenshotNamingPattern(filename: "Bildschirmfoto 2026-09-29 um 09.00.00.png"))
        // Dutch
        XCTAssertTrue(detector.matchesScreenshotNamingPattern(filename: "Schermafbeelding 2026-09-29 om 09.00.00.png"))
        // Swedish & Norwegian
        XCTAssertTrue(detector.matchesScreenshotNamingPattern(filename: "Skärmavbild 2026-09-29 kl. 09.00.00.png"))
        XCTAssertTrue(detector.matchesScreenshotNamingPattern(filename: "Skjermbilde 2026-09-29 kl. 09.00.00.png"))
        // Finnish
        XCTAssertTrue(detector.matchesScreenshotNamingPattern(filename: "Näyttökuva 2026-09-29 klo 09.00.00.png"))
    }

    func testAsianScreenshotNamingPatterns() {
        // Japanese
        XCTAssertTrue(detector.matchesScreenshotNamingPattern(filename: "スクリーンショット 2026-09-29 9.00.00.png"))
        // Simplified & Traditional Chinese
        XCTAssertTrue(detector.matchesScreenshotNamingPattern(filename: "屏幕快照 2026-09-29 09.00.00.png"))
        XCTAssertTrue(detector.matchesScreenshotNamingPattern(filename: "螢幕快照 2026-09-29 09.00.00.png"))
        // Korean
        XCTAssertTrue(detector.matchesScreenshotNamingPattern(filename: "화면 캡처 2026-09-29 09.00.00.png"))
    }

    func testDeveloperAndSimulatorScreenshotNamingPatterns() {
        XCTAssertTrue(detector.matchesScreenshotNamingPattern(filename: "Simulator Screenshot - iPhone 16 Pro - 2026-09-29 at 09.00.00.png"))
        XCTAssertTrue(detector.matchesScreenshotNamingPattern(filename: "CleanShot 2026-09-29 at 09.00.00.png"))
    }

    func testUnrelatedFilenamesAreRejected() {
        XCTAssertFalse(detector.matchesScreenshotNamingPattern(filename: "vacation_photo.jpg"))
        XCTAssertFalse(detector.matchesScreenshotNamingPattern(filename: "invoice_august_2026.pdf"))
        XCTAssertFalse(detector.matchesScreenshotNamingPattern(filename: "project_archive.zip"))
        XCTAssertFalse(detector.matchesScreenshotNamingPattern(filename: "app_icon_1024.png"))
    }
}
