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

    func testDeduplicatesConsecutiveCopies() {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("clipshot-tests-dedup-\(UUID())"))
        let manager = ClipboardHistoryManager(pasteboard: pasteboard)

        pasteboard.clearContents()
        pasteboard.setString("Duplicate text", forType: .string)
        manager.checkForChanges()
        XCTAssertEqual(manager.items.count, 1)

        // Same content again
        pasteboard.clearContents()
        pasteboard.setString("Duplicate text", forType: .string)
        manager.checkForChanges()
        XCTAssertEqual(manager.items.count, 1)
    }

    func testClearHistory() {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("clipshot-tests-clear-\(UUID())"))
        let manager = ClipboardHistoryManager(pasteboard: pasteboard)

        pasteboard.clearContents()
        pasteboard.setString("Sample item", forType: .string)
        manager.checkForChanges()
        XCTAssertEqual(manager.items.count, 1)

        manager.clearHistory()
        XCTAssertTrue(manager.items.isEmpty)
    }
}
