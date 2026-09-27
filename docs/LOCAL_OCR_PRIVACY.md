# Local OCR & Privacy Architecture Guide

ClipShot provides instant optical character recognition (OCR) with strict, uncompromising privacy guarantees.

---

## 1. 100% On-Device Neural Processing

- **Framework**: Built exclusively on Apple's native `Vision` framework (`VNRecognizeTextRequest`).
- **Hardware Acceleration**: Executes directly on the Apple Neural Engine (ANE) on Apple Silicon and GPU/CPU on Intel Macs.
- **Zero Cloud Calls**: No network requests, API keys, or third-party servers are ever contacted.
- **Offline Capable**: Functions identically in airplane mode or air-gapped secure environments.

---

## 2. Privacy Guarantees

### Zero Telemetry & Logging
As documented in `AppLogger.swift`:
> "Privacy-respecting diagnostic rotating file logger for ClipShot. Never logs image contents, file contents, or recognized OCR text."

Diagnostic logs record only timestamps and subsystem event statuses (`INFO`, `WARN`, `ERROR`), strictly omitting sensitive extracted content.

### Transient Processing
- Images sent to `OCRService` are processed in-memory.
- Extracted text strings are only stored if the user explicitly copies them to the clipboard or saves them via the OCR Result Window.

---

## 3. Recognition Accuracy & Language Correction

- **Recognition Level**: `.accurate` (utilizes deep learning models rather than fast heuristics).
- **Language Correction**: `usesLanguageCorrection = true` automatically resolves common OCR character ambiguities (e.g. `1` vs `l`, `0` vs `O`).
- **Multilingual Support**: Supports English, Spanish, French, German, Italian, Portuguese, Chinese, Japanese, and Korean.
