# Localization & Internationalization Guide

ClipShot is configured with English (`en`) as its base development language and welcomes community localizations for global macOS users.

---

## 🌐 Architecture Overview

- **Default Localization**: Declared in `Package.swift` via `defaultLocalization: "en"`.
- **String Catalogs**: Modern SwiftUI string lookups and `NSLocalizedString` keys.
- **Dynamic Formatting**: Number, date, and dimension formatting uses system `Locale.current` and Apple's `Measurement` APIs to respect regional standards (e.g. 12-hour vs 24-hour clocks, metric vs imperial dimensions).

---

## 🛠️ Adding a New Language

To contribute a new language translation:

1. **Create the Language Directory**:
   Inside `Sources/ClipShotApp/Resources/`, create `<language-code>.lproj` (e.g. `fr.lproj`, `ja.lproj`, `de.lproj`, `km.lproj`).
2. **Translate Core Strings**:
   Add `Localizable.strings` containing translated pairs for:
   - Menu bar titles and tooltips.
   - Capture overlay instructions.
   - Command palette labels.
   - Preferences tabs and options.
3. **Test with Different Locales**:
   Run ClipShot from the terminal with the AppleLanguages argument:
   ```bash
   swift run ClipShot -AppleLanguages "(fr)"
   ```
4. **Submit a Pull Request**:
   Follow the [Contributing Guidelines](CONTRIBUTING.md) to open a PR.
