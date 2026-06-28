#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="卜卜桌面宠物"
EXECUTABLE_NAME="BuBuCarrotPet"
BUILD_DIR="$ROOT/Build"
APP_DIR="$BUILD_DIR/$EXECUTABLE_NAME.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

mkdir -p "$MACOS" "$RESOURCES"
printf 'APPL????' > "$CONTENTS/PkgInfo"

python3 - <<'PY'
try:
    import PIL  # noqa: F401
except ModuleNotFoundError:
    raise SystemExit("Missing dependency: Pillow. Install it with: python3 -m pip install Pillow")
PY

python3 "$ROOT/Scripts/prepare_assets.py"

cp "$ROOT"/Assets/carrot_*.png "$RESOURCES/"

export CLANG_MODULE_CACHE_PATH="$BUILD_DIR/ModuleCache"
mkdir -p "$CLANG_MODULE_CACHE_PATH"

/usr/bin/clang \
  -fobjc-arc \
  -fmodules \
  -mmacosx-version-min=13.0 \
  "$ROOT/Sources/main.m" \
  -framework Cocoa \
  -framework QuartzCore \
  -o "$MACOS/$EXECUTABLE_NAME"

cat > "$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$EXECUTABLE_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>com.local.bubu-carrot-pet</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

chmod +x "$MACOS/$EXECUTABLE_NAME"

echo "$APP_DIR"
