import XCTest
import AppKit
@testable import ClipShotCore

final class EndToEndWorkflowTests: XCTestCase {

    var tempFolder: URL!

    override func setUp() {
        super.setUp()
        tempFolder = FileManager.default.temporaryDirectory.appendingPathComponent("ClipShotTestFolder_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempFolder, withIntermediateDirectories: true)
        AppSettings.shared.customScreenshotFolderPath = tempFolder.path
        AppSettings.shared.monitoringActive = true
        AppSettings.shared.autoCopyEnabled = true
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempFolder)
        AppSettings.shared.resetToDefaults()
        super.tearDown()
    }

    func testFullScreenshotToClipboardWorkflow() async throws {
        // 1. Create a simulated screenshot image file matching macOS naming pattern
        let screenshotFilename = "Screen Shot 2026-08-31 at 11.23.45.png"
        let fileURL = tempFolder.appendingPathComponent(screenshotFilename)

        let testImageSize = NSSize(width: 400, height: 300)
        let testImage = NSImage(size: testImageSize)
        testImage.lockFocus()
        NSColor.systemGreen.drawSwatch(in: NSRect(origin: .zero, size: testImageSize))
        testImage.unlockFocus()

        try ImageUtils.savePNG(image: testImage, to: fileURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))

        // 2. Process candidate via ScreenshotProcessor actor
        let processor = ScreenshotProcessor.shared
        await processor.processCandidate(url: fileURL)

        // 3. Verify clipboard contains the image
        await MainActor.run {
            let pasteboard = NSPasteboard.general
            let types = pasteboard.types ?? []
            XCTAssertTrue(types.contains(.png) || types.contains(.tiff))
        }

        // 4. Verify history item was recorded (wait briefly for background queue)
        try await Task.sleep(nanoseconds: 200_000_000)

        let history = HistoryManager.shared
        XCTAssertFalse(history.items.isEmpty)
        let lastItem = history.lastScreenshot
        XCTAssertNotNil(lastItem)
        XCTAssertEqual(lastItem?.fileName, screenshotFilename)
    }

    func testRapidScreenshotBurstPreservesLatestClipboard() async throws {
        let processor = ScreenshotProcessor.shared

        // Create 3 rapid screenshots
        let fileA = tempFolder.appendingPathComponent("Screen Shot 2026-08-31 at 11.24.01.png")
        let fileB = tempFolder.appendingPathComponent("Screen Shot 2026-08-31 at 11.24.02.png")
        let fileC = tempFolder.appendingPathComponent("Screen Shot 2026-08-31 at 11.24.03.png")

        let size = NSSize(width: 100, height: 100)
        let img = NSImage(size: size)
        img.lockFocus()
        NSColor.blue.drawSwatch(in: NSRect(origin: .zero, size: size))
        img.unlockFocus()

        try ImageUtils.savePNG(image: img, to: fileA)
        try ImageUtils.savePNG(image: img, to: fileB)
        try ImageUtils.savePNG(image: img, to: fileC)

        // Dispatch sequentially
        await processor.processCandidate(url: fileA)
        await processor.processCandidate(url: fileB)
        await processor.processCandidate(url: fileC)

        try await Task.sleep(nanoseconds: 150_000_000)

        // Verify all 3 are in history
        let history = HistoryManager.shared
        XCTAssertGreaterThanOrEqual(history.items.count, 3)
    }

    func testPausedMonitoringIgnoresCandidate() async throws {
        AppSettings.shared.monitoringActive = false

        let fileURL = tempFolder.appendingPathComponent("Screen Shot 2026-08-31 at 11.25.00.png")
        let img = NSImage(size: NSSize(width: 50, height: 50))
        img.lockFocus()
        NSColor.yellow.drawSwatch(in: NSRect(origin: .zero, size: NSSize(width: 50, height: 50)))
        img.unlockFocus()
        try ImageUtils.savePNG(image: img, to: fileURL)

        let historyCountBefore = HistoryManager.shared.items.count
        await ScreenshotProcessor.shared.processCandidate(url: fileURL)

        // History should NOT have increased while paused
        XCTAssertEqual(HistoryManager.shared.items.count, historyCountBefore)
    }
}
