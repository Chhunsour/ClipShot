import XCTest
import AppKit
@testable import ClipShotCore

final class ClipNotchStateTransitionTests: XCTestCase {

    func testPresentationKindMappingForAllStates() {
        XCTAssertEqual(ClipNotchState.idle.presentationKind, .idle)
        XCTAssertEqual(ClipNotchState.quickActions.presentationKind, .quickActions)
        XCTAssertEqual(ClipNotchState.musicPlayer.presentationKind, .musicPlayer)
        XCTAssertEqual(ClipNotchState.recording(durationSeconds: 10, isPaused: false).presentationKind, .recording)
        XCTAssertEqual(ClipNotchState.ocrResult(text: "Hello").presentationKind, .ocrResult)
        XCTAssertEqual(ClipNotchState.colorResult(hex: "#FF0000", rgb: "rgb(255, 0, 0)", hsl: "hsl(0, 100%, 50%)").presentationKind, .colorResult)
        XCTAssertEqual(ClipNotchState.error(message: "Failed").presentationKind, .error)
        XCTAssertEqual(ClipNotchState.fileDropHover.presentationKind, .fileDropHover)
        XCTAssertEqual(ClipNotchState.recentShelf(items: []).presentationKind, .recentShelf)
    }

    func testVideoActivityDetection() {
        let dummyModel = VideoCapsuleModel(
            windowID: 12345,
            appName: "Safari",
            windowTitle: "Meeting"
        )

        let videoState = ClipNotchState.video(model: dummyModel)
        XCTAssertTrue(videoState.isVideoActive)
        XCTAssertEqual(videoState.activeVideoModel?.windowID, 12345)

        XCTAssertFalse(ClipNotchState.idle.isVideoActive)
        XCTAssertNil(ClipNotchState.idle.activeVideoModel)
        XCTAssertFalse(ClipNotchState.recording(durationSeconds: 5, isPaused: false).isVideoActive)
    }

    func testRecordingStateTransitions() {
        var state: ClipNotchState = .idle
        XCTAssertEqual(state, .idle)

        // Start recording
        state = .recording(durationSeconds: 0, isPaused: false)
        XCTAssertEqual(state, .recording(durationSeconds: 0, isPaused: false))
        XCTAssertEqual(state.presentationKind, .recording)

        // Pause recording
        state = .recording(durationSeconds: 12, isPaused: true)
        XCTAssertEqual(state, .recording(durationSeconds: 12, isPaused: true))

        // Resume and advance
        state = .recording(durationSeconds: 13, isPaused: false)
        XCTAssertEqual(state, .recording(durationSeconds: 13, isPaused: false))

        // Stop recording
        state = .idle
        XCTAssertEqual(state, .idle)
    }

    func testColorResultPayloadIntegrity() {
        let state = ClipNotchState.colorResult(hex: "#007AFF", rgb: "rgb(0, 122, 255)", hsl: "hsl(211°, 100%, 50%)")
        if case .colorResult(let hex, let rgb, let hsl) = state {
            XCTAssertEqual(hex, "#007AFF")
            XCTAssertEqual(rgb, "rgb(0, 122, 255)")
            XCTAssertEqual(hsl, "hsl(211°, 100%, 50%)")
        } else {
            XCTFail("State should match .colorResult")
        }
    }
}
