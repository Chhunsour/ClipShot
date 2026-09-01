import XCTest
import AppKit
@testable import ClipShotCore

@MainActor
final class ClipNotchStateMachineTests: XCTestCase {

    func testInitialStateIsIdle() {
        let vm = ClipNotchViewModel()
        XCTAssertEqual(vm.currentState, .idle)
    }

    func testShowQuickActions() {
        let vm = ClipNotchViewModel()
        vm.showQuickActions()
        XCTAssertEqual(vm.currentState, .quickActions)
    }

    func testScreenshotInterruptsVideoAndRestores() {
        let vm = ClipNotchViewModel()
        let videoModel = VideoCapsuleModel(
            windowID: 100,
            appName: "Safari",
            windowTitle: "YouTube Video"
        )

        vm.showVideo(model: videoModel)
        XCTAssertEqual(vm.currentState, .video(model: videoModel))

        let item = ScreenshotItem(
            fileURL: URL(fileURLWithPath: "/tmp/test.png"),
            fileName: "test.png"
        )
        let sampleImage = NSImage(size: NSSize(width: 100, height: 100))

        vm.showScreenshot(item: item, image: sampleImage)

        // Should transition to videoInterruptedByScreenshot
        if case .videoInterruptedByScreenshot(let v, let s, _) = vm.currentState {
            XCTAssertEqual(v.appName, "Safari")
            XCTAssertEqual(s.fileName, "test.png")
        } else {
            XCTFail("Expected .videoInterruptedByScreenshot state")
        }
    }

    func testOCRAndColorStates() {
        let vm = ClipNotchViewModel()
        vm.showOCRResult(text: "Extracted Sample Text")
        XCTAssertEqual(vm.currentState, .ocrResult(text: "Extracted Sample Text"))

        let redColor = NSColor.red
        vm.showColorResult(color: redColor, hex: "#FF0000")
        if case .colorResult(let hex, _, _) = vm.currentState {
            XCTAssertEqual(hex, "#FF0000")
        } else {
            XCTFail("Expected .colorResult state")
        }
    }

    func testRapidScreenshotsKeepVideoAndNewestPreview() {
        let vm = ClipNotchViewModel()
        let video = VideoCapsuleModel(windowID: 7, appName: "Preview", windowTitle: "Video")
        let image = NSImage(size: NSSize(width: 100, height: 100))
        vm.showVideo(model: video)

        vm.showScreenshot(
            item: ScreenshotItem(fileURL: URL(fileURLWithPath: "/tmp/first.png"), fileName: "first.png"),
            image: image
        )
        vm.showScreenshot(
            item: ScreenshotItem(fileURL: URL(fileURLWithPath: "/tmp/latest.png"), fileName: "latest.png"),
            image: image
        )

        guard case .videoInterruptedByScreenshot(let activeVideo, let item, _) = vm.currentState else {
            return XCTFail("Expected interrupted video preview")
        }
        XCTAssertEqual(activeVideo, video)
        XCTAssertEqual(item.fileName, "latest.png")
    }

    func testVideoUpdatesDoNotDismissScreenshotPreview() {
        let vm = ClipNotchViewModel()
        let original = VideoCapsuleModel(windowID: 7, appName: "Preview", windowTitle: "Video")
        var updated = original
        updated.scalingMode = .fill
        let item = ScreenshotItem(fileURL: URL(fileURLWithPath: "/tmp/test.png"), fileName: "test.png")

        vm.showVideo(model: original)
        vm.showScreenshot(item: item, image: NSImage(size: NSSize(width: 100, height: 100)))
        vm.updateVideo(model: updated)

        guard case .videoInterruptedByScreenshot(let activeVideo, let visibleItem, _) = vm.currentState else {
            return XCTFail("Expected interrupted video preview")
        }
        XCTAssertEqual(activeVideo.scalingMode, .fill)
        XCTAssertEqual(visibleItem, item)
    }

