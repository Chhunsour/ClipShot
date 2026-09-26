# On-Screen Measurement & Ruler Guide

ClipShot features a built-in pixel ruler and dimension measurement service designed for designers, developers, and QA engineers.

---

## 📏 Measurement Features

- **Live Pixel Dimension HUD**: When dragging an area selection, real-time bounding box dimensions ($W \times H\text{ px}$) are rendered above the cursor.
- **Euclidean Distance Calculation**: Measures the exact pixel hypotenuse between any two screen points.
- **Horizontal & Vertical Alignment Guides**: Automatically formats clean delta readouts:
  - Horizontal lines: `X px (H)`
  - Vertical lines: `Y px (V)`
  - Diagonal vectors: `Distance px (Δx: X, Δy: Y)`
- **Sub-Pixel Precision**: Rounds to the nearest physical display pixel accounting for Retina `@2x` scale factors.

---

## 🎯 Usage Instructions

1. Press `⌘ ⇧ 2` to bring up the Capture Overlay.
2. Select the **Measure Tool** (`ruler`) on the bottom toolbar.
3. Click and drag across the screen element you want to measure (e.g. padding, button width, margin spacing).
4. Inspect the on-screen badge displaying exact pixel distances.
5. Press `Esc` to dismiss or `Enter` to capture the measured area.
