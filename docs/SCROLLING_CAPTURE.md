# Scrolling Long Capture Guide

ClipShot allows you to capture long web pages, lengthy terminal outputs, source code files, and conversation threads into a single continuous image.

---

## 📜 How Scrolling Capture Works

1. **Initial Frame**: ClipShot locks the target viewport coordinates and captures the initial frame.
2. **Scroll Event Tracking**: As you scroll down within the window, ClipShot captures consecutive overlapping frames.
3. **Vertical Stitching Engine**: `ScrollingCaptureService.stitchFrames` compares adjacent frames, calculates overlap offsets, and composites them into a single high-resolution bitmap.
4. **Instant Export**: The assembled long image is written directly to your clipboard and history cache.

---

## 🎯 How to Use

1. Press `⌘ ⇧ 2` to bring up the Capture Overlay.
2. Select the **Scrolling Capture** mode (`arrow.up.and.down.and.sparkles`) in the toolbar.
3. Select the window or rectangular region containing scrollable content.
4. Slowly scroll down using your trackpad or mouse wheel.
5. Click **Done** or press `Enter` to finalize and stitch the composite image.
