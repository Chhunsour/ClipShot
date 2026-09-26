# Contributing to ClipShot

Thank you for your interest in improving **ClipShot**! ClipShot is an open-source, local-first screenshot-to-clipboard engine and Dynamic Notch companion for macOS.

We welcome contributions of all kinds: bug fixes, documentation improvements, new tests, and enhancements.

---

## 🛠️ Development Setup

### System Prerequisites
- **macOS 14.0 (Sonoma)** or **macOS 15.0 (Sequoia)** or later
- **Xcode 15.0+** or the Command Line Tools (`xcode-select --install`)
- **Swift 5.9+** toolchain
- Apple Silicon (M-series) or Intel Mac

### Getting Started

1. **Fork and Clone** the repository:
   ```bash
   git clone https://github.com/<your-username>/ClipShot.git
   cd ClipShot
   ```

2. **Build the Project**:
   ```bash
   swift build
   ```

3. **Run the Test Suite**:
   ```bash
   swift test
   ```
   All 52+ unit and integration tests should pass before submitting any changes.

4. **Run in Debug Mode**:
   ```bash
   swift run ClipShot
   ```

5. **Build the Standalone `.app` Bundle**:
   ```bash
   ./Scripts/build_app.sh
   ```
   The built bundle will reside at `build/Release/ClipShot.app`.

---

## 📐 Project Structure

- `Package.swift`: Swift Package Manager manifest declaring targets and dependencies.
- `Sources/ClipShotApp/`: Application entry point, `AppDelegate`, and lifecycle management.
- `Sources/ClipShotCore/`: Core library containing:
  - `CaptureEngine/`: Low-level ScreenCaptureKit, CoreGraphics, and AVFoundation capture services.
  - `CaptureOverlay/`: Crosshairs, interactive loupe magnifier, color picker, and measurement tools.
  - `Core/`: FSEvents file monitor, NSPasteboard multi-type writer, deduplication, and hotkey managers.
  - `Features/`: Feature implementations including ClipNotch, Command Palette, History, OCR, and Settings.
  - `Models/`: Data structures, configuration enums, and persistent preferences.
  - `Utilities/`: ImageIO decoding, logging, and audio feedback.
- `Tests/ClipShotTests/`: Unit and integration test suite.
- `Scripts/`: Automation scripts for app packaging and automated verification.

---

## 🛡️ Core Architectural Principles

When writing or reviewing code for ClipShot, please adhere to these core principles:

1. **Zero Telemetry & Absolute Privacy**: ClipShot makes 0 network requests. Never introduce analytics, tracking SDKs, or cloud dependencies.
2. **Zero-Polling Efficiency**: Filesystem monitoring is event-driven via `FSEvents`. Never introduce background polling loops or timers that wake the CPU unnecessarily.
3. **Thread Safety & Swift Concurrency**: Use Swift Concurrency (`actor`, `@MainActor`, `async/await`) properly. UI interactions must always happen on the `@MainActor`.
4. **Resilient Non-Blocking UX**: Clipboard injection and image decoding must remain off the main thread so user workflows are never blocked.

---

## 📝 Pull Request Guidelines

1. **Branch Naming**: Use descriptive branch names:
   - `feat/feature-name`
   - `fix/issue-description`
   - `docs/clarify-setup`
2. **Keep Commits Focused**: Prefer atomic, descriptive commits following Conventional Commits (e.g., `feat(notch): ...`, `fix(capture): ...`, `docs: ...`).
3. **Verify Tests**: Ensure `swift test` runs cleanly with zero failures.
4. **Formatting**: Keep code clean, idiomatic, and consistent with existing Swift patterns.
