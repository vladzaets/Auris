#!/bin/bash
set -euo pipefail

WHISPER_CPP_DIR="${WHISPER_CPP_DIR:-../whisper.cpp}"
FRAMEWORK_DIR="$(cd "$(dirname "$0")/.." && pwd)/Frameworks"
BUILD_DIR="$(cd "$(dirname "$0")/.." && pwd)/.build/whisper-cpp"

MACOS_MIN_OS_VERSION="13.3"

echo "==> Building whisper.cpp for macOS arm64 (Metal + embedded shaders)..."
echo "    Source: $WHISPER_CPP_DIR"
echo "    Output: $FRAMEWORK_DIR"

if [ ! -d "$WHISPER_CPP_DIR/src" ]; then
    echo "ERROR: whisper.cpp not found at $WHISPER_CPP_DIR"
    echo "Set WHISPER_CPP_DIR to the whisper.cpp repository path."
    exit 1
fi

WHISPER_CPP_DIR="$(cd "$WHISPER_CPP_DIR" && pwd)"

cmake -B "$BUILD_DIR/build-macos" -G Xcode \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=$MACOS_MIN_OS_VERSION \
    -DCMAKE_OSX_ARCHITECTURES="arm64" \
    -DBUILD_SHARED_LIBS=OFF \
    -DWHISPER_BUILD_EXAMPLES=OFF \
    -DWHISPER_BUILD_TESTS=OFF \
    -DWHISPER_BUILD_SERVER=OFF \
    -DGGML_METAL=ON \
    -DGGML_METAL_EMBED_LIBRARY=ON \
    -DGGML_BLAS_DEFAULT=ON \
    -DGGML_METAL_USE_BF16=ON \
    -DGGML_NATIVE=OFF \
    -DGGML_OPENMP=OFF \
    -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED=NO \
    -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY="" \
    -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED=NO \
    -DCMAKE_C_FLAGS="-Wno-macro-redefined -Wno-shorten-64-to-32 -Wno-unused-command-line-argument" \
    -DCMAKE_CXX_FLAGS="-Wno-macro-redefined -Wno-shorten-64-to-32 -Wno-unused-command-line-argument" \
    -S "$WHISPER_CPP_DIR"

cmake --build "$BUILD_DIR/build-macos" --config Release -- -quiet

echo "==> Creating framework structure..."

PRODUCTS_DIR="$BUILD_DIR/build-macos/src/Release"
GGML_RELEASE="$BUILD_DIR/build-macos/ggml/src/Release"

if [ ! -f "$PRODUCTS_DIR/libwhisper.a" ]; then
    echo "ERROR: libwhisper.a not found at $PRODUCTS_DIR"
    find "$BUILD_DIR/build-macos" -name "libwhisper.a" 2>/dev/null || true
    exit 1
fi

FRAMEWORK_NAME="CWhisper"
FW="$BUILD_DIR/framework/$FRAMEWORK_NAME.framework"

rm -rf "$FW"
mkdir -p "$FW/Versions/A/Headers"
mkdir -p "$FW/Versions/A/Modules"
mkdir -p "$FW/Versions/A/Resources"

cp "$WHISPER_CPP_DIR/include/whisper.h"           "$FW/Versions/A/Headers/"
cp "$WHISPER_CPP_DIR/ggml/include/ggml.h"          "$FW/Versions/A/Headers/"
cp "$WHISPER_CPP_DIR/ggml/include/ggml-alloc.h"    "$FW/Versions/A/Headers/"
cp "$WHISPER_CPP_DIR/ggml/include/ggml-backend.h"  "$FW/Versions/A/Headers/"
cp "$WHISPER_CPP_DIR/ggml/include/ggml-cpu.h"      "$FW/Versions/A/Headers/"
cp "$WHISPER_CPP_DIR/ggml/include/ggml-metal.h"    "$FW/Versions/A/Headers/"
cp "$WHISPER_CPP_DIR/ggml/include/ggml-blas.h"     "$FW/Versions/A/Headers/"
cp "$WHISPER_CPP_DIR/ggml/include/gguf.h"          "$FW/Versions/A/Headers/"

