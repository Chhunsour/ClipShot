import XCTest
@testable import ClipShotCore

final class AppLoggerTests: XCTestCase {

    func testAppLoggerSingleton() {
        let logger = AppLogger.shared
        XCTAssertNotNil(logger)
    }

    func testLogMethodsExecuteSafely() {
        let logger = AppLogger.shared

        logger.info("Unit test info message")
        logger.warning("Unit test warning message")
        logger.error("Unit test error message")
        logger.debug("Unit test debug message")

        // Allow background queue to flush safely
        let expectation = expectation(description: "Logger write queue")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
}
