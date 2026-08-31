import Foundation
import AppKit
import CoreGraphics

/// Service providing optional built-in capture triggers (Area, Full Screen, Window).
/// Delegates capture tasks to native macOS capture subsystem.
public final class ScreenCaptureService: @unchecked Sendable {
    public static let shared = ScreenCaptureService()

    public init() {}

    /// Triggers an interactive crosshair capture for an area of the screen.
    public func captureArea() {
        let destinationFolder = PathUtils.shared.activeScreenshotFolder()
        let filename = generateScreenshotFilename()
        let fileURL = destinationFolder.appendingPathComponent(filename)

        runScreencaptureCommand(arguments: ["-i", fileURL.path])
    }

    /// Captures the entire main screen.
    public func captureFullScreen() {
        let destinationFolder = PathUtils.shared.activeScreenshotFolder()
        let filename = generateScreenshotFilename()
        let fileURL = destinationFolder.appendingPathComponent(filename)

        runScreencaptureCommand(arguments: ["-m", fileURL.path])
    }

    /// Triggers an interactive window capture.
    public func captureWindow() {
        let destinationFolder = PathUtils.shared.activeScreenshotFolder()
        let filename = generateScreenshotFilename()
        let fileURL = destinationFolder.appendingPathComponent(filename)

        runScreencaptureCommand(arguments: ["-w", fileURL.path])
    }

    // MARK: - Helpers

    private func generateScreenshotFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        let timestamp = formatter.string(from: Date())
        return "Screen Shot \(timestamp).png"
    }

    private func runScreencaptureCommand(arguments: [String]) {
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
            process.arguments = arguments

            do {
                try process.run()
                process.waitUntilExit()
                AppLogger.shared.info("Completed screencapture execution with code: \(process.terminationStatus)")
            } catch {
                AppLogger.shared.error("Failed to run screencapture: \(error.localizedDescription)")
            }
        }
    }
}
