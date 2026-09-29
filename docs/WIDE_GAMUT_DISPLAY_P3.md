# Display P3 Wide Color Gamut Architecture & Color Fidelity

Modern Apple hardware—including MacBook Pro Liquid Retina XDR displays, iMacs, iPhones, and Apple Studio Displays—features wide-gamut Display P3 panels. Maintaining pixel-accurate color reproduction during screenshot capture, loupe magnification, and clipboard sharing requires rigorous color space management.

---

## 1. Color Gamut Comparison: sRGB vs Display P3

| Primary / Property | Standard sRGB (BT.709) | Display P3 (Apple Wide Color) |
| :--- | :--- | :--- |
| **Red Primary (x, y)** | `(0.640, 0.330)` | `(0.680, 0.320)` (Deeper crimson) |
| **Green Primary (x, y)** | `(0.300, 0.600)` | `(0.265, 0.690)` (Vivid emerald) |
| **Blue Primary (x, y)** | `(0.150, 0.060)` | `(0.150, 0.060)` (Identical) |
| **White Point** | D65 `(0.3127, 0.3290)` | D65 `(0.3127, 0.3290)` (Identical) |
| **Transfer Curve** | sRGB gamma (~2.2 piecewise) | sRGB gamma (~2.2 piecewise) |
| **Gamut Volume** | Baseline (100%) | **+35.7% larger chromatic area** |

---

## 2. Common Pitfalls in Unmanaged Screen Capture

1. **Untagged RGB Triplet Assumption**:
   If an application samples raw RGB values `(1.0, 0.0, 0.0)` from a Display P3 screen and interprets them as sRGB, the color appears desaturated or shifted.
2. **Clipping When Converting P3 to sRGB**:
   Vivid saturated colors in P3 fall outside the reproducible sRGB triangle. Converting naively without perceptual or relative colorimetric rendering intents causes harsh edge clipping.
3. **Double Gamma Correction**:
   Applying gamma expansion or compression twice results in crushed shadows or blown highlights.

---

## 3. ClipShot Color Fidelity Strategy

ClipShot enforces color integrity across three critical stages:

### A. Screen Capture
CoreGraphics screen captures preserve the native screen color space (`screen.colorSpace`). On modern MacBooks, `CGImageGetColorSpace()` returns Display P3.

### B. Precision Loupe & Eyedropper Sampling
When sampling single-pixel colors for developers:
```swift
// Preserves calibrated RGB color representations without lossy gamut compression
let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
let sampledColor = bitmapRep.colorAt(x: 0, y: 0)
let hex = sampledColor.hexRepresentation
```

### C. Multi-Flavor Pasteboard Ingestion
ClipShot writes image representations to `NSPasteboard` with embedded ICC color profiles:
- **`public.png`**: Includes the embedded P3 color profile chunk (`iCCP`), ensuring web browsers and Slack render exact colors.
- **`public.tiff`**: Uncompressed tagged image representation retaining native Quartz color metadata for Adobe Creative Cloud and Figma.
