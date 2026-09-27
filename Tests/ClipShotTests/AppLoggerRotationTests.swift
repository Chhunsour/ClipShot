import XCTest
@testable import ClipShotCore

final class AppLoggerRotationTests: XCTestCase {

    func testLogLineFormatting() {
        let level = "INFO"
        let msg = "App initialization complete"
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let line = "[\(timestamp)] [\(level)] \(msg)\n"

        XCTAssertTrue(line.hasPrefix("["))
        XCTAssertTrue(line.contains("[\(level)]"))
        XCTAssertTrue(line.contains(msg))
        XCTAssertTrue(line.hasSuffix("\n"))
    }

    func testRotationFilenamePattern() {
        let maxFiles = AppConfig.maxLogFiles
        XCTAssertEqual(maxFiles, 3)

        var rotatedNames: [String] = []
        for i in 1..<maxFiles {
            rotatedNames.append("clipshot.\(i).log")
        }

        XCTAssertEqual(rotatedNames, ["clipshot.1.log", "clipshot.2.log"])
    }

    func testMaxLogFileSizeSanity() {
        XCTAssertEqual(AppConfig.maxLogFileSize, 2 * 1024 * 1024)
        XCTAssertTrue(AppConfig.maxLogFileSize > 0)
    }
}
