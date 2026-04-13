#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/.build/xcode"
APP="$PROJECT_DIR/Auris.app"

CONFIG="Release"
ICON_MAX_SIZE=""
BUILD_DMG=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --debug) CONFIG="Debug"; shift ;;
        --dmg) BUILD_DMG=true; shift ;;
        --icon-max-size) ICON_MAX_SIZE="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

if [ ! -d "$PROJECT_DIR/Frameworks/CWhisper.xcframework" ]; then
    echo "==> CWhisper.xcframework not found. Building whisper.cpp..."
    "$PROJECT_DIR/scripts/build-whisper-framework.sh"
fi

echo "==> Building with xcodebuild ($CONFIG)..."
xcodebuild -scheme Auris -destination 'platform=macOS' -derivedDataPath "$BUILD_DIR" \
    -configuration "$CONFIG" -quiet

PRODUCTS="$BUILD_DIR/Build/Products/$CONFIG"

if [ ! -f "$PRODUCTS/Auris" ]; then
    echo "ERROR: Binary not found at $PRODUCTS/Auris"
    exit 1
fi

echo "==> Assembling Auris.app..."
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources/Assets.xcassets"

cp "$PRODUCTS/Auris" "$APP/Contents/MacOS/Auris"

if [ -f "$PROJECT_DIR/Resources/icon.icns" ]; then
    if [ -n "$ICON_MAX_SIZE" ]; then
        echo "==> Rebuilding icon.icns with max size ${ICON_MAX_SIZE}x${ICON_MAX_SIZE}..."
        ICONSET=$(mktemp -d)/icon.iconset
        mkdir -p "$ICONSET"
        SRC="$PROJECT_DIR/Resources/icon.png"
        SIZES="16 32 128 256 512"
        for S in $SIZES; do
            if [ "$S" -le "$ICON_MAX_SIZE" ]; then
                sips -z "$S" "$S" "$SRC" --out "$ICONSET/icon_${S}x${S}.png" >/dev/null
                RETINA=$((S * 2))
                if [ "$RETINA" -le "$ICON_MAX_SIZE" ]; then
                    sips -z "$RETINA" "$RETINA" "$SRC" --out "$ICONSET/icon_${S}x${S}@2x.png" >/dev/null
                fi
            fi
        done
        iconutil -c icns "$ICONSET" -o "$PROJECT_DIR/Resources/icon.icns"
        rm -rf "$(dirname "$ICONSET")"
    fi
    cp "$PROJECT_DIR/Resources/icon.icns" "$APP/Contents/Resources/icon.icns"
fi

if [ -f "$PROJECT_DIR/Resources/54x54.png" ]; then
    cp "$PROJECT_DIR/Resources/54x54.png" "$APP/Contents/Resources/54x54.png"
fi

cat > "$APP/Contents/Info.plist" << 'EOF'
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
EOF

cat > "$APP/Contents/Resources/Assets.xcassets/Contents.json" << 'EOF'
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

for bundle in "$PRODUCTS"/*.bundle; do
    [ -d "$bundle" ] || continue
    name=$(basename "$bundle")
    cp -R "$bundle" "$APP/Contents/Resources/$name"
    echo "    bundled $name"
done

mkdir -p "$APP/Contents/Frameworks"
if [ -d "$PROJECT_DIR/Frameworks/CWhisper.xcframework/macos-arm64" ]; then
    cp -R "$PROJECT_DIR/Frameworks/CWhisper.xcframework/macos-arm64/CWhisper.framework" "$APP/Contents/Frameworks/"
    echo "    embedded CWhisper.framework"
fi

echo "==> Adding rpath for embedded frameworks..."
install_name_tool -add_rpath "@executable_path/../Frameworks" "$APP/Contents/MacOS/Auris"

echo "==> Code signing..."
codesign --deep --force --sign - "$APP"

if [ "$BUILD_DMG" = true ]; then
    echo "==> Creating DMG..."
    STAGING=$(mktemp -d)
    cp -R "$APP" "$STAGING/"
    ln -s /Applications "$STAGING/Applications"
    hdiutil create -volname "Auris" -srcfolder "$STAGING" -ov -format UDZO "$PROJECT_DIR/Auris.dmg"
    rm -rf "$STAGING"
    echo "==> Done: $PROJECT_DIR/Auris.dmg"
else
    echo "==> Done: $APP"
fi
