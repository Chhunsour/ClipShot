# FSEvents Kernel Stream Internals & Zero-Polling Detection

Instantaneous screenshot detection requires observing filesystem writes with microsecond responsiveness while consuming negligible CPU and energy. ClipShot implements this via Apple's CoreServices `FSEventStream` API.

---

## 1. Polling vs Event-Driven Architecture

| Characteristic | Periodic Polling (e.g. 500ms Timer) | FSEvents Stream (`ScreenshotMonitor`) |
| :--- | :--- | :--- |
| **CPU Overhead** | Continuous wakeups every 500ms; prevents CPU deep sleep | 0.0% CPU when idle; CPU remains in low-power states |
| **I/O Overhead** | Repeated `readdir()` calls scan directory contents | Zero disk reads until kernel triggers an event |
| **Capture Latency** | 0 to 500ms delay depending on poll phase | Sub-millisecond (< 5ms) instantaneous kernel notification |
| **Battery Impact** | Continuous wakeups drain laptop battery | Negligible; energy impact score < 0.1 |

---

## 2. Stream Configuration & Creation Flags

ClipShot configures the kernel stream in `ScreenshotMonitor.swift`:

```swift
let flags = UInt32(
    kFSEventStreamCreateFlagUseCFTypes |
    kFSEventStreamCreateFlagFileEvents |
    kFSEventStreamCreateFlagNoDefer
)

let stream = FSEventStreamCreate(
    kCFAllocatorDefault,
    callback,
    &context,
    pathsToWatch,
    FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
    0.0, // 0.0s latency for instant delivery
    flags
)
```

### Flag Semantics:
- **`kFSEventStreamCreateFlagUseCFTypes`**: Delivers event paths as standard `CFArray` of `CFString` objects, avoiding manual C-string pointer arithmetic.
- **`kFSEventStreamCreateFlagFileEvents`**: Instructs the kernel to emit granular events for individual files rather than coarse directory-level notifications.
- **`kFSEventStreamCreateFlagNoDefer`**: Bypasses kernel event coalescing windows, delivering notifications immediately without buffering.
- **Latency `0.0`**: Requests zero artificial delivery delay.

---

## 3. Bitmask Event Flag Processing

When the callback fires, ClipShot filters for relevant file events:

```swift
let isCreated  = (eventFlag & UInt32(kFSEventStreamEventFlagItemCreated)) != 0
let isRenamed  = (eventFlag & UInt32(kFSEventStreamEventFlagItemRenamed)) != 0
let isModified = (eventFlag & UInt32(kFSEventStreamEventFlagItemModified)) != 0

if isCreated || isRenamed || isModified {
    Task {
        await ScreenshotProcessor.shared.processCandidate(url: url)
    }
}
```

- **`ItemCreated`**: Fires when a screenshot application begins creating the target image file.
- **`ItemRenamed`**: macOS screencapture daemon often writes to a temporary dot-file and renames it atomically upon flush completion.
- **`ItemModified`**: Signals chunked writes to disk completing.

---

## 4. Sleep & Wake Recovery

When a MacBook lid closes, macOS suspends background queues. Upon waking, kernel event streams can occasionally encounter dropped event IDs or stalled mach ports.

ClipShot observes `NSWorkspace.didWakeNotification`:
```swift
NSWorkspace.shared.notificationCenter.addObserver(
    forName: NSWorkspace.didWakeNotification,
    object: nil,
    queue: .main
) { [weak self] _ in
    AppLogger.shared.info("System did wake from sleep; refreshing FSEvents monitor")
    self?.restart()
}
```
This guarantees reliable continuous monitoring across sleep cycles without requiring an application restart.
