# macOS Code Signing, Hardened Runtime & Notarization

To run cleanly on macOS without Gatekeeper security warnings or quarantine blocks, native macOS applications must be signed with an Apple Developer ID certificate, opt into Hardened Runtime, and receive a cryptographically stapled notarization ticket from Apple's automated notary service.

---

## 1. Security Architecture Pipeline

```
[ Swift Compiler ]
       ↓
[ codesign --options runtime ]  (Hardened Runtime + Entitlements)
       ↓
[ ditto -c -k (ZIP Archive) ]
       ↓
[ xcrun notarytool submit ]     (Apple Cloud Validation)
       ↓
[ xcrun stapler staple ]        (Attach Offline Verification Ticket)
```

---

## 2. Hardened Runtime & Required Entitlements

Hardened Runtime mitigates memory corruption and code injection vulnerabilities. Any exception to default sandbox restrictions must be declared explicitly in `ClipShot.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Screen Recording entitlement handled at runtime via TCC -->
    <!-- Audio input access for microphone recording during screen captures -->
    <key>com.apple.security.device.audio-input</key>
    <true/>
    
    <!-- User selected files read/write access -->
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    
    <!-- Disable library validation for third-party audio plugin compatibility if needed -->
    <key>com.apple.security.cs.disable-library-validation</key>
    <false/>
</dict>
</plist>
```

---

## 3. Signing Command Line Workflow

```bash
# 1. Sign embedded frameworks and binaries from inside out
codesign --force --options runtime --timestamp \
  --sign "Developer ID Application: Your Name (TEAMID)" \
  --entitlements ClipShot.entitlements \
  ClipShot.app

# 2. Strict signature verification
codesign --verify --deep --strict --verbose=2 ClipShot.app

# 3. Assess Gatekeeper compliance
spctl --assess --type execute --verbose ClipShot.app
```

---

## 4. Notarization with `notarytool`

Apple deprecated legacy `altool` in favor of `notarytool`:

```bash
# 1. Compress app bundle into zip
ditto -c -k --keepParent ClipShot.app ClipShot.zip

# 2. Submit to Apple Notary Service
xcrun notarytool submit ClipShot.zip \
  --keychain-profile "AC_PASSWORD" \
  --wait

# 3. Staple notarization ticket directly to app bundle
xcrun stapler staple ClipShot.app

# 4. Verify stapled status
xcrun stapler validate ClipShot.app
```

Once stapled, the application can launch completely offline on any Mac running macOS Gatekeeper with zero untrusted developer warnings.
