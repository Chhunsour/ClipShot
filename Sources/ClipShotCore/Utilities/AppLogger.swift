import Foundation
import AppKit

/// Privacy-respecting diagnostic rotating file logger for ClipShot.
/// Never logs image contents, file contents, or recognized OCR text.
public final class AppLogger: @unchecked Sendable {
    public static let shared = AppLogger()

    private let queue = DispatchQueue(label: "com.clipshot.logger", qos: .utility)
    private let logDirectory: URL
    private let logFileURL: URL
    private var fileHandle: FileHandle?

    public init() {
        let fileManager = FileManager.default
        let libraryLogs = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first?.appendingPathComponent("Logs")
            ?? URL(fileURLWithPath: NSTemporaryDirectory())

        self.logDirectory = libraryLogs.appendingPathComponent("ClipShot")
        self.logFileURL = logDirectory.appendingPathComponent("clipshot.log")

        setupLogDirectory()
        openLogFile()
    }

    private func setupLogDirectory() {
        let fm = FileManager.default
        if !fm.fileExists(atPath: logDirectory.path) {
            try? fm.createDirectory(at: logDirectory, withIntermediateDirectories: true, attributes: nil)
        }
    }

    private func openLogFile() {
        let fm = FileManager.default
        if !fm.fileExists(atPath: logFileURL.path) {
            fm.createFile(atPath: logFileURL.path, contents: nil, attributes: nil)
        }
        fileHandle = try? FileHandle(forWritingTo: logFileURL)
        fileHandle?.seekToEndOfFile()
    }

    public func log(_ message: String, level: String = "INFO") {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let line = "[\(timestamp)] [\(level)] \(message)\n"

        #if DEBUG
        print("[\(AppConfig.appName)] \(line)", terminator: "")
        #endif

        queue.async { [weak self] in
            guard let self = self else { return }
            self.rotateIfNeeded()
            if let data = line.data(using: .utf8) {
                self.fileHandle?.write(data)
            }
        }
    }

    public func info(_ message: String) {
        log(message, level: "INFO")
    }

    public func warning(_ message: String) {
        log(message, level: "WARN")
    }

    public func error(_ message: String) {
        log(message, level: "ERROR")
    }

    public func debug(_ message: String) {
        #if DEBUG
        log(message, level: "DEBUG")
        #endif
    }

    private func rotateIfNeeded() {
        let fm = FileManager.default
        guard let attributes = try? fm.attributesOfItem(atPath: logFileURL.path),
              let size = attributes[.size] as? Int64,
              size > AppConfig.maxLogFileSize else {
            return
        }

        fileHandle?.closeFile()
        fileHandle = nil

        // Rotate: clipshot.2.log -> remove, clipshot.1.log -> clipshot.2.log, clipshot.log -> clipshot.1.log
        for i in stride(from: AppConfig.maxLogFiles - 1, through: 1, by: -1) {
            let src = logDirectory.appendingPathComponent("clipshot.\(i).log")
            let dest = logDirectory.appendingPathComponent("clipshot.\(i + 1).log")
            try? fm.removeItem(at: dest)
            try? fm.moveItem(at: src, to: dest)
        }

        let firstBackup = logDirectory.appendingPathComponent("clipshot.1.log")
        try? fm.removeItem(at: firstBackup)
        try? fm.moveItem(at: logFileURL, to: firstBackup)

        openLogFile()
    }

    /// Reveals the log directory in Finder.
    public func openLogFolder() {
        NSWorkspace.shared.selectFile(logFileURL.path, inFileViewerRootedAtPath: logDirectory.path)
    }
}
