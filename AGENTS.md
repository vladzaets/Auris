# Project: Auris

## Build

**Important:** Do NOT use `swift build` — it does not compile Metal shaders (.metal → .metallib), causing a runtime crash:

```
MLX error: Failed to load the default metallib. library not found
```

### Quick build (bare binary)

```bash
xcodebuild -scheme Auris -destination 'platform=macOS' -derivedDataPath .build/xcode
```

Binary output: `.build/xcode/Build/Products/Debug/Auris`

### Build .app bundle

```bash
./build.sh
```

This runs xcodebuild, assembles `Auris.app` with all resource bundles (metallib, etc.), writes Info.plist, copies `icon.icns` (if present in project root), and code-signs. Output: `Auris.app` in project root.

## Architecture

- Swift Package Manager project with local dependency on `mlx-swift-audio` (`../mlx-swift-audio`)
- Depends on MLX (Apple's machine learning framework) which requires Metal GPU shaders
- Minimum macOS 15.4
- Settings stored in `~/.auris/settings.json` (migrated from UserDefaults on first launch)
- Menu-bar only app (LSUIElement=true, no Dock icon)
