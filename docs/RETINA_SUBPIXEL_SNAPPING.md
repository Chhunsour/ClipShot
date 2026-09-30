# Retina Subpixel Point Snapping & Hairline Rendering Architecture

macOS devices utilize high-DPI Retina displays operating at `2.0x` (e.g. MacBook Pro Liquid Retina XDR, Studio Display) or non-integer virtual scale factors. In AppKit and CoreGraphics, layout and geometry are defined in **logical points**, while physical rendering occurs in **hardware pixels**. Without precise snapping, vector outlines and hairlines land across physical pixel boundaries, resulting in blurry, anti-aliased borders and degraded visual clarity.

---

## 1. The Point vs Pixel Discrepancy

| Metric | Non-Retina (1x) | Standard Retina (2x) | Ultra Retina / Scaled (3x) |
| :--- | :--- | :--- | :--- |
| **Point-to-Pixel Ratio** | 1 pt = 1 px | 1 pt = 2 px | 1 pt = 3 px |
| **1 Physical Pixel in Points** | 1.0 pt | 0.5 pt | 0.333 pt |
| **0.5 Physical Pixel in Points** | N/A (Cannot render) | 0.25 pt | 0.167 pt |
| **Minimum Hairline Stroke** | 1.0 pt | **0.5 pt** | **0.333 pt** |

---

## 2. The 1-Pixel Hairline Problem

When drawing a 1-pixel wide line in CoreGraphics, standard integer point coordinates cause rasterization blur:

```
Center of line at X = 10.0 pt:
Stroke width = 1.0 pt (spans X = 9.5 pt to 10.5 pt)
On a 1x display: Covers pixel columns 9 and 10 with 50% opacity (BLURRY)

On a 2x display:
1.0 pt stroke = 2 physical pixels (spans physical pixels 19 to 21)
Exact half-point offset aligns the stroke center with pixel boundary:
X = 10.25 pt or stroke width = 0.5 pt (1 physical pixel).
```

### The Solution: 0.5pt Hairline Alignment
To achieve an ultra-crisp single-pixel border on a 2x Retina screen:
1. Set the stroke width to `1.0 / backingScaleFactor` (e.g., `0.5 pt` on 2x).
2. Offset stroke center coordinates by `0.5 / backingScaleFactor` (e.g., `0.25 pt`) when stroking centered paths.

---

## 3. Subpixel Snapping Mathematical Formulation

To align any arbitrary logical point or rectangle to exact physical hardware pixel boundaries:

$$\text{snappedPoint} = \frac{\text{round}(\text{point} \times \text{scale})}{\text{scale}}$$

$$\text{snappedRect} = \text{CGRect}\left(\frac{\text{floor}(x \times s)}{s}, \frac{\text{floor}(y \times s)}{s}, \frac{\text{ceil}((x + w) \times s) - \text{floor}(x \times s)}{s}, \frac{\text{ceil}((y + h) \times s) - \text{floor}(y \times s)}{s}\right)$$

---

## 4. Swift Implementation in ClipShot

ClipShot encapsulates coordinate normalization in geometry extensions:

```swift
extension CGFloat {
    /// Snaps a logical coordinate to the nearest physical device pixel boundary.
    public func pixelAligned(scale: CGFloat) -> CGFloat {
        guard scale > 0 else { return self }
        return (self * scale).rounded() / scale
    }
}

extension CGRect {
    /// Aligns rect origin and size to integer device pixel boundaries.
    public func pixelAligned(scale: CGFloat) -> CGRect {
        guard scale > 0 else { return self }
        let minX = (self.minX * scale).rounded(.down) / scale
        let minY = (self.minY * scale).rounded(.down) / scale
        let maxX = (self.maxX * scale).rounded(.up) / scale
        let maxY = (self.maxY * scale).rounded(.up) / scale
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}
```

---

## 5. Application Across Subsystems

- **Crop & Selection Overlay**: Drag selection handles and bounding frames snap to 0.5pt grids, ensuring screen captures cleanly extract whole pixels without fractional subpixel fringing.
- **Loupe Magnifier Crosshairs**: The center crosshair renders at `0.5 pt` stroke width on 2x screens, perfectly bisecting pixel grid cells.
- **Dimension Badges**: Text baseline and pill container backgrounds snap to backing scale, preventing fuzzy typography during live mouse drags.
