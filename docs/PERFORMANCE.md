# Performance & Resource Efficiency Guide

ClipShot is engineered specifically for macOS to be lightweight, responsive, and battery-friendly on both Apple Silicon (M1/M2/M3/M4) and Intel Macs.

---

## Benchmarks & Resource Targets

| Metric | Target | Realized Measurement |
| :--- | :--- | :--- |
| **Idle Memory Footprint** | < 50 MB | ~38 MB RSS |
| **Active Overlay Memory** | < 120 MB | ~85 MB RSS |
| **Idle CPU Utilization** | < 0.2% | < 0.05% CPU |
| **Capture Latency** | < 80 ms | ~45 ms (ScreenCaptureKit) |
| **OCR Processing Speed** | < 400 ms | ~180 ms (Neural Engine) |

---

## Architectural Optimizations

### 1. Event-Driven File Monitoring
Instead of polling the file system in a timer loop, ClipShot employs kernel event monitoring via `DispatchSource.makeFileSystemObjectSource`. The monitoring subsystem sleeps until macOS kernel `kqueue` notifications signal a new screenshot file creation.

### 2. High-Performance Screen Capture
On macOS 13+, ClipShot leverages Apple's hardware-accelerated **ScreenCaptureKit** framework (`SCStream` / `SCScreenshotManager`). Framebuffers are captured directly in GPU memory using `IOSurface` backing, bypassing expensive user-to-kernel memory copies.

### 3. Smart Thumbnail Downsampling
When populating the Screenshot History grid, ClipShot never decodes full-resolution 4K/5K images into memory. Instead, it utilizes `CGImageSourceCreateThumbnailAtIndex` with sub-sampling flags:
- Generates a fixed-size 320px thumbnail directly during file decoding.
- Keeps peak heap allocations flat regardless of whether the user captured a 12-megapixel screenshot.

### 4. macOS App Nap & Battery Conservation
- Windows and panels are completely deallocated or ordered out (`orderOut:`) when closed, terminating GPU rendering passes.
- Timers for hover effects or media tracking use coalesced firing intervals (`tolerance: 0.2s`) to allow the CPU cores to remain in deep low-power sleep states.
