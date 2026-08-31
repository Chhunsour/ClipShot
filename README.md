# ClipShot

> **Instant macOS Screenshot-to-Clipboard Productivity Utility**
> *Take a screenshot. Paste it immediately.*

ClipShot is a lightweight, ultra-responsive native macOS menu-bar utility designed around one essential workflow: whenever you take a screenshot on your Mac (using standard shortcuts like `⌘ ⇧ 4`, `⌘ ⇧ 3`, or `⌘ ⇧ 5`), ClipShot automatically detects it in real time and places the actual image bytes onto your clipboard. You can immediately press `⌘ V` in apps like ChatGPT, Discord, Slack, Telegram, Figma, Notion, Photoshop, or your browser without having to manually open or copy the file.

---

## Key Features

- ⚡ **Near-Instant Auto-Copy (< 100–250ms)**: Uses macOS File System Events (`FSEvents`) for zero-polling, negligible-CPU event detection.
- 📋 **Universal Clipboard Compatibility**: Writes raw PNG, TIFF, and NSImage representations to `NSPasteboard.general` for reliable pasting across all modern macOS apps.
- 🛡️ **Deduplication & Sequence Protection**: Safely handles bursts of rapid screenshots (`A → B → C`), guaranteeing the latest screenshot wins the clipboard while all are indexed in history.
- 🪟 **Floating Preview Overlay**: Lightweight, non-activating thumbnail overlay with quick actions (`Copy`, `OCR`, `Edit`, `Pin`, `Finder`, `Trash`, `Close`).
- 🕒 **Screenshot History**: Searchable history with date grouping, lightweight metadata storage, and disk-cached thumbnails with automatic retention policies (max item count & age limits).
- 📌 **Pin to Screen**: Float reference screenshots on top of all windows with adjustable opacity (25%, 50%, 75%, 100%), resizing, and dragging.
- 🔍 **Offline OCR (Apple Vision)**: Extract text locally on your Mac with `VNRecognizeTextRequest`—zero cloud requests, zero data transmission.
- ✏️ **Annotation & Markup Editor**: Arrow, rectangle, ellipse, pen, text callout, highlight, blur, and crop tools with high-fidelity PNG export.
- 🧹 **Clipboard-Only Mode**: Opt-in mode that copies the screenshot bytes to the clipboard and immediately trashes the original file, keeping your Desktop spotless.
- 🚀 **Modern Launch at Login**: Implemented using Apple's official `SMAppService` API (macOS 13+).
- 🔒 **100% Offline & Private**: No analytics, no accounts, no network requests. All data stays strictly on your Mac.

---

## Architecture Overview

```
ClipShot/
├── Package.swift                       # SPM package manifest
├── Sources/
│   ├── ClipShotCore/                   # Core business logic framework
│   │   ├── AppConfig.swift             # App constants, naming & branding
│   │   ├── Models/
│   │   │   ├── AppSettings.swift       # Reactive user preferences (UserDefaults)
│   │   │   ├── AppEnums.swift          # Configuration enums
│   │   │   └── ScreenshotItem.swift    # Screenshot metadata record
│   │   ├── Core/
│   │   │   ├── ScreenshotMonitor.swift # FSEvents filesystem monitor
│   │   │   ├── ScreenshotDetector.swift# Candidate verification & metadata heuristic
│   │   │   ├── ScreenshotProcessor.swift# Central actor: stability, ordering & deduplication
│   │   │   ├── ClipboardManager.swift  # NSPasteboard writer & format provider
│   │   │   ├── HistoryManager.swift    # History persistence & thumbnail caching
│   │   │   ├── HotkeyManager.swift     # Carbon global hotkeys
│   │   │   ├── LaunchAtLoginManager.swift# SMAppService integration
│   │   │   └── PermissionsManager.swift# System permissions & deep links
│   │   ├── Features/
│   │   │   ├── MenuBar/                # NSStatusItem controller & dynamic menu
│   │   │   ├── Preview/                # Non-activating floating preview panel
│   │   │   ├── History/                # History viewer window & search
│   │   │   ├── Pin/                    # Floating reference pinned window
│   │   │   ├── OCR/                    # Local Vision OCR text extraction
│   │   │   ├── Markup/                 # Canvas annotation editor
│   │   │   ├── Capture/                # Built-in area/screen/window capture
│   │   │   ├── Onboarding/             # 3-step first-launch guide
│   │   │   └── Settings/               # Native tabbed preferences window
│   │   └── Utilities/
│   │       ├── ImageUtils.swift        # ImageIO, CGImage & PNG converters
│   │       ├── PathUtils.swift         # Screenshot location detection & bookmarks
│   │       ├── AppLogger.swift         # Rotating diagnostic file logger
│   │       └── SoundManager.swift      # Subtle audio feedback
│   └── ClipShotApp/                    # Main executable target
│       ├── ClipShotApp.swift           # @main entry point
│       ├── AppDelegate.swift           # NSApplicationDelegate lifecycle
│       └── Resources/                  # Info.plist & AppIcon.icns
├── Tests/
│   └── ClipShotTests/                  # Comprehensive unit & integration tests
│       ├── ScreenshotDetectorTests.swift
│       ├── DeduplicationTests.swift
│       ├── HistoryManagerTests.swift
│       ├── ClipboardManagerTests.swift
│       ├── SettingsTests.swift
│       ├── ImageUtilsTests.swift
│       └── EndToEndWorkflowTests.swift
└── Scripts/
    ├── build_app.sh                    # Release build and packaging script
    └── generate_icons.swift            # CoreGraphics icon generator
```

