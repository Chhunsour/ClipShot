import XCTest
@testable import ClipShotCore

final class SystemNowPlayingServiceTests: XCTestCase {
    func testSystemMediaSnapshotDecoding() throws {
        let data = #"{"title":"Video","artist":"Creator","artworkBase64":"AQID","isPlaying":true}"#.data(using: .utf8)!
        let snapshot = try JSONDecoder().decode(SystemMediaSnapshot.self, from: data)
        XCTAssertEqual(snapshot.title, "Video")
        XCTAssertEqual(snapshot.artist, "Creator")
        XCTAssertEqual(snapshot.artworkBase64, "AQID")
        XCTAssertTrue(snapshot.isPlaying)
        XCTAssertNil(snapshot.sourcePID)
        XCTAssertNil(snapshot.currentPlaybackDate)
    }

    func testElapsedTimeAdvancesFromReportedPositionAndClampsToDuration() {
        let now = Date(timeIntervalSince1970: 1_000)
        XCTAssertEqual(
            SystemNowPlayingService.resolvedElapsed(
                rawElapsed: 42,
                playbackDate: Date(timeIntervalSince1970: 900),
                now: now,
                isPlaying: true,
                duration: 180
            ),
            142
        )
        XCTAssertEqual(
            SystemNowPlayingService.resolvedElapsed(
                rawElapsed: 250,
                playbackDate: nil,
                now: now,
                isPlaying: true,
                duration: 180
            ),
            180
        )
    }

    func testElapsedTimeFallsBackToPlaybackDateForBrowserMedia() {
        let now = Date(timeIntervalSince1970: 1_000)
        XCTAssertEqual(
            SystemNowPlayingService.resolvedElapsed(
                rawElapsed: 0,
                playbackDate: Date(timeIntervalSince1970: 982),
                now: now,
                isPlaying: true,
                duration: 180
            ),
            18
        )
        XCTAssertEqual(
            SystemNowPlayingService.resolvedElapsed(
                rawElapsed: 0,
                playbackDate: Date(timeIntervalSince1970: 1_010),
                now: now,
                isPlaying: true,
                duration: 180
            ),
            0
        )
        XCTAssertEqual(
            SystemNowPlayingService.resolvedElapsed(
                rawElapsed: 0,
                playbackDate: Date(timeIntervalSince1970: 982),
                now: now,
                isPlaying: false,
                duration: 180
            ),
            0
        )
    }
}
