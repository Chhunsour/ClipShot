#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "==> Building ClipShot (Release)..."
cd "$PROJECT_ROOT"
swift build -c release

RELEASE_BIN="$PROJECT_ROOT/.build/release/ClipShot"
OUTPUT_DIR="$PROJECT_ROOT/build/Release"
APP_BUNDLE="$OUTPUT_DIR/ClipShot.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "==> Creating .app bundle structure..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

echo "==> Copying executable..."
cp "$RELEASE_BIN" "$MACOS_DIR/ClipShot"
chmod +x "$MACOS_DIR/ClipShot"

echo "==> Copying Info.plist..."
cp "$PROJECT_ROOT/Sources/ClipShotApp/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"

echo "==> Writing PkgInfo..."
echo -n "APPLCSHT" > "$CONTENTS_DIR/PkgInfo"

echo "==> Copying AppIcon..."
if [ -f "$PROJECT_ROOT/Sources/ClipShotApp/Resources/AppIcon.icns" ]; then
    cp "$PROJECT_ROOT/Sources/ClipShotApp/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

SIGN_IDENTITY="${CLIPSHOT_SIGN_IDENTITY:-$(security find-identity -v -p codesigning | awk -F '"' '/^[[:space:]]*[0-9]+\)/ { print $2; exit }')}"
if [ -n "$SIGN_IDENTITY" ] && security find-identity -v -p codesigning | rg -Fq "\"$SIGN_IDENTITY\""; then
    echo "==> Signing ClipShot.app with stable identity..."
else
    echo "==> Stable identity unavailable; using ad-hoc signing..."
    SIGN_IDENTITY="-"
fi
codesign --force --deep --sign "$SIGN_IDENTITY" "$APP_BUNDLE"

echo "==> Verifying code signature..."
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

echo "==> Build succeeded: $APP_BUNDLE"
