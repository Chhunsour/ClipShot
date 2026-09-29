import XCTest
import Foundation
@testable import ClipShotCore

final class AppConfigConstantsTests: XCTestCase {

    func testSemanticVersionFormat() {
        let components = AppConfig.appVersion.split(separator: ".")
        XCTAssertEqual(components.count, 3, "Version must follow semantic versioning (MAJOR.MINOR.PATCH)")
        for comp in components {
            XCTAssertNotNil(Int(comp), "Semantic version component must be integer: \(comp)")
        }
    }

    func testBuildNumberIsPositiveInteger() {
        guard let buildNum = Int(AppConfig.buildNumber) else {
            XCTFail("Build number should be convertible to Int")
            return
        }
        XCTAssertGreaterThan(buildNum, 0)
    }

    func testBundleIdentifierReverseDNSStructure() {
        let parts = AppConfig.bundleIdentifier.split(separator: ".")
        XCTAssertGreaterThanOrEqual(parts.count, 2, "Bundle identifier must follow reverse-DNS notation")
        XCTAssertEqual(parts.first, "com")
        XCTAssertEqual(parts.last, "ClipShot")
    }

    func testStabilityCheckNanosecondsToMillisecondsConversion() {
        // minFileStabilityCheckMs is defined in nanoseconds
        let nanoseconds = AppConfig.minFileStabilityCheckMs
        let milliseconds = nanoseconds / 1_000_000
        XCTAssertEqual(milliseconds, 15, "File stability check interval should equal 15ms")
    }

    func testMaxLogFileSizeExactByteCalculation() {
        let expectedBytes: Int64 = 2 * 1024 * 1024 // 2 Megabytes
        XCTAssertEqual(AppConfig.maxLogFileSize, expectedBytes)
    }

    func testCopyrightNoticeIncludesBrandingAndValidYear() {
        let copyright = AppConfig.copyright
        XCTAssertTrue(copyright.hasPrefix("Copyright ©"), "Copyright notice must begin with standard header")
        XCTAssertTrue(copyright.contains("ClipShot"))
        XCTAssertTrue(copyright.hasSuffix("All rights reserved."))
    }

    func testHelpURLSecurityAndHost() {
        guard let url = AppConfig.helpURL else {
            XCTFail("Help URL must not be nil")
            return
        }
        XCTAssertEqual(url.scheme, "https", "Help URL must use secure HTTPS")
        XCTAssertEqual(url.host, "github.com")
        XCTAssertEqual(url.path, "/Chhunsour/ClipShot")
    }
}
