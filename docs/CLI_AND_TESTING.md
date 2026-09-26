# CLI & Testing Guide

This guide covers building, debugging, testing, and running diagnostic scripts for ClipShot from the terminal.

---

## 🛠️ Build Commands

### Debug Build
Compiles all targets using standard debug settings and symbols:
```bash
swift build
```

### Release Build
Compiles with optimizations enabled (`-O`):
```bash
swift build -c release
```

### Run in Debug Mode
Launches the ClipShot status bar item and event monitors directly from your terminal session:
```bash
swift run ClipShot
```
*Note: Terminal console output will show real-time `[ClipShot] [INFO]` logs.*

---

## 🧪 Testing

ClipShot comes with 52+ unit and integration tests covering:
- Deduplication and burst mitigation
- ClipNotch state machine transitions
- Color palette and dynamic Album Aura extraction
- Pasteboard multi-type representations
- System media control integration

### Run All Tests
```bash
swift test
```

### Run a Specific Test Suite
```bash
# Run only Settings persistence tests
swift test --filter SettingsTests

# Run only ClipNotch state machine tests
swift test --filter ClipNotchStateMachineTests

# Run only deduplication tests
swift test --filter DeduplicationTests
```

### Run Tests in Parallel
```bash
swift test --parallel
```

---

## 📦 Packaging & Distribution

### Building the Standalone `.app`
Run the automated packaging script:
```bash
./Scripts/build_app.sh
```

### Custom Code Signing
By default, `build_app.sh` auto-detects installed Developer ID Application certificates in your macOS Keychain. If none is found, it safely falls back to ad-hoc signing (`-`).

To force a specific identity:
```bash
CLIPSHOT_SIGN_IDENTITY="Developer ID Application: Your Name (TEAM_ID)" ./Scripts/build_app.sh
```

---

## 🔬 Diagnostic Scripts

| Script | Purpose | Command |
| :--- | :--- | :--- |
| **Instant Paste Latency** | Measures time elapsed between shortcut capture and clipboard availability | `swift Scripts/check_instant_paste.swift` |
| **Notch Hover Stability** | Verifies 120Hz spring physics during cursor hover without layout jitter | `swift Scripts/check_notch_hover_stability.swift` |
| **ScreenCaptureKit Check** | Verifies single-window off-screen frame capture | `swift Scripts/check_video_capture.swift` |

---

## 📜 Diagnostic Logging

ClipShot writes rotated, local-only diagnostic logs to:
```bash
# Tail live application logs
tail -f ~/Library/Logs/ClipShot/clipshot.log
```

Log rotation is automated:
- Maximum file size: 2 MB
- Retained files: 3 rotation generations (`clipshot.log`, `clipshot.1.log`, `clipshot.2.log`)
- Never logs screenshot pixel contents or extracted OCR text.