    func testIdleNotchSizesAreTwelvePercentLarger() {
        XCTAssertEqual(ClipNotchSize.compact.idleDimensions.width, 184 * 1.12, accuracy: 0.001)
        XCTAssertEqual(ClipNotchSize.compact.idleDimensions.height, 34 * 1.12, accuracy: 0.001)
        XCTAssertEqual(ClipNotchSize.normal.idleDimensions.width, 224 * 1.12, accuracy: 0.001)
        XCTAssertEqual(ClipNotchSize.normal.idleDimensions.height, 36 * 1.12, accuracy: 0.001)
        XCTAssertEqual(ClipNotchSize.large.idleDimensions.width, 260 * 1.12, accuracy: 0.001)
        XCTAssertEqual(ClipNotchSize.large.idleDimensions.height, 38 * 1.12, accuracy: 0.001)
        XCTAssertEqual(ClipNotchSize.extraLarge.idleDimensions.width, 310 * 1.12, accuracy: 0.001)
        XCTAssertEqual(ClipNotchSize.extraLarge.idleDimensions.height, 41 * 1.12, accuracy: 0.001)
        XCTAssertEqual(ClipNotchSize.ultraWide.idleDimensions.width, 390 * 1.12, accuracy: 0.001)
        XCTAssertEqual(ClipNotchSize.ultraWide.idleDimensions.height, 43 * 1.12, accuracy: 0.001)
        XCTAssertEqual(ClipNotchSize.studio.idleDimensions.width, 480 * 1.12, accuracy: 0.001)
        XCTAssertEqual(ClipNotchSize.studio.idleDimensions.height, 45 * 1.12, accuracy: 0.001)
    }

    func testPresentationKindStabilityAcrossUpdates() {
        let recording1 = ClipNotchState.recording(durationSeconds: 1, isPaused: false)
        let recording2 = ClipNotchState.recording(durationSeconds: 15, isPaused: true)
        XCTAssertEqual(recording1.presentationKind, .recording)
        XCTAssertEqual(recording1.presentationKind, recording2.presentationKind)

        let video1 = ClipNotchState.video(model: VideoCapsuleModel(windowID: 1, appName: "App", windowTitle: "Title1"))
        let video2 = ClipNotchState.video(model: VideoCapsuleModel(windowID: 1, appName: "App", windowTitle: "Title2"))
        XCTAssertEqual(video1.presentationKind, .video)
        XCTAssertEqual(video1.presentationKind, video2.presentationKind)

        let img = NSImage(size: NSSize(width: 10, height: 10))
        let item1 = ScreenshotItem(fileURL: URL(fileURLWithPath: "/tmp/1.png"), fileName: "1.png")
        let item2 = ScreenshotItem(fileURL: URL(fileURLWithPath: "/tmp/2.png"), fileName: "2.png")
        let screenshotPreview = ClipNotchState.screenshotPreview(item: item1, image: img)
        let videoInterrupted = ClipNotchState.videoInterruptedByScreenshot(
            video: VideoCapsuleModel(windowID: 1, appName: "App", windowTitle: "Title"),
            screenshot: item2,
            image: img
        )
        XCTAssertEqual(screenshotPreview.presentationKind, .screenshotPreview)
        XCTAssertEqual(videoInterrupted.presentationKind, .screenshotPreview)

        XCTAssertEqual(ClipNotchState.idle.presentationKind, .idle)
        XCTAssertEqual(ClipNotchState.quickActions.presentationKind, .quickActions)
        XCTAssertEqual(ClipNotchState.ocrResult(text: "abc").presentationKind, .ocrResult)
        XCTAssertEqual(ClipNotchState.colorResult(hex: "#000", rgb: "", hsl: "").presentationKind, .colorResult)
        XCTAssertEqual(ClipNotchState.error(message: "err").presentationKind, .error)
        XCTAssertEqual(ClipNotchState.fileDropHover.presentationKind, .fileDropHover)
        XCTAssertEqual(ClipNotchState.recentShelf(items: []).presentationKind, .recentShelf)
    }
}
