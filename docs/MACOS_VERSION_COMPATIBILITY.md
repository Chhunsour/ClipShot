# macOS Version Compatibility Guide

This document details the macOS operating system versions, architectures, and framework capabilities supported by ClipShot.

---

## 1. Supported Platforms

| macOS Version | Codename | Support Level | Key Technologies Used |
| :--- | :--- | :--- | :--- |
| **macOS 15.0+** | Sequoia | **Tier 1 (Full)** | ScreenCaptureKit, Modern Menu Bar, Native Window Placement |
| **macOS 14.0+** | Sonoma | **Tier 1 (Target)** | Modern ScreenCaptureKit, Interactive Widgets, SMAppService |
| **macOS 13.0+** | Ventura | **Tier 2 (Supported)**| `SMAppService` for Launch at Login, Vision VNRecognizeTextRequest |
| **macOS 12.0 and older** | Monterey & earlier | Unsupported | Missing ScreenCaptureKit & SMAppService APIs |

---

## 2. Hardware Architecture Support

ClipShot is compiled as a Universal 2 binary supporting both major macOS architectures:

- **Apple Silicon (arm64)**: Optimized for M1, M2, M3, and M4 Apple Silicon with native Vision Neural Engine hardware acceleration.
- **Intel (x86_64)**: Fully supported for late Intel Mac models running macOS 13+.

---

## 3. Framework & Subsystem Breakdown

### ScreenCaptureKit vs CGWindowList
- ClipShot utilizes `ScreenCaptureKit` for high-performance, low-latency screen recording and live video stream rendering in the ClipNotch capsule.
- In headless test runner environments, fallback paths avoid WindowServer dependencies.

### Launch at Login (`SMAppService`)
- On macOS 13+, ClipShot uses Apple's official `SMAppService.mainApp` API.
- Replaces legacy deprecated SMLoginItemSetEnabled and Helper App sandboxing patterns.

### Filesystem Ingestion (`FSEvents`)
- Ingestion operates over the Darwin `FSEvents` framework with `kFSEventStreamCreateFlagFileEvents`.
- Survives system sleep via `NSWorkspace.didWakeNotification` observation.
