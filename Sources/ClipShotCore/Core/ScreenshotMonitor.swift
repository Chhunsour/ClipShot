import Foundation
import CoreServices
import AppKit

/// Event-driven filesystem monitor using Apple's FSEvents framework.
///
/// Delivers zero-polling, negligible-CPU detection of screenshot directory events.
/// Unlike legacy polling timers that repeatedly query directory listings, `ScreenshotMonitor`
/// registers directly with the macOS kernel via `FSEventStreamCreate` to receive immediate
/// asynchronous notifications whenever new files are written to the monitored directory.
public final class ScreenshotMonitor: @unchecked Sendable {
    /// Shared singleton monitor instance.
    public static let shared = ScreenshotMonitor()

    /// Opaque reference to the active CoreServices FSEvent stream.
    private var streamRef: FSEventStreamRef?

    /// Dedicated user-initiated serial dispatch queue processing incoming filesystem event callbacks.
    private let queue = DispatchQueue(label: "com.clipshot.fsevents", qos: .userInitiated)

    /// Internal tracking flag indicating active stream execution.
    private var isMonitoring: Bool = false

    /// Standardized file path of the currently monitored folder.
    private var currentMonitoredPath: String?

    /// Initializes monitor and attaches workspace wake-from-sleep lifecycle observers.
    public init() {
        setupWakeNotification()
    }

    deinit {
        stop()
    }

    // MARK: - Lifecycle

    /// Starts or restarts monitoring on the active screenshot directory.
    ///
    /// Validates directory existence on disk, checks if already monitoring the identical path,
    /// tears down any existing stream, and starts a fresh low-latency FSEvent stream.
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

    /// Stops monitoring the filesystem and releases underlying CoreServices stream resources.
    ///
    /// Executes `FSEventStreamStop`, `FSEventStreamInvalidate`, and `FSEventStreamRelease` to
    /// prevent CoreServices memory leaks.
    public func stop() {
        guard let stream = streamRef else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        streamRef = nil
        isMonitoring = false
        AppLogger.shared.info("Stopped FSEvents monitoring")
    }

    /// Restarts monitoring (e.g. when directory setting changes or system wakes from sleep).
    public func restart() {
        stop()
        start()
    }

    // MARK: - Private FSEvents Setup

    /// Configures and starts the low-latency FSEventStream on a background dispatch queue.
    ///
    /// Flags used:
    /// - `kFSEventStreamCreateFlagUseCFTypes`: Passes paths as native CFArray of CFStrings.
    /// - `kFSEventStreamCreateFlagFileEvents`: Requests fine-grained file-level rather than directory-level notifications.
    /// - `kFSEventStreamCreateFlagNoDefer`: Delivers events immediately without batching delays.
    ///
    /// - Parameter path: Normalized directory path to watch.
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

    /// Processes batch filesystem events and dispatches created/renamed file URLs to ScreenshotProcessor.
    ///
    /// Inspects bitwise flags for:
    /// - `kFSEventStreamEventFlagItemCreated`: Newly created screenshot files.
    /// - `kFSEventStreamEventFlagItemRenamed`: Files moved into the folder or renamed by macOS screencapture daemon.
    /// - `kFSEventStreamEventFlagItemModified`: Content writes completing on disk.
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

    /// Registers for system wake notifications to re-establish the FSEvents stream after sleep.
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
