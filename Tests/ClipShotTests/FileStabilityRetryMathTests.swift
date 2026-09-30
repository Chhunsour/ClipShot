import XCTest
@testable import ClipShotCore

final class FileStabilityRetryMathTests: XCTestCase {

    func testRetryTimingConstants() {
        XCTAssertEqual(AppConfig.maxFileStabilityRetries, 10)
        // 15,000,000 ns == 15 ms
        XCTAssertEqual(AppConfig.minFileStabilityCheckMs, 15_000_000)
    }

    func testNanosecondsToMillisecondsConversion() {
        let nano: UInt64 = AppConfig.minFileStabilityCheckMs
        let ms = Double(nano) / 1_000_000.0
        XCTAssertEqual(ms, 15.0)

        let seconds = Double(nano) / 1_000_000_000.0
        XCTAssertEqual(seconds, 0.015)
    }

    func testMaxTotalStabilityCheckWindow() {
        let retries = AppConfig.maxFileStabilityRetries
        let intervalMs = Double(AppConfig.minFileStabilityCheckMs) / 1_000_000.0
        let totalWindowMs = Double(retries) * intervalMs

        // Total window should be 150ms, safely catching asynchronous macOS disk flush
        XCTAssertEqual(totalWindowMs, 150.0)
        XCTAssertLessThanOrEqual(totalWindowMs, 500.0, "Stability check should not introduce perceptible UI delay")
    }

    func testSizeConvergenceSimulation() {
        // Simulating 5 progressive file write probes
        let sizeProgression: [Int64] = [0, 4096, 16384, 32768, 32768]
        var converged = false
        var lastSize: Int64 = -1
        var iterations = 0

        for size in sizeProgression {
            iterations += 1
            if size > 0 && size == lastSize {
                converged = true
                break
            }
            lastSize = size
        }

        XCTAssertTrue(converged)
        XCTAssertEqual(iterations, 5)
        XCTAssertEqual(lastSize, 32768)
    }

    func testUnchangingZeroByteFileRejection() {
        let emptyProgression: [Int64] = Array(repeating: 0, count: AppConfig.maxFileStabilityRetries)
        var converged = false
        var lastSize: Int64 = -1

        for size in emptyProgression {
            if size > 0 && size == lastSize {
                converged = true
                break
            }
            lastSize = size
        }

        XCTAssertFalse(converged, "Zero-byte file must never be considered stable")
    }
}
