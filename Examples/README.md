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

---

## Executing Examples

All scripts in this directory are self-contained executable Swift scripts. Run them from the command line:

```bash
swift Examples/detect_screenshot_folder.swift
swift Examples/extract_artwork_colors.swift
swift Examples/measure_euclidean_distance.swift
swift Examples/query_screencapture_defaults.swift
swift Examples/parse_smart_data_ocr.swift
swift Examples/generate_color_swatches.swift
swift Examples/format_byte_sizes.swift
swift Examples/simulate_notch_transitions.swift
swift Examples/inspect_display_topology.swift
swift Examples/test_log_rotation.swift
swift Examples/convert_image_formats.swift
```
