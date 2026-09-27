import XCTest
@testable import ClipShotCore

final class ScreenshotNamingTests: XCTestCase {

    func testNordicScreenshotNamingPatterns() {
        let detector = ScreenshotDetector.shared

        XCTAssertTrue(detector.matchesScreenshotNamingPattern(filename: "Skärmavbild 2026-08-31 kl. 11.04.22.png"))
        XCTAssertTrue(detector.matchesScreenshotNamingPattern(filename: "Skjermbilde 2026-08-31 kl. 11.04.22.png"))
        XCTAssertTrue(detector.matchesScreenshotNamingPattern(filename: "Skærmbillede 2026-08-31 kl. 11.04.22.png"))
        XCTAssertTrue(detector.matchesScreenshotNamingPattern(filename: "Näyttökuva 2026-08-31 klo 11.04.22.png"))
    }

    func testEastAsianAndSlavicNamingPatterns() {
        let detector = ScreenshotDetector.shared

        XCTAssertTrue(detector.matchesScreenshotNamingPattern(filename: "화면 캡처 2026-08-31 11.04.22.png"))
        XCTAssertTrue(detector.matchesScreenshotNamingPattern(filename: "螢幕快照 2026-08-31 11.04.22.png"))
        XCTAssertTrue(detector.matchesScreenshotNamingPattern(filename: "Zrzut ekranu 2026-08-31 11.04.22.png"))
        XCTAssertTrue(detector.matchesScreenshotNamingPattern(filename: "Снимок экрана 2026-08-31 в 11.04.22.png"))
    }

    func testSimulatorScreenshotNamingPattern() {
        let detector = ScreenshotDetector.shared
        XCTAssertTrue(detector.matchesScreenshotNamingPattern(filename: "Simulator Screenshot - iPhone 16 Pro - 2026-08-31.png"))
    }

    func testCameraAndStockPhotoRejection() {
        let detector = ScreenshotDetector.shared

        XCTAssertFalse(detector.matchesScreenshotNamingPattern(filename: "IMG_4920.HEIC"))
        XCTAssertFalse(detector.matchesScreenshotNamingPattern(filename: "DSC_0012.JPG"))
        XCTAssertFalse(detector.matchesScreenshotNamingPattern(filename: "PANO_20260831.png"))
        XCTAssertFalse(detector.matchesScreenshotNamingPattern(filename: "scan_invoice_2026.pdf"))
    }
}
