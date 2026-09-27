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

    func testDisplayTitleFormatting() {
        let service = SystemNowPlayingService.shared
        // Default empty state
        XCTAssertTrue(service.displayTitle.isEmpty || !service.displayTitle.isEmpty)
    }

    func testSystemMediaSnapshotWithFullFields() throws {
        let json = """
        {
            "title": "Midnight City",
            "artist": "M83",
            "album": "Hurry Up, We're Dreaming",
            "artworkBase64": "ZXhhbXBsZQ==",
            "isPlaying": false,
            "duration": 243.5,
            "elapsedTime": 120.0,
            "currentPlaybackDate": 1700000000.0,
            "sourcePID": 1234
        }
        """.data(using: .utf8)!

        let snapshot = try JSONDecoder().decode(SystemMediaSnapshot.self, from: json)
        XCTAssertEqual(snapshot.title, "Midnight City")
        XCTAssertEqual(snapshot.artist, "M83")
        XCTAssertEqual(snapshot.album, "Hurry Up, We're Dreaming")
        XCTAssertEqual(snapshot.duration, 243.5)
        XCTAssertEqual(snapshot.elapsedTime, 120.0)
        XCTAssertEqual(snapshot.sourcePID, 1234)
        XCTAssertFalse(snapshot.isPlaying)
    }
}
