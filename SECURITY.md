# Security Policy

## Supported Versions

ClipShot is actively maintained. Security patches and fixes are provided for the latest release on macOS 14.0+ (Sonoma and Sequoia).

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

---

## 🔒 Security & Privacy Model

ClipShot is engineered around strict local-first privacy:
- **Zero Network Transmission**: ClipShot contains zero network code, analytics libraries, telemetry, crash reporting services, or cloud tracking. No data, screenshots, or metadata ever leave your computer.
- **On-Device Neural Processing**: Text recognition (OCR) executes entirely on Apple Silicon / local CPU via Apple's native `Vision.framework`.
- **Security-Scoped Bookmarks**: ClipShot uses AppKit security-scoped bookmarks to access only user-specified directories (e.g. Desktop or custom screenshot directories).
- **Clipboard Isolation**: Pasteboard writes use standard `NSPasteboard` APIs and do not persist outside your system's pasteboard buffer.

---

## 🛡️ Reporting a Vulnerability

If you discover a security vulnerability or potential privacy issue in ClipShot:

1. **Please do NOT report security vulnerabilities via public GitHub issues.**
2. Send a report via GitHub Private Vulnerability Reporting or email the maintainer directly at: `sengchhunsour@gmail.com`.
3. Include detailed reproduction steps, macOS version, and impact assessment.
4. You will receive an acknowledgment within 48 hours, followed by updates as the issue is investigated and patched.
