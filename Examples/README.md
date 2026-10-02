# ClipShot Developer Examples & Snippets

This directory provides standalone executable Swift scripts, reference patterns, and recipes for extending or integrating with `ClipShotCore`.

---

## Directory Overview

| Script / Recipe | Description | Primary Subsystem |
| :--- | :--- | :--- |
| [`detect_screenshot_folder.swift`](detect_screenshot_folder.swift) | Inspect active macOS screenshot folder or override | `PathUtils`, `AppSettings` |
| [`format_color_sample.swift`](format_color_sample.swift) | Convert NSColor samples across HEX, RGB, HSL, and Display P3 | `ColorFormat`, `ColorPickerService` |
| [`calculate_notch_geometry.swift`](calculate_notch_geometry.swift) | Inspect ClipNotch dynamic pill dimensions and corner radii | `ClipNotchSize`, `ClipNotchState` |
| [`prune_screenshot_history.swift`](prune_screenshot_history.swift) | Demonstrate age-based history pruning and disk cleanup | `HistoryRetention`, `HistoryLimit` |
| [`extract_artwork_colors.swift`](extract_artwork_colors.swift) | Extract dominant palette colors via RGB quantization | `ArtworkPaletteService` |
| [`measure_euclidean_distance.swift`](measure_euclidean_distance.swift) | On-screen pixel distance and dimension guide calculation | `MeasurementService` |
| [`query_screencapture_defaults.swift`](query_screencapture_defaults.swift) | Inspect macOS system screenshot preferences via CFPreferences | System Defaults |
| [`parse_smart_data_ocr.swift`](parse_smart_data_ocr.swift) | Parse URLs, email addresses, and phone numbers from OCR | `OCRService`, `NSDataDetector` |
| [`generate_color_swatches.swift`](generate_color_swatches.swift) | Render ANSI and hex preview color swatches | `ColorFormat` |
| [`format_byte_sizes.swift`](format_byte_sizes.swift) | Human-readable byte formatting across file and memory styles | `ScreenshotItem` |
| [`simulate_notch_transitions.swift`](simulate_notch_transitions.swift) | ClipNotch state machine lifecycle and interruption handling | `ClipNotchState` |
| [`inspect_display_topology.swift`](inspect_display_topology.swift) | Enumerate connected displays, backing scale, and safe insets | `DisplayTrackingService` |
| [`test_log_rotation.swift`](test_log_rotation.swift) | Rotating file log simulation and size-based archiving | `AppLogger` |
| [`convert_image_formats.swift`](convert_image_formats.swift) | Encode bitmaps between PNG, JPEG, and TIFF representations | `ImageUtils` |
| [`calculate_aspect_ratio.swift`](calculate_aspect_ratio.swift) | Compute display and capture aspect ratios via GCD math | Aspect Ratio & Dimensions |
| [`simulate_pixel_nudge.swift`](simulate_pixel_nudge.swift) | Demonstrate keyboard arrow micro/macro nudging and edge clamping | Selection Overlay |
| [`extract_image_dpi.swift`](extract_image_dpi.swift) | Query ImageIO DPI properties and Retina backing scale factors | `ImageIO`, Resolution |
| [`simulate_clipboard_types.swift`](simulate_clipboard_types.swift) | Inspect NSPasteboard UTI hierarchies and privacy filters | `ClipboardHistoryManager` |
| [`format_relative_timestamp.swift`](format_relative_timestamp.swift) | Humanized relative time formatting for recent capture shelves | `ScreenshotItem` |
| [`verify_fsevents_latency.swift`](verify_fsevents_latency.swift) | Measure filesystem change notification and attribute check latency | `ScreenshotMonitor` |
| [`calculate_color_contrast.swift`](calculate_color_contrast.swift) | Compute WCAG 2.1 relative luminance and contrast ratios | Accessibility & Contrast |
| [`inspect_window_layers.swift`](inspect_window_layers.swift) | Inspect CoreGraphics window levels used across ClipShot panels | Window Management |
| [`generate_test_pattern.swift`](generate_test_pattern.swift) | Generate in-memory diagnostic grid test patterns with CoreGraphics | Diagnostics & Rendering |
| [`parse_hex_color_variants.swift`](parse_hex_color_variants.swift) | Parse and normalize 3-digit, 6-digit, and 8-digit hex colors | `ColorPickerService` |
| [`detect_localized_screenshots.swift`](detect_localized_screenshots.swift) | Multi-language regex matching across 11 macOS localization patterns | `ScreenshotDetector` |
| [`calculate_memory_budget.swift`](calculate_memory_budget.swift) | Uncompressed raster memory budget calculator across Retina/Pro displays | Memory & Buffers |
| [`simulate_spring_physics.swift`](simulate_spring_physics.swift) | Harmonic oscillator spring physics and critically damped settling simulator | `ClipNotchPanel` Motion |
| [`inspect_display_gamut.swift`](inspect_display_gamut.swift) | Display P3 vs sRGB color primaries, chromaticity, and volume | Color Fidelity |
| [`benchmark_regex_matching.swift`](benchmark_regex_matching.swift) | Benchmark precompiled vs on-the-fly regex matching speedup | Performance & FSEvents |
| [`simulate_key_debounce.swift`](simulate_key_debounce.swift) | Event burst debouncing and sliding cache duplicate suppression | `ScreenshotProcessor` |
| [`format_duration_string.swift`](format_duration_string.swift) | Screen recording duration formatting and boundary validation | `ScreenRecordingEngine` |
| [`calculate_pixel_density.swift`](calculate_pixel_density.swift) | Mac display PPI, physical diagonal, and Retina scale factors | Retina Coordinate Math |
| [`inspect_pasteboard_flavors.swift`](inspect_pasteboard_flavors.swift) | Multi-flavor NSPasteboard item inspection and consumer extraction | `ClipboardManager` |
| [`simulate_color_quantization.swift`](simulate_color_quantization.swift) | Uniform box color quantization and dominant centroid extraction | Palette Extraction |
| [`calculate_retina_point_grid.swift`](calculate_retina_point_grid.swift) | Retina subpixel point grid snapping and hairline alignment calculator | Retina & Geometry |
| [`benchmark_string_drawing_cache.swift`](benchmark_string_drawing_cache.swift) | Dimension string measurement caching and layout benchmark | UI Performance |
| [`simulate_history_lru_eviction.swift`](simulate_history_lru_eviction.swift) | Screenshot history LRU thumbnail buffer eviction simulation | Cache & Memory |
| [`inspect_color_luminance_thresholds.swift`](inspect_color_luminance_thresholds.swift) | WCAG 2.1 relative luminance and contrast ratio analyzer | Accessibility |
| [`simulate_notch_autocollapse.swift`](simulate_notch_autocollapse.swift) | ClipNotch auto-collapse state machine and timer cooldown simulation | `ClipNotch` Interactions |
| [`format_exif_timestamp.swift`](format_exif_timestamp.swift) | EXIF and TIFF timestamp normalization and ISO-8601 formatting | Metadata & ImageIO |
| [`simulate_bitmap_crop_bounds.swift`](simulate_bitmap_crop_bounds.swift) | Boundary-safe bitmap cropping math and scale transformation | Image Processing |
| [`benchmark_imageio_thumbnail.swift`](benchmark_imageio_thumbnail.swift) | Hardware-accelerated ImageIO thumbnail downsampling benchmark | `ImageIO`, Performance |

---

## Executing Examples

All scripts in this directory are self-contained executable Swift scripts using `#!/usr/bin/env swift`. Run them from the repository root:

```bash
swift Examples/calculate_retina_point_grid.swift
swift Examples/benchmark_string_drawing_cache.swift
swift Examples/simulate_history_lru_eviction.swift
swift Examples/inspect_color_luminance_thresholds.swift
swift Examples/simulate_notch_autocollapse.swift
swift Examples/format_exif_timestamp.swift
swift Examples/simulate_bitmap_crop_bounds.swift
```

To validate all 41 examples in sequence:
```bash
for script in Examples/*.swift; do
    swift "$script" > /dev/null || exit 1
done
```

