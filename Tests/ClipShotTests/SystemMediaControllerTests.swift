import XCTest
@testable import ClipShotCore

final class SystemMediaControllerTests: XCTestCase {
    func testMediaKeyEventEncoding() {
        XCTAssertEqual(
            SystemMediaController.eventData(for: .playPause, keyDown: true),
            (16 << 16) | (0xA << 8)
        )
        XCTAssertEqual(
            SystemMediaController.eventData(for: .next, keyDown: false),
            (17 << 16) | (0xB << 8)
        )
        XCTAssertEqual(SystemMediaController.mediaRemoteValue(for: .playPause), 2)
        XCTAssertEqual(SystemMediaController.mediaRemoteValue(for: .next), 4)
        XCTAssertEqual(SystemMediaController.mediaRemoteValue(for: .previous), 5)
    }

    func testRelativeSeekClampsToTrackBounds() {
        XCTAssertEqual(SystemMediaController.clampedSeekTarget(seconds: -15, relativeTo: 8, duration: 180), 0)
        XCTAssertEqual(SystemMediaController.clampedSeekTarget(seconds: 15, relativeTo: 175, duration: 180), 180)
        XCTAssertEqual(SystemMediaController.clampedSeekTarget(seconds: 15, relativeTo: 20, duration: 0), 35)
    }

    func testScriptableOptionsRouteOnlyToActualNowPlayingSource() {
        XCTAssertEqual(SystemMediaController.scriptablePlayer(for: "com.apple.Music"), .music)
        XCTAssertEqual(SystemMediaController.scriptablePlayer(for: "com.spotify.client"), .spotify)
        XCTAssertNil(SystemMediaController.scriptablePlayer(for: "com.google.Chrome"))
        XCTAssertNil(SystemMediaController.scriptablePlayer(for: nil))
    }
}
