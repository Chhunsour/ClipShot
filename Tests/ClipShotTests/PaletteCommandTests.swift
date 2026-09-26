import XCTest
@testable import ClipShotCore

final class PaletteCommandTests: XCTestCase {

    func testPaletteCommandPropertiesAndExecution() {
        var actionExecuted = false
        let command = PaletteCommand(
            title: "Capture Area",
            subtitle: "Select region to screenshot",
            iconName: "crop"
        ) {
            actionExecuted = true
        }

        XCTAssertEqual(command.title, "Capture Area")
        XCTAssertEqual(command.subtitle, "Select region to screenshot")
        XCTAssertEqual(command.iconName, "crop")
        XCTAssertFalse(actionExecuted)

        command.action()
        XCTAssertTrue(actionExecuted)
    }

    func testPaletteCommandUniqueIDs() {
        let cmd1 = PaletteCommand(title: "Cmd1", subtitle: "Sub1", iconName: "star") {}
        let cmd2 = PaletteCommand(title: "Cmd1", subtitle: "Sub1", iconName: "star") {}
        XCTAssertNotEqual(cmd1.id, cmd2.id)
    }
}
