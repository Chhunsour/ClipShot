# ClipShot Development & Automation Scripts

This directory contains automation utilities, build scripts, and diagnostic verification tools for ClipShot.

---

## 📜 Script Index

| Script | Type | Description |
| :--- | :---: | :--- |
| **`build_app.sh`** | Bash | Builds release binary via SPM, generates macOS `.app` bundle structure, copies resources/icons, signs bundle, and validates code signature. |
| **`generate_icons.swift`** | Swift | Renders the vector squircle AppIcon with viewfinder corners and lightning copy spark across all standard macOS icon sizes (16x16 through 1024x1024). |
| **`check_instant_paste.swift`** | Swift | Diagnostic test that measures keyboard capture to pasteboard latency, verifying the sub-750ms performance guarantee. |
| **`check_notch_hover_stability.swift`** | Swift | Simulates mouse hover and click interactions against the active ClipNotch panel to detect jitter, oscillation, or frame jumps. |
| **`check_video_capture.swift`** | Swift | Verifies ScreenCaptureKit window filtering and single-frame capture on the active display without opening full UI. |

---

## 🚀 Usage Guide

### 1. Building the Application
To build and package the production `.app` bundle:
```bash
./Scripts/build_app.sh
```
The output will be placed in `build/Release/ClipShot.app`.

### 2. Generating App Icons
To regenerate icons in `AppIcon.iconset`:
```bash
swift Scripts/generate_icons.swift
iconutil -c icns AppIcon.iconset -o Sources/ClipShotApp/Resources/AppIcon.icns
```

### 3. Running Latency Benchmark
With ClipShot running:
```bash
swift Scripts/check_instant_paste.swift
```

### 4. Running Notch Stability Test
With ClipShot running:
```bash
swift Scripts/check_notch_hover_stability.swift
```
