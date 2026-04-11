#!/bin/bash
set -euo pipefail

APP_NAME="Auris"
BUNDLE_ID="com.vladz.auris"
APP_DIR="${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
BUILD_DIR=".build/release"

echo "==> Building ${APP_NAME}..."
swift build -c release

echo "==> Creating .app bundle..."
rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

echo "==> Copying binary..."
cp "${BUILD_DIR}/${APP_NAME}" "${MACOS_DIR}/${APP_NAME}"
chmod +x "${MACOS_DIR}/${APP_NAME}"

echo "==> Creating Info.plist..."
cat > "${CONTENTS_DIR}/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>Auris</string>
    <key>CFBundleIconFile</key>
    <string>icon</string>
    <key>CFBundleIdentifier</key>
    <string>com.vladz.auris</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Auris</string>
    <key>CFBundleDisplayName</key>
    <string>Auris</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>15.4</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSMicrophoneUsageDescription</key>
    <string>Auris needs microphone access for speech transcription.</string>
    <key>NSAccessibilityUsageDescription</key>
    <string>Auris needs accessibility access to paste transcribed text into the active application.</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>Auris needs Apple Events access for text injection.</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo "==> Copying resources..."
if [ -f "Resources/icon.icns" ]; then
    cp "Resources/icon.icns" "${RESOURCES_DIR}/icon.icns"
fi

echo "==> Creating minimal Assets.xcassets..."
ASSETS_DIR="${RESOURCES_DIR}/Assets.xcassets"
mkdir -p "${ASSETS_DIR}"
cat > "${ASSETS_DIR}/Contents.json" << 'JSON'
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
JSON

echo "==> Signing..."
codesign --deep --force --sign - "${APP_DIR}"

echo "==> Done: ${APP_DIR}"
echo "    Run: open ${APP_DIR}"
