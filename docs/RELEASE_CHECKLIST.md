# Release Verification Checklist

This checklist ensures consistent build quality, test hygiene, security validation, and documentation accuracy prior to tagging a new release of ClipShot.

---

## 1. Automated Test Suite Validation

Before creating any release build, execute the complete unit and integration test suite:

```bash
# Run full package test suite
swift test

# Verify all standalone example scripts execute cleanly
for f in Examples/*.swift; do
    swift "$f" > /dev/null || exit 1
done
```

- [ ] All unit test targets pass with 0 unexpected failures.
- [ ] No regression warnings or memory leaks detected in test output.
- [ ] Vision OCR tests pass on target hardware.

---

## 2. Code Quality & Git Hygiene

- [ ] Clean working tree (`git status` reports working tree clean).
- [ ] Correct git author attribution (`Seng Chhunsour <195839568+Chhunsour@users.noreply.github.com>`).
- [ ] Accurate version numbers in `AppConfig.swift` and `Info.plist`.
- [ ] CHANGELOG.md updated with all notable improvements and bug fixes.

---

## 3. macOS Security & Notarization

- [ ] Entitlements file verified (`ClipShot.entitlements`).
- [ ] Hardened Runtime enabled for release configuration.
- [ ] Signed with valid Apple Developer ID Certificate.
- [ ] Apple Notarization ticket stapled to the application bundle.