cat > "$FW/Versions/A/Modules/module.modulemap" << 'EOF'
framework module CWhisper {
    header "whisper.h"
    header "ggml.h"
    header "ggml-alloc.h"
    header "ggml-backend.h"
    header "ggml-cpu.h"
    header "ggml-metal.h"
    header "ggml-blas.h"
    header "gguf.h"

    link "c++"
    link framework "Accelerate"
    link framework "Metal"
    link framework "Foundation"

    export *
}
EOF

cat > "$FW/Versions/A/Resources/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>CWhisper</string>
    <key>CFBundleIdentifier</key>
    <string>com.auris.cwhisper</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>CWhisper</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
</dict>
</plist>
EOF

ln -sf A "$FW/Versions/Current"
ln -sf Versions/Current/Headers   "$FW/Headers"
ln -sf Versions/Current/Modules   "$FW/Modules"
ln -sf Versions/Current/Resources "$FW/Resources"
ln -sf Versions/Current/CWhisper  "$FW/CWhisper"

echo "==> Creating dynamic library from static archives..."

find_lib() {
    local name="$1"
    local primary="$2"
    if [ -f "$primary" ]; then
        echo "$primary"
        return
    fi
    local alt
    alt=$(find "$BUILD_DIR/build-macos" -name "$name" -path "*/arm64/*" | head -1)
    if [ -n "$alt" ] && [ -f "$alt" ]; then
        echo "$alt"
        return
    fi
    alt=$(find "$BUILD_DIR/build-macos" -name "$name" | head -1)
    if [ -n "$alt" ] && [ -f "$alt" ]; then
        echo "$alt"
        return
    fi
    echo "ERROR: Could not find $name" >&2
    exit 1
}

WHISPER_LIB=$(find_lib "libwhisper.a" "$PRODUCTS_DIR/libwhisper.a")
GGML_LIB=$(find_lib "libggml.a" "$GGML_RELEASE/libggml.a")
GGML_BASE_LIB=$(find_lib "libggml-base.a" "$GGML_RELEASE/libggml-base.a")
GGML_CPU_LIB=$(find_lib "libggml-cpu.a" "$GGML_RELEASE/libggml-cpu.a")
GGML_METAL_LIB=$(find_lib "libggml-metal.a" "$BUILD_DIR/build-macos/ggml/src/ggml-metal/Release/libggml-metal.a")
GGML_BLAS_LIB=$(find_lib "libggml-blas.a" "$GGML_RELEASE/libggml-blas.a")

echo "    Using libraries:"
echo "      $WHISPER_LIB"
echo "      $GGML_LIB"
echo "      $GGML_BASE_LIB"
echo "      $GGML_CPU_LIB"
echo "      $GGML_METAL_LIB"
echo "      $GGML_BLAS_LIB"

TEMP_DIR="$BUILD_DIR/temp"
mkdir -p "$TEMP_DIR"

libtool -static -o "$TEMP_DIR/combined.a" \
    "$WHISPER_LIB" \
    "$GGML_LIB" \
    "$GGML_BASE_LIB" \
    "$GGML_CPU_LIB" \
    "$GGML_METAL_LIB" \
    "$GGML_BLAS_LIB" \
    2>/dev/null

xcrun -sdk macosx clang++ -dynamiclib \
    -isysroot $(xcrun --sdk macosx --show-sdk-path) \
    -arch arm64 \
    -mmacosx-version-min=$MACOS_MIN_OS_VERSION \
    -Wl,-force_load,"$TEMP_DIR/combined.a" \
    -framework Foundation -framework Metal -framework Accelerate \
    -install_name "@rpath/CWhisper.framework/Versions/Current/CWhisper" \
    -o "$FW/Versions/A/CWhisper"

rm -rf "$TEMP_DIR"

echo "==> Creating XCFramework..."

rm -rf "$FRAMEWORK_DIR/CWhisper.xcframework"

xcodebuild -create-xcframework \
    -framework "$FW" \
    -output "$FRAMEWORK_DIR/CWhisper.xcframework" \
    2>&1 | tail -5

echo "==> Done: $FRAMEWORK_DIR/CWhisper.xcframework"
