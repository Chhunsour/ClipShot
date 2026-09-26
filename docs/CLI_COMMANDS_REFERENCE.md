# CLI & Build Script Reference

ClipShot includes developer automation scripts in `Scripts/` to streamline building, testing, diagnostics, and asset generation.

---

## 🛠️ Build Automation (`Scripts/build_app.sh`)

The primary build script packages ClipShot into a standalone macOS `.app` bundle:

```bash
# Display help and available options
./Scripts/build_app.sh --help

# Standard debug build (default)
./Scripts/build_app.sh

# Optimized release build
./Scripts/build_app.sh --release

# Clean build artifacts before compilation
./Scripts/build_app.sh --clean

# Build and automatically open the resulting application
./Scripts/build_app.sh --open
```

### Options Overview

| Flag | Short | Description |
| :--- | :--- | :--- |
| `--release` | `-r` | Compiles using Swift `-c release` with compiler optimizations |
| `--clean` | `-c` | Removes `.build/` and `.build-app/` before compiling |
| `--open` | `-o` | Launches `ClipShot.app` immediately after successful build |
| `--help` | `-h` | Prints usage details and exit codes |

---

## 🧪 Swift Package Manager Commands

| Action | Command |
| :--- | :--- |
| **Compile Core Library** | `swift build` |
| **Run All Unit Tests** | `swift test` |
| **Run Specific Test Suite** | `swift test --filter <TestSuiteName>` |
| **Run Single Test Case** | `swift test --filter <TestSuiteName>/<testCase>` |

---

## 🔍 Diagnostic Scripts

| Script | Purpose | Run Command |
| :--- | :--- | :--- |
| `check_instant_paste.swift` | Benchmarks clipboard write latency (< 100ms target) | `swift Scripts/check_instant_paste.swift` |
| `check_notch_hover_stability.swift` | Tests hover state hysteresis and collapse timeouts | `swift Scripts/check_notch_hover_stability.swift` |
| `check_video_capture.swift` | Tests ScreenCaptureKit stream creation and permissions | `swift Scripts/check_video_capture.swift` |
| `generate_icons.swift` | Generates multi-resolution iconsets (`.icns`) for macOS | `swift Scripts/generate_icons.swift` |
