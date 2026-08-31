import Foundation
import CoreServices
import AppKit

/// Event-driven filesystem monitor using Apple's FSEvents framework.
/// Delivers zero-polling, negligible-CPU detection of screenshot directory events.
public final class ScreenshotMonitor: @unchecked Sendable {
    public static let shared = ScreenshotMonitor()

    private var streamRef: FSEventStreamRef?
    private let queue = DispatchQueue(label: "com.clipshot.fsevents", qos: .userInitiated)
    private var isMonitoring: Bool = false
    private var currentMonitoredPath: String?

    public init() {
        setupWakeNotification()
    }

    deinit {
        stop()
    }

    // MARK: - Lifecycle

    /// Starts or restarts monitoring on the active screenshot directory.
    public func start() {
        let folderURL = PathUtils.shared.activeScreenshotFolder()
        let path = folderURL.path

        guard FileManager.default.fileExists(atPath: path) else {
            AppLogger.shared.error("Screenshot folder does not exist: \(path)")
            return
        }

        if isMonitoring && currentMonitoredPath == path {
            return
        }

        stop()

        currentMonitoredPath = path
        startFSEventStream(for: path)
        isMonitoring = true
        AppLogger.shared.info("Started FSEvents monitoring on: \(path)")
    }

    /// Stops monitoring the filesystem.
    public func stop() {
        guard let stream = streamRef else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        streamRef = nil
        isMonitoring = false
        AppLogger.shared.info("Stopped FSEvents monitoring")
    }

    /// Restarts monitoring (e.g. when directory setting changes).
    public func restart() {
        stop()
        start()
    }

    // MARK: - Private FSEvents Setup

    private func startFSEventStream(for path: String) {
        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let pathsToWatch = [path] as CFArray
        let flags = UInt32(
            kFSEventStreamCreateFlagUseCFTypes |
            kFSEventStreamCreateFlagFileEvents |
            kFSEventStreamCreateFlagNoDefer
        )

        let callback: FSEventStreamCallback = { (streamRef, clientCallBackInfo, numEvents, eventPaths, eventFlags, eventIds) in
            guard let clientInfo = clientCallBackInfo else { return }
            let monitor = Unmanaged<ScreenshotMonitor>.fromOpaque(clientInfo).takeUnretainedValue()
            monitor.handleEvents(paths: eventPaths, flags: eventFlags, count: numEvents)
        }

        guard let stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            callback,
            &context,
            pathsToWatch,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.0, // 0.0s latency for instant delivery
            flags
        ) else {
            AppLogger.shared.error("Failed to create FSEventStream for path: \(path)")
            return
        }

        self.streamRef = stream
        FSEventStreamSetDispatchQueue(stream, queue)
        FSEventStreamStart(stream)
    }

    private func handleEvents(paths: UnsafeMutableRawPointer, flags: UnsafePointer<FSEventStreamEventFlags>, count: Int) {
        guard let pathArray = unsafeBitCast(paths, to: NSArray.self) as? [String] else { return }

        for i in 0..<count {
            guard i < pathArray.count else { break }
            let filePath = pathArray[i]
            let eventFlag = flags[i]

            // Check for created, renamed, or modified file events
            let isCreated = (eventFlag & UInt32(kFSEventStreamEventFlagItemCreated)) != 0
            let isRenamed = (eventFlag & UInt32(kFSEventStreamEventFlagItemRenamed)) != 0
            let isModified = (eventFlag & UInt32(kFSEventStreamEventFlagItemModified)) != 0

            if isCreated || isRenamed || isModified {
                let url = URL(fileURLWithPath: filePath)

                // Dispatch candidate to processor actor
                Task {
                    await ScreenshotProcessor.shared.processCandidate(url: url)
                }
            }
        }
    }

    private func setupWakeNotification() {
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            AppLogger.shared.info("System did wake from sleep; refreshing FSEvents monitor")
            self?.restart()
        }
    }
}
