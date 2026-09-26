# ClipShot Architecture & Engineering Deep-Dive

This document details the underlying system architecture, concurrency guarantees, and event pipeline of **ClipShot**.

---

## 🏛️ High-Level Design

ClipShot operates as a decoupled, event-driven macOS background utility. Its primary objective is to capture, process, and inject screenshots into the system clipboard with minimum latency (< 100ms) and zero background CPU usage.

```
┌────────────────────────────────────────────────────────┐
│                   macOS Darwin Kernel                  │
│   (ScreenCapture writes file to disk -> FSEvents)     │
└──────────────────────────┬─────────────────────────────┘
                           │ Kernel Event (Latency: ~50ms)
                           ▼
┌────────────────────────────────────────────────────────┐
│                   ScreenshotMonitor                    │
│   FSEventStream with kFSEventStreamCreateFlagFileEvents│
└──────────────────────────┬─────────────────────────────┘
                           │ Candidate File URL
                           ▼
┌────────────────────────────────────────────────────────┐
│              ScreenshotProcessor (Actor)               │
│   - Burst deduplication cache                          │
│   - Asynchronous ImageIO file stability polling        │
│   - Mode dispatch (Clipboard-only vs Keep)             │
└───────────┬────────────────────────────────────────────┘
            │
            ├──────────────────────────┬──────────────────────────┐
            ▼                          ▼                          ▼
┌───────────────────────┐  ┌───────────────────────┐  ┌───────────────────────┐
│   ClipboardManager    │  │    HistoryManager     │  │   ClipNotchViewModel  │
│  NSPasteboard.general │  │  Metadata & Thumbnail │  │      (@MainActor)     │
│  (PNG, TIFF, NSImage) │  │  SQLite/JSON Storage  │  │  120Hz Spring Physics │
└───────────────────────┘  └───────────────────────┘  └───────────────────────┘
```

---

## 🧵 Concurrency & Actor Isolation

1. **`ScreenshotProcessor` Actor**:
   All filesystem candidate verification, burst debouncing, and stability checks run inside an isolated Swift `actor`. This eliminates race conditions when multiple screenshot events fire in rapid succession (e.g., burst captures or automated tools).

2. **`@MainActor` UI Pipeline**:
   All UI controllers (`ClipNotchPanel`, `FloatingPreviewPanel`, `CaptureOverlayController`, `MenuBarController`) are strictly bound to `@MainActor`. State changes dispatched from background processing actors hop cleanly to the main thread via `@MainActor` isolated view models.

3. **Background ImageIO Decoding**:
   Image decoding occurs off the main thread using Apple's `ImageIO.framework` (`CGImageSourceCreateWithURL`). Bitmaps are decoded lazily or thumbnail-scaled without blocking the main RunLoop.

---

## ⚡ File Stability & Burst Deduplication

When macOS captures a screenshot, it writes the PNG file incrementally. Attempting to read bytes immediately can cause torn reads or corrupted decodes.

ClipShot solves this without timer polling:
1. When an `FSEvents` notification arrives, `ScreenshotProcessor` checks `CGImageSourceCreateWithURL`.
2. It queries `CGImageSourceGetStatus(source)`. If the status is `.statusComplete`, the file write has concluded.
3. If incomplete, it retries with an exponential nano-sleep (up to `AppConfig.maxFileStabilityRetries`).
4. Rapid bursts (`A → B → C` within milliseconds) update the sequence number, guaranteeing the most recent screenshot wins the clipboard while previous captures are still indexed in history.

---

## 📋 Multi-Format Pasteboard Representation

When copying an image, different macOS applications expect different pasteboard types:
- **Web browsers, Slack, Discord, Telegram**: Prefer `public.png` or `image/png`.
- **Native macOS apps, Pages, Keynote**: Prefer `public.tiff`.
- **Cocoa/AppKit applications**: Expect `NSImage` object representations.

ClipShot populates `NSPasteboard.general` atomically with all three formats simultaneously, ensuring 100% paste compatibility across every target application.

---

## 🏝️ ClipNotch Floating Architecture

ClipNotch is built using a custom `NSPanel` subclass (`ClipNotchPanel`):
- **Window Level**: Positioned at `NSWindow.Level.statusBar` or `.floating` (level 25) so it floats above standard application windows without obscuring system modals.
- **Focus Non-Stealing**: Configured with `.nonactivatingPanel` style mask so clicking or interacting with ClipNotch never steals keyboard focus from the user's active editor or browser.
- **Display Tracking**: `DisplayTrackingService` monitors screen reconfiguration notifications (`NSApplication.didChangeScreenParametersNotification`) to dynamically align the notch with the primary display's camera housing.
- **ProMotion Synchronization**: All notch spring animations are driven by SwiftUI spring physics running at 120 FPS on Apple Silicon ProMotion displays.
