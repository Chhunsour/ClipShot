# Multilingual Localization Workflow & RTL Guidelines

ClipShot is designed for global macOS users, supporting dynamic language adaptation, Apple String Catalogs (`.xcstrings`), and Right-to-Left (RTL) writing systems.

---

## 1. String Catalogs Architecture

All user-visible strings are declared through SwiftUI's `LocalizedStringKey` and managed via Xcode String Catalogs:

```swift
Text("Settings", comment: "Main title for preferences window")
Text("Copy to Clipboard", comment: "Primary capture action button")
```

### Supported Languages
1. **English (en)**: Development baseline.
2. **French (fr)**: Français.
3. **German (de)**: Deutsch.
4. **Japanese (ja)**: 日本語.
5. **Simplified Chinese (zh-Hans)**: 简体中文.
6. **Traditional Chinese (zh-Hant)**: 繁體中文.
7. **Spanish (es)**: Español.
8. **Arabic (ar)**: العربية (Right-to-Left).
9. **Hebrew (he)**: עברית (Right-to-Left).

---

## 2. Right-to-Left (RTL) Considerations

When running in Arabic or Hebrew macOS system environments:
- **Layout Mirroring**: Horizontal stacks (`HStack`) automatically reverse element ordering according to the layout direction environment variable (`\.layoutDirection`).
- **Icons & Symbols**: Direction-sensitive SF Symbols (such as `arrow.forward`, `chevron.right`, and playback controls) must use directional variants or `flipsForRightToLeftLayoutDirection(true)`.
- **Coordinate Systems**: Display notch coordinates (`screenFrame.midX`) remain symmetrical, ensuring ClipNotch remains horizontally centered regardless of layout direction.

---

## 3. Pluralization & Grammatical Agreement

String catalogs utilize Apple's modern plural rule tables (`zero`, `one`, `other`, `many`) to avoid awkward phrasing:

```swift
// Example: History item count
Text("^[\(count) screenshot](inflect: true)")
```

This ensures proper grammatical agreement across languages with complex plural forms (such as Polish, Russian, and Arabic).

---

## 4. Contributing Translations

To contribute a new language translation:
1. Open the `.xcstrings` catalog file in Xcode or any standard JSON editor.
2. Add the ISO 639-1 language code.
3. Translate keys without modifying interpolation markers (`%@`, `%d`, `%lf`).
4. Validate visual layouts in Xcode Previews using the `.environment(\.locale, Locale(identifier: "xx"))` modifier.
