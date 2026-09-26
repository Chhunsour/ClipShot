# ClipShot Project Roadmap

This document outlines planned improvements, community requested features, and architectural goals for future releases of **ClipShot**.

---

## 🎯 Short-Term Roadmap

- [ ] **Multi-Monitor Display Selector**: Quick switch between primary and external displays directly from the capture crosshair toolbar.
- [ ] **Text Watermarking**: Optional subtle timestamp or author watermarking in Annotation Studio export.
- [ ] **Custom Colorway Creator**: UI in ClipNotch Settings to create and save custom 3-color user palettes.
- [ ] **Global Hotkey Presets**: Pre-configured shortcut layouts mimicking Shottr, CleanShot X, or macOS defaults.

---

## 🚀 Medium-Term Roadmap

- [ ] **ScreenCaptureKit Performance Tuning**: Migrate remaining legacy CoreGraphics APIs to full ScreenCaptureKit pipelines on macOS 14+.
- [ ] **WebDAV / S3 Private Cloudless Sync**: Optional encrypted backup of history screenshots to user-owned private storage (preserving zero-telemetry policy).
- [ ] **CLI Subcommands**: Command-line flag parsing for triggering specific captures directly from shell scripts (e.g. `clipshot capture --window`).
- [ ] **Audio Source Switching**: Per-app audio selection for screen recordings.

---

## 🛡️ Non-Goals & Guarantees

- **No Cloud Accounts or Subscriptions**: ClipShot will always remain 100% free and offline.
- **No Third-Party Analytics**: No Google Analytics, Mixpanel, Sentry, or telemetry SDKs will ever be added.
- **No Polling**: Background monitoring will strictly remain kernel event-driven.
