import XCTest
import AppKit
@testable import ClipShotCore

@MainActor
final class PinnedImageWindowControllerTests: XCTestCase {

    func testPinnedWindowInitialization() {
        let size = NSSize(width: 800, height: 600)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.blue.drawSwatch(in: NSRect(origin: .zero, size: size))
        image.unlockFocus()

        let initialCount = PinnedImageWindowController.pinnedWindows.count
        PinnedImageWindowController.pin(image: image, title: "Test Pin")

        XCTAssertEqual(PinnedImageWindowController.pinnedWindows.count, initialCount + 1)

        guard let controller = PinnedImageWindowController.pinnedWindows.last else {
            XCTFail("Expected pinned window controller to be registered")
            return
        }

        guard let panel = controller.window as? NSPanel else {
            XCTFail("Expected window to be an NSPanel")
            return
        }

        XCTAssertEqual(panel.level, .floating)
        XCTAssertTrue(panel.isMovableByWindowBackground)
        XCTAssertEqual(panel.aspectRatio.width, 800)
        XCTAssertEqual(panel.aspectRatio.height, 600)

        // Clean up
        controller.closeWindow()
        XCTAssertEqual(PinnedImageWindowController.pinnedWindows.count, initialCount)
    }

    func testPinnedWindowLifecycleMultipleWindows() {
        let size1 = NSSize(width: 200, height: 150)
        let img1 = NSImage(size: size1)
        let size2 = NSSize(width: 400, height: 300)
        let img2 = NSImage(size: size2)

        let initialCount = PinnedImageWindowController.pinnedWindows.count
        PinnedImageWindowController.pin(image: img1, title: "Pin 1")
        PinnedImageWindowController.pin(image: img2, title: "Pin 2")

        XCTAssertEqual(PinnedImageWindowController.pinnedWindows.count, initialCount + 2)

        let win1 = PinnedImageWindowController.pinnedWindows[initialCount]
        let win2 = PinnedImageWindowController.pinnedWindows[initialCount + 1]

        XCTAssertEqual(win1.window?.aspectRatio.width, 200)
        XCTAssertEqual(win2.window?.aspectRatio.width, 400)

        win1.closeWindow()
        XCTAssertEqual(PinnedImageWindowController.pinnedWindows.count, initialCount + 1)

        win2.closeWindow()
        XCTAssertEqual(PinnedImageWindowController.pinnedWindows.count, initialCount)
    }
}
