import XCTest
import Foundation
@testable import ClipShotCore

final class AppConfigTests: XCTestCase {

    func testBrandingAndIdentityConstants() {
        XCTAssertEqual(AppConfig.appName, "ClipShot")
        XCTAssertEqual(AppConfig.bundleIdentifier, "com.clipshot.ClipShot")
        XCTAssertFalse(AppConfig.appVersion.isEmpty)
        XCTAssertFalse(AppConfig.buildNumber.isEmpty)
        XCTAssertTrue(AppConfig.copyright.contains("ClipShot"))
    }

    func testHelpURLIsValid() {
        XCTAssertNotNil(AppConfig.helpURL)
        XCTAssertEqual(AppConfig.helpURL?.scheme, "https")
        XCTAssertEqual(AppConfig.helpURL?.host, "github.com")
        XCTAssertTrue(AppConfig.helpURL?.absoluteString.contains("Chhunsour/ClipShot") == true)
    }

    func testLoggingLimitsAndDefaults() {
        XCTAssertGreaterThan(AppConfig.maxLogFiles, 0)
        XCTAssertGreaterThan(AppConfig.maxLogFileSize, 1024 * 1024) // At least 1 MB
        XCTAssertGreaterThan(AppConfig.defaultPreviewDuration, 0)
        XCTAssertGreaterThan(AppConfig.defaultHistoryLimit, 0)
        XCTAssertGreaterThan(AppConfig.defaultRetentionDays, 0)
        XCTAssertGreaterThan(AppConfig.maxFileStabilityRetries, 0)
    }
}
