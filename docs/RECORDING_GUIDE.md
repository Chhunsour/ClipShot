# Screen Recording & Animated GIF Guide

ClipShot features a built-in screen recording engine capable of capturing crisp MP4 video and animated GIF clips with zero external dependencies.

---

## 🎥 Recording Capabilities

- **Area Recording**: Select any arbitrary rectangular region of your display.
- **Window Recording**: Record a specific application window with clean edges.
- **Full Display Recording**: Capture entire Retina monitors up to 60 FPS.
- **Dual Output Formats**:
  - **MP4 Video**: Hardware-accelerated H.264/HEVC encoding via `AVAssetWriter`.
  - **Animated GIF**: Frame-optimized GIF sequences ideal for GitHub PRs and Slack messages.

---

## 🏝️ ClipNotch Recording Capsule

When a recording starts:
1. ClipNotch smoothly transforms into the **Recording Capsule**.
2. Displays a pulsing red recording indicator, elapsed timer (`00:15`), and audio status.
3. Provides an instant **Stop** button directly in the notch for clean endings without capturing toolbar windows.

---

## ⚙️ Output & Saving

Recordings are automatically saved to your configured screenshot directory:
```
~/Desktop/Screen Recording YYYY-MM-DD at HH.MM.SS.mp4
~/Desktop/Screen Recording YYYY-MM-DD at HH.MM.SS.gif
```
The resulting file is automatically indexed in ClipShot's history and copied to your clipboard if enabled.
