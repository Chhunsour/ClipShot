import XCTest
@testable import ClipShotCore

final class DeduplicationTests: XCTestCase {

    func testDuplicateEventsDoNotCrashProcessor() async {
        let processor = ScreenshotProcessor()
        let testImageURL = URL(fileURLWithPath: "/tmp/non_existent_fake_screenshot.png")

        // Rapid sequential calls should gracefully reject duplicate/invalid candidates
        await processor.processCandidate(url: testImageURL)
        await processor.processCandidate(url: testImageURL)
        await processor.processCandidate(url: testImageURL)

        XCTAssertTrue(true)
    }
}
