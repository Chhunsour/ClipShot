# Offline Apple Vision OCR Guide

ClipShot includes an embedded on-device Optical Character Recognition (OCR) engine powered by Apple's native `Vision.framework`.

---

## ⚡ Key Highlights

- **100% On-Device Processing**: Text recognition runs on the local Apple Neural Engine and CPU. No images or text are ever transmitted over the network.
- **Sub-100ms Latency**: Recognition initiates asynchronously off the main thread the moment an image or region is selected.
- **Code & Indentation Preservation**: Specialized whitespace recognition retains programming indentation, braces, and line breaks for code snippets.
- **Multi-Language Support**: Automatically detects Latin-script languages, Chinese, Japanese, Korean, and Cyrillic via Apple's Vision models.

---

## 🎯 How to Use OCR

### 1. From ClipNotch
When a screenshot is captured:
1. Hover or glance at the **ClipNotch** status capsule.
2. Click the **OCR** icon (`text.viewfinder`).
3. The extracted text is copied to your clipboard immediately, and an inspection sheet displays the recognized text with character and word counts.

### 2. From Screenshot History (`⌘ ⇧ H`)
1. Open the History window.
2. Select any past capture thumbnail.
3. Click the **Recognize Text** button in the detail view or press `⌘ C` to copy text directly.

### 3. From Command Palette (`⌥ Space`)
1. Open the Command Palette with `⌥ Space`.
2. Type `OCR` or select **OCR Last Screenshot**.
3. Text from the most recent capture is placed on your pasteboard in milliseconds.

---

## 🏗️ Technical Implementation

ClipShot configures `VNRecognizeTextRequest` with:
- `recognitionLevel = .accurate`: Prioritizes accuracy and punctuation fidelity.
- `usesCPUOnly = false`: Utilizes the Apple Neural Engine on Apple Silicon for maximum energy efficiency.
- `recognitionLanguages = ["en-US"]` (with system language fallback).

Text bounding boxes are parsed and sorted by vertical line offset, ensuring multi-column text and code blocks read in natural reading order.
