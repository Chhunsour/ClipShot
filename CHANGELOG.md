# Changelog

All notable changes to **ClipShot** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.3.0] - 2026-09-26

### Added
- Comprehensive documentation guides:
  - `docs/PERMISSIONS.md`: Detailed setup and troubleshooting for macOS Screen Recording and file permissions.
  - `docs/CLIPNOTCH.md`: Full reference of 14 colorways, 6 finishes, motion physics, and interactive capsules.
  - `docs/KEYBOARD_SHORTCUTS.md`: Keyboard shortcuts reference card and overlay nudge keys.
  - `Scripts/README.md`: Index and usage instructions for all build and diagnostic automation scripts.
- GitHub issue templates for bug reports and feature requests.
- Standard GitHub pull request template.
- Enhanced `.gitignore` rules for Xcode workspace, IDE configurations, and dSYM symbols.
- Target doc comments in `Package.swift`.

### Changed
- Refined README architecture tree to accurately reflect `Core` and `CaptureOverlay` modules.
- Updated `AppConfig.helpURL` to active GitHub repository.

---

## [1.2.0] - 2026-09-07

### Added
- Dynamic **Album Aura** colorway: automatically samples and extracts a 3-color jewel palette directly from active music album artwork.
- Interactive live seeking scrubber for ClipNotch music capsule.
- Support for relative timeline seeking in Spotify and Apple Music.

### Improved
- Polished notch animation frame timing during rapid expand/collapse transitions.
- Enhanced recent captures shelf drag-and-drop thumbnail caching.

---

## [1.1.0] - 2026-09-01

### Added
- **ClipNotch**: Dynamic Island companion tailored for MacBook Pro camera notches and external displays.
- 13 Curated Colorways: Prism, Aurora, Ember, Tidal, Cyberpunk, Solaris, Matrix, Cosmic, Synthwave, Sakura, Arctic, Champagne, and Monochrome.
- 6 Tactile Finishes: Obsidian, Glass, Bloom, Titanium, Neon Aura, and Frosted.
- 5 Spring Motion Profiles: Calm, Fluid, Snappy, Pulse, and Bouncy.
- 6 Notch Sizing Presets: Compact, Normal, Large, Extra Large, Ultra Wide, and Studio / Max.
- 3 Placement Modes: Top Header, Below Menu Bar, and Free Floating Island.
- 120 FPS ProMotion fluid spring animations.
- Redesigned music player capsule with track info and transport controls.

---

## [1.0.0] - 2026-08-31

### Added
- Initial open-source release of ClipShot.
- Ultra-responsive screenshot detection using Darwin kernel `FSEvents` (< 100ms latency).
- Multi-format clipboard injection (`public.png`, `public.tiff`, `NSImage`).
- Clipboard-Only Mode (automatic temporary screenshot file trashing).
- Precision crosshair capture HUD (`⌘ ⇧ 2`) with live magnifier loupe and dimensions badge.
- Window capture with native drop shadows.
- Full screen and scrolling capture engines.
- Color picker tool with HEX, RGB, and HSL swatches.
- Screen ruler and dimension measurement tool.
- 100% on-device neural OCR powered by Apple's `Vision.framework`.
- Annotation & Markup studio with blur redaction, shapes, arrows, and callouts.
- Pinned floating reference window with variable opacity.
- Searchable capture history archive with thumbnail caching and date grouping.
- Spotlight-style keyboard Command Palette (`⌥ Space`).
- Zero background polling and 100% offline local privacy architecture.
