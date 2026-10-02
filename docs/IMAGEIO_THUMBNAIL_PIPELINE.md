# ImageIO Hardware Thumbnail Downsampling Architecture

This document describes the zero-decoding dimensions queries and hardware-accelerated thumbnail downsampling pipeline employed across **ClipShot**.

---

## 1. Motivation & Memory Constraints

Modern macOS displays run at high Retina resolutions (e.g., 2880×1800, 3456×2234 on MacBook Pro, up to 5120×2880 on Apple Studio Display). An uncompressed 32-bit RGBA raster image of a full display capture requires:

$$\text{Memory} = \text{Width} \times \text{Height} \times 4 \text{ bytes}$$

* **14" MacBook Pro (3024×1964):** $\approx 23.7\text{ MB}$ uncompressed RAM
* **16" MacBook Pro (3456×2234):** $\approx 30.9\text{ MB}$ uncompressed RAM
* **5K Studio Display (5120×2880):** $\approx 58.9\text{ MB}$ uncompressed RAM

If ClipShot were to decode full bitmaps merely to display small preview chips in the Dynamic Notch (`ClipNotch`) or History Archive items, caching 50 captures in memory would consume upwards of **1.5 GB to 3.0 GB of RAM**.

---

## 2. ImageIO Subsampling Engine

ClipShot utilizes Apple's `ImageIO` framework to perform on-the-fly subsampled decoding directly from encoded compressed disk buffers (PNG, JPEG, HEIC, TIFF).

```swift
let options: [CFString: Any] = [
    kCGImageSourceCreateThumbnailFromImageAlways: true,
    kCGImageSourceShouldCacheImmediately: true,
    kCGImageSourceCreateThumbnailWithTransform: true,
    kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
]

guard let source = CGImageSourceCreateWithURL(fileURL as CFURL, nil),
      let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
    return nil
}
```

### Key Flags & Behaviors

1. **`kCGImageSourceCreateThumbnailFromImageAlways`**: Forces downsampling even if an embedded thumbnail is absent.
2. **`kCGImageSourceThumbnailMaxPixelSize`**: Bounds the maximum edge length (e.g., 256px or 512px). The decoder subsamples during decompression, maintaining high visual fidelity while reducing peak memory allocation by up to **98%**.
3. **`kCGImageSourceCreateThumbnailWithTransform`**: Automatically honors EXIF orientation tags without additional matrix manipulations.
4. **`kCGImageSourceShouldCacheImmediately`**: Prevents lazy decoding spikes on UI threads by pre-decoding on background dispatch queues.

---

## 3. Zero-Decoding Dimensions Extraction

To extract capture dimensions, aspect ratios, or DPI metadata without decoding pixel bytes:

```swift
let queryOptions: [CFString: Any] = [
    kCGImageSourceShouldCache: false
]

if let source = CGImageSourceCreateWithURL(fileURL as CFURL, queryOptions as CFDictionary),
   let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, queryOptions as CFDictionary) as? [CFString: Any] {
    let width = properties[kCGImagePropertyPixelWidth] as? CGFloat ?? 0
    let height = properties[kCGImagePropertyPixelHeight] as? CGFloat ?? 0
}
```

This ensures file inspection executes in **< 0.1ms** without allocating framebuffer memory.
