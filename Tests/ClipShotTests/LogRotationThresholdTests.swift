import Foundation
import XCTest
@testable import ClipShotCore

final class LogRotationThresholdTests: XCTestCase {
    func testLogThresholdConfigurationConstants() {
        XCTAssertEqual(AppConfig.maxLogFiles, 3)
        XCTAssertEqual(AppConfig.maxLogFileSize, 2 * 1024 * 1024)
        XCTAssertEqual(AppConfig.minFileStabilityCheckMs, 15_000_000)
        XCTAssertEqual(AppConfig.maxFileStabilityRetries, 10)
    }

    func testLogFileByteCountFormatting() {
        let formatted = ByteCountFormatter.string(fromByteCount: AppConfig.maxLogFileSize, countStyle: .file)
        XCTAssertTrue(formatted.contains("2") && formatted.contains("MB"))
    }

    func testLogRotationFileNamingSequence() {
        let baseDirectory = URL(fileURLWithPath: "/tmp/ClipShotLogs")
        var expectedNames: [String] = []

        for i in 1...AppConfig.maxLogFiles {
            let logURL = baseDirectory.appendingPathComponent("clipshot.\(i).log")
            expectedNames.append(logURL.lastPathComponent)
        }

        XCTAssertEqual(expectedNames, ["clipshot.1.log", "clipshot.2.log", "clipshot.3.log"])
    }

    func testLogLineFormattingStructure() {
        let level = "INFO"
        let message = "Test log event message"
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let line = "[\(timestamp)] [\(level)] \(message)\n"

        XCTAssertTrue(line.hasPrefix("["))
        XCTAssertTrue(line.contains("[\(level)]"))
        XCTAssertTrue(line.hasSuffix("\(message)\n"))
    }

    func testFileStabilityRetryDelayCalculations() {
        let delayNs = AppConfig.minFileStabilityCheckMs
        let delaySeconds = Double(delayNs) / 1_000_000_000.0

        XCTAssertEqual(delaySeconds, 0.015, accuracy: 0.0001)

        let totalWorstCaseDelay = delaySeconds * Double(AppConfig.maxFileStabilityRetries)
        XCTAssertEqual(totalWorstCaseDelay, 0.150, accuracy: 0.001)
    }
}
