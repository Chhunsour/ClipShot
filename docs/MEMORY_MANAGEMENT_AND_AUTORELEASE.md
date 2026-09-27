# Memory Management & Autorelease Pool Architecture

Capturing high-resolution Retina screenshots (e.g. 3456 × 2234 at 4 bytes per pixel = ~31 MB per uncompressed bitmap buffer) and recording 60 FPS video streams can quickly bloat resident memory if unmanaged.

ClipShot enforces rigorous memory limits and autorelease scoping to keep idle resident RAM below **35 MB**.

---

## 1. Explicit Autorelease Scoping for Bitmaps

macOS CoreGraphics and ImageIO allocate temporary bitmap memory that relies on the thread's autorelease pool. In long-running background tasks, loops without autorelease pools delay deallocation until the main runloop turns.

ClipShot wraps all bitmap generation in explicit `autoreleasepool` blocks:

```swift
autoreleasepool {
    guard let context = CGContext(...) else { return }
    context.draw(cgImage, in: targetRect)
    if let downscaled = context.makeImage() {
        saveThumbnail(downscaled)
    }
}
// Transient CGContext data buffers and decoded TIFF/PNG structures are freed immediately here
```

---

## 2. Lazy Image Loading via ImageIO Metadata

When populating history tables or browsing screenshot archives:
- ClipShot never loads full `NSImage` objects into memory just to display dimensions or file sizes.
- `ImageUtils.getImageMetadata(at: url)` uses `CGImageSourceCreateWithURL` and `CGImageSourceCopyPropertiesAtIndex`.
- This reads EXIF/PNG header bytes in microseconds without allocating bitmap raster RAM.

---

## 3. Thumbnail Downsampling at Source

Thumbnails are created using ImageIO's hardware-accelerated decode-and-scale pipeline:

```swift
let options: [CFString: Any] = [
    kCGImageSourceCreateThumbnailFromImageAlways: true,
    kCGImageSourceThumbnailMaxPixelSize: 320,
    kCGImageSourceShouldCacheImmediately: true
]
```

This prevents the full 4K/5K bitmap from ever being materialized in memory, generating a tiny 320px thumbnail directly during decoding.

---

## 4. Live Video Capsule Frame Purging

During Video Capsule window mirroring (ScreenCaptureKit):
- Each video frame is rendered into a hardware-backed Metal texture or single-buffer `currentFrame` property.
- When a new frame arrives before the previous frame is consumed, the prior frame is immediately overwritten and deallocated.
- Successive capture buffers never accumulate in a queue, preventing memory leaks during high-load scenarios.

---

## 5. Memory Verification Checklist

- [x] Idle resident memory (RSS) stays under 35 MB.
- [x] Peak memory during 5K full-screen capture stays under 95 MB.
- [x] Rapidly taking 20 screenshots in succession does not exhibit steady memory growth.
- [x] Closing floating tools or dismiss timers triggers immediate deallocation of window controllers.
