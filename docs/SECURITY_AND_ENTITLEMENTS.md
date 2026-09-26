# Security, Sandboxing, and Entitlements

ClipShot is designed with a strict **local-first, privacy-respecting architecture**. It has no backend servers, performs no cloud tracking, and transmits zero user imagery or telemetry over the network.

---

## Privacy Principles

1. **Zero Network Egress**: ClipShot never uploads your screenshots, OCR extractions, clipboard contents, or system metrics anywhere.
2. **On-Device Machine Learning**: Text recognition (OCR) runs completely on your Apple Neural Engine / GPU via Apple VisionKit and CoreML.
3. **Transient Memory Processing**: Pixels copied directly to the clipboard or pinned on-screen reside solely in macOS RAM unless saved to disk by your designated screenshot folder.
4. **Transparent Permissions**: Every system capability used by ClipShot requires explicit user authorization through standard macOS Transparency, Consent, and Control (TCC) dialogs.

---

## Required Entitlements & Permissions

| Entitlement / Permission | Purpose | macOS Setting Location |
| :--- | :--- | :--- |
| **Screen Recording** | Capturing display pixels for area, window, and full-screen screenshots | `System Settings > Privacy & Security > Screen Recording` |
| **Files and Folders** | Reading incoming screenshot image files and preserving annotated exports | `System Settings > Privacy & Security > Files and Folders` |
| **User Notifications** | Delivering banners when screenshots are detected or copied | `System Settings > Notifications > ClipShot` |
| **Accessibility** *(Optional)* | Global hotkey registration and active window coordinate detection | `System Settings > Privacy & Security > Accessibility` |
| **Apple Events** *(Optional)* | Reading playback state from Music or Spotify for ClipNotch media controls | `System Settings > Privacy & Security > Automation` |

---

## Hardened Runtime & Notarization

When compiling ClipShot for release distribution outside the Mac App Store:

- **Code Signing**: Binaries are signed using an Apple Developer ID Application certificate.
- **Hardened Runtime (`--options runtime`)**: Enforces macOS integrity protections against code injection, memory patching, and dynamic library hijacking.
- **Notarization (`notarytool`)**: Submitted to Apple's automated notary service to verify the absence of malicious code and attach an Apple cryptographic ticket.

---

## Security-Scoped Bookmarks

When users select custom storage folders (via `PathUtils.saveBookmark(for:)`), ClipShot stores persistent access tokens using macOS Security-Scoped Bookmarks (`URL.bookmarkData(options: .withSecurityScope, ...)`). This ensures:
- Access survives application relaunches without asking repeatedly.
- The app only accesses directories explicitly designated by the user.
- Sandboxed containers cannot access arbitrary user home directories.
