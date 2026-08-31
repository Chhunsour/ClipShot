import AppKit
import XCTest
@testable import ClipShotCore

@MainActor
final class ClipboardHistoryManagerTests: XCTestCase {
    func testCapturesRecopiesAndProtectsSensitiveText() {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("clipshot-tests-\(UUID())"))
        let manager = ClipboardHistoryManager(pasteboard: pasteboard)

        pasteboard.clearContents()
        pasteboard.setString("A useful copied note", forType: .string)
        manager.checkForChanges()

        XCTAssertEqual(manager.items.first?.text, "A useful copied note")
        XCTAssertTrue(manager.copy(manager.items[0]))
        XCTAssertEqual(pasteboard.string(forType: .string), "A useful copied note")

        let concealed = NSPasteboardItem()
        concealed.setString("secret", forType: .string)
        concealed.setString("1", forType: NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType"))
        pasteboard.clearContents()
        pasteboard.writeObjects([concealed])
        manager.checkForChanges()

        XCTAssertEqual(manager.items.count, 1)
    }
}
