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
  - `docs/SECURITY_AND_ENTITLEMENTS.md`: Local privacy guarantees, TCC permissions, and hardened runtime.
  - `docs/PERFORMANCE.md`: Benchmarks, memory footprint, and ScreenCaptureKit optimizations.
  - `docs/OCR_GUIDE.md`: Offline Apple Vision neural text recognition.
  - `docs/COLOR_PICKER.md`: Precision pixel loupe, HEX / RGB / HSL / Display P3 color formatting.
  - `docs/MEASUREMENT_TOOL.md`: On-screen Euclidean distance calculation and bounding margins.
  - `docs/ANNOTATION_STUDIO.md`: Vector arrows, blur & pixelate redactions, step badges, typography.
  - `docs/FLOATING_PIN.md`: Stay-on-top reference windows with variable transparency.
  - `docs/HISTORY_ARCHIVE.md`: Searchable capture archive, thumbnail caching, and pruning rules.
  - `docs/COMMAND_PALETTE.md`: Spotlight-style launcher (`⌥ Space`) and fuzzy search.
  - `docs/RECORDING_GUIDE.md`: Hardware-accelerated MP4 video and animated GIF capture.
  - `docs/SCROLLING_CAPTURE.md`: Vertical frame stitching for long documents and code files.
  - `docs/TROUBLESHOOTING.md`: Diagnostic steps, TCC permission resets, and log inspection.
  - `docs/CONFIGURATION.md`: Complete `AppSettings` keys, defaults, and `UserDefaults` mapping.
  - `docs/FAQ.md`: Frequently asked questions, privacy, and performance FAQ.
  - `docs/ACCESSIBILITY.md`: VoiceOver support, keyboard accessibility, and reduced motion.
  - `docs/LOCALIZATION.md`: Guide for contributing multi-language translations.
  - `docs/ROADMAP.md`: Planned features, community requests, and architectural non-goals.
  - `Examples/README.md`: Developer recipes for extending and integrating with `ClipShotCore`.
  - `Scripts/README.md`: Index and usage instructions for all build and diagnostic automation scripts.
- Over 20 comprehensive unit test suites covering models, enums, settings, and utility services.
- GitHub Actions CI workflow for macOS build, unit test execution, and bundle validation.
- Dependabot configuration for GitHub Actions dependencies.
- GitHub issue templates for bug reports, feature requests, and documentation improvements.
- Standard GitHub pull request template and CODEOWNERS configuration.
- Enhanced `.gitignore` rules for Xcode workspace, IDE configurations, and dSYM symbols.
- Target doc comments in `Package.swift`.

### Fixed
- Fixed unbundled test runner compatibility in `PermissionsManager` to safely guard UserNotifications authorization calls during headless unit tests.

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
