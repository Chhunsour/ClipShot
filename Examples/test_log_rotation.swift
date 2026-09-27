#!/usr/bin/env swift
import Foundation

print("--- ClipShot: Log Rotation Simulation ---")

let tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("ClipShotLogRotationDemo_\(UUID().uuidString)")
let fm = FileManager.default
try? fm.createDirectory(at: tempDir, withIntermediateDirectories: true)
defer { try? fm.removeItem(at: tempDir) }

let maxLogFiles = 3
let maxFileSize: Int64 = 256 // 256 bytes for test rotation

func writeLog(message: String) {
    let logFile = tempDir.appendingPathComponent("clipshot.log")
    let line = "[\(ISO8601DateFormatter().string(from: Date()))] \(message)\n"
    guard let data = line.data(using: .utf8) else { return }

    if !fm.fileExists(atPath: logFile.path) {
        fm.createFile(atPath: logFile.path, contents: nil)
    }

    if let attrs = try? fm.attributesOfItem(atPath: logFile.path),
       let size = attrs[.size] as? Int64,
       size + Int64(data.count) > maxFileSize {
        // Rotate
        for i in stride(from: maxLogFiles - 1, through: 1, by: -1) {
            let src = tempDir.appendingPathComponent("clipshot.\(i).log")
            let dst = tempDir.appendingPathComponent("clipshot.\(i + 1).log")
            try? fm.removeItem(at: dst)
            try? fm.moveItem(at: src, to: dst)
        }
        let firstBackup = tempDir.appendingPathComponent("clipshot.1.log")
        try? fm.removeItem(at: firstBackup)
        try? fm.moveItem(at: logFile, to: firstBackup)
        fm.createFile(atPath: logFile.path, contents: nil)
        print("  * Rotated logs due to size limit (\(size) bytes) *")
    }

    if let handle = try? FileHandle(forWritingTo: logFile) {
        handle.seekToEndOfFile()
        handle.write(data)
        try? handle.close()
    }
}

// Generate multiple log entries to trigger rotations
print("Writing log entries...")
for i in 1...20 {
    writeLog(message: "Event log entry #\(i): Screen capture processed and saved to clipboard.")
}

let existingFiles = (try? fm.contentsOfDirectory(atPath: tempDir.path)) ?? []
print("\nFinal log directory contents (\(existingFiles.count) files):")
for file in existingFiles.sorted() {
    let path = tempDir.appendingPathComponent(file).path
    let size = (try? fm.attributesOfItem(atPath: path)[.size] as? Int64) ?? 0
    print("  - \(file): \(size) bytes")
}
