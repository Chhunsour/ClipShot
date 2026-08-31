import AppKit
import SwiftUI
import ClipShotCore

@main
struct ClipShotMain {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