---

## How Automatic Screenshot Copying Works

```
macOS screenshot shortcut (⌘ ⇧ 4 / ⌘ ⇧ 3)
              ↓
macOS writes screenshot file to folder (e.g. ~/Desktop)
              ↓
FSEvents Stream detects file modification (latency: 50ms)
              ↓
ScreenshotProcessor verifies file write stability (ImageIO statusComplete)
              ↓
ScreenshotDetector validates candidate (kMDItemIsScreenCapture / naming heuristic)
              ↓
Deduplication cache ignores redundant events
              ↓
Image decoded off UI thread
              ↓
ClipboardManager writes PNG & TIFF representations to NSPasteboard.general
              ↓
HistoryManager indexes metadata & caches thumbnail
              ↓
FloatingPreviewPanel displays lightweight overlay in screen corner
              ↓
You press ⌘ V in any target application!
```

---

## Building and Running

### Requirements
- macOS 14.0 or later
- Apple Silicon (M1/M2/M3/M4) or Intel Mac
- Xcode 15+ / Swift 5.9+

### Quick Build (Release `.app` Bundle)
To build the standalone `ClipShot.app`:
```bash
./Scripts/build_app.sh
```
The resulting application is placed at:
```
build/Release/ClipShot.app
```
The build uses the first available local signing identity and falls back to ad-hoc signing. Set `CLIPSHOT_SIGN_IDENTITY` to choose a specific certificate.

### Running Unit & Integration Tests
Run via Swift Package Manager:
```bash
swift test
```
Or via `xcodebuild`:
```bash
xcodebuild test -scheme ClipShot -destination "platform=macOS"
```

### Running Debug Build
```bash
swift run ClipShot
```

---

## Permissions Guide

ClipShot adheres strictly to the principle of least privilege:
- **Screenshot Folder Access**: Granted automatically for standard folders; prompts for custom folders via `NSOpenPanel` using security-scoped bookmarks so permissions persist across restarts.
- **Screen Recording (Optional)**: Only required if you use ClipShot's built-in capture actions (`Capture Area`, `Capture Full Screen`, `Capture Window`). Standard macOS shortcuts (`⌘ ⇧ 4`, etc.) do **not** require this permission.
- **Notifications (Optional)**: Used to display non-intrusive feedback and error alerts.

---

## Troubleshooting

### Screenshot is not copied to clipboard
1. Verify that ClipShot is running in your menu bar and shows `● Monitoring Active`.
2. Check that the screenshot directory in **Settings → Screenshots** matches where macOS saves screenshots. (Default: `~/Desktop`).
3. If using custom folders, click **Choose Folder...** in Settings to re-grant folder access.

### Screenshot folder changed
If you changed your macOS screenshot destination using `defaults write com.apple.screencapture location <path>`, restart ClipShot or select the new folder in **ClipShot Settings → Screenshots → Choose Folder...**.

### Clipboard Only Mode
If you enable **Clipboard Only Mode**, ClipShot will load the screenshot data into memory, write the image bytes to the clipboard, verify the pasteboard write succeeded, and automatically move the original file from the Desktop into the macOS Trash.

---

## Privacy Assurance

ClipShot does not collect, store, or transmit any user data. All processing (screenshot detection, clipboard formatting, image rendering, OCR text recognition, and logging) occurs entirely locally and offline on your Mac.

---

## License

ClipShot is open source under the [MIT License](LICENSE).
