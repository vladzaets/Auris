# AGENTS.md

## Project

macOS menu bar dictation app. Hold Fn (or Right Option / Right Command) → record → release → transcribe (whisper.cpp via CWhisper XCFramework) → auto-paste. Apple Silicon only, fully on-device. Written in Swift using AppKit.

## Build

**Important:** Before building, the CWhisper XCFramework must be present. Run the build script once to generate it:

```bash
./scripts/build-whisper-framework.sh
```

This builds whisper.cpp from `../whisper.cpp` with Metal support (`GGML_METAL=ON`, `GGML_METAL_EMBED_LIBRARY=ON`) and creates `Frameworks/CWhisper.xcframework`. The Metal shaders are embedded in the library, so no separate .metallib file is needed at runtime.

**Note:** The LSP / SourceKit will report `No such module 'CWhisper'` errors in `WhisperEngineWrapper.swift` and other files that `import CWhisper`. This is expected — the XCFramework is not on SourceKit's framework search path. The project compiles fine via `xcodebuild`. Ignore these LSP diagnostics; do not attempt to "fix" them.

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

No CLI arguments. Change settings via menu bar or `~/.auris/settings.json`.

## Architecture

- Local dependency on [whisper.cpp](https://github.com/ggerganov/whisper.cpp) (`../whisper.cpp`), built as CWhisper XCFramework with Metal support
- Minimum macOS 15.4
- Settings stored in `~/.auris/settings.json` (migrated from UserDefaults on first launch)
- Menu-bar only app (LSUIElement=true, no Dock icon)

### Threading Model

```
Main Thread (AppKit run loop, @MainActor)
  ├── Menu bar UI (NSStatusItem + NSMenu)
  ├── TranscriptionPipeline state machine (idle → recording → transcribing → idle)
  └── WhisperEngineWrapper (async/await transcription)

Hotkey Thread (dedicated Thread, CGEventTap)
  └── Detects Fn/Right Option/Right Command press/release
      → dispatches to @MainActor via Task { @MainActor in ... }
```

All UI work and transcription coordination happens on `@MainActor`. The hotkey thread communicates back to the main actor via `Task { @MainActor }` blocks. No shared mutable state outside actor isolation.

### Data Flow

1. User holds hotkey → HotkeyManager dispatches `handleHotkeyStart()` on @MainActor
2. AppDelegate calls `pipeline.startRecording()` → AudioRecorder captures to temp WAV
3. User releases hotkey → HotkeyManager dispatches `handleHotkeyStop()` on @MainActor
4. AppDelegate calls `pipeline.stopRecording()` → stops recorder, enters transcribing state
5. Pipeline spawns async task: transcribe via WhisperEngineWrapper → strip hallucination loops → remove filler words → apply vocabulary corrections
6. Result dispatched to AppDelegate → TextInjector pastes via clipboard + Cmd+V

### Backend Interface

`WhisperEngineWrapper` wraps whisper.cpp via the CWhisper XCFramework. It handles model downloading (from Hugging Face), loading/unloading, language mapping, and transcription. Models are cached in `~/.auris/models/` and downloaded on first use.

## Package Layout

```
Sources/Auris/
  App.swift               # @main entry point, NSApplication setup
  AppDelegate.swift       # Menu bar UI, hotkey dispatch, state updates
  Settings.swift           # StoredSettings (Codable), Settings singleton, UserDefaults migration
  AppConstants.swift       # File paths (~/.auris/*)
  AudioRecorder.swift      # Mic capture via AVAudioEngine, WAV export
  TranscriptionPipeline.swift  # State machine: idle/recording/transcribing/downloading
  WhisperEngineWrapper.swift    # whisper.cpp backend wrapper
  TextCleaner.swift        # Hallucination loop detection, filler word removal
  PostProcessor.swift      # Regex vocabulary corrections from corrections.txt
  Vocabulary.swift         # Domain vocabulary dictionaries
  TextInjector.swift       # Paste via clipboard + Cmd+V (CGEvent key press)
  HotkeyManager.swift      # Fn/Right Option/Right Command via CGEventTap
  SoundPlayer.swift        # macOS system sound playback
  Permissions.swift        # Accessibility/Mic/Input Monitoring checks
  Autostart.swift           # Login item via SMAppService (macOS 13+)
  TranscriptionLog.swift   # JSONL logging
  TranscriptionsViewer.swift  # History window (NSWindow + NSTableView)
  UpdateChecker.swift      # GitHub release check, version comparison
  UpdateAvailableWindow.swift # Update notification window (Download/Skip/Remind)
Resources/
  icon.icns                # App icon
  icon.png                 # App icon source
  54x54.png                # Menu bar icon
```

## Configuration

All settings live in `Settings.swift` as `StoredSettings` (Codable struct). Persistence is automatic to `~/.auris/settings.json`.

Access via `Settings.shared` singleton. Properties are typed (enums `WhisperModel`, `AppLanguage`, `RecordingHotkey`).

| Setting | Default | Description |
|---|---|---|
| `whisperModel` | `large-v3-turbo` | Whisper model size (small/medium/large-v3/large-v3-turbo) |
| `language` | `en` | Language code for transcription (16 languages) |
| `recordingHotkey` | `fn` | Push-to-talk key (fn/right_option/right_command) |
| `postProcessingEnabled` | `true` | Enable vocabulary corrections |
| `initialPromptEnabled` | `true` | Enable initial prompt for transcription |
| `collectTrainingData` | `true` | Save audio/transcript pairs |
| `soundStart/Stop/Complete/Error` | `Pop`/`Basso`/`Hero`/`Basso` | System sounds for events |
| `pasteDelaySeconds` | `0.05` | Delay before Cmd+V |
| `clipboardRestoreDelaySeconds` | `0.2` | Delay before clipboard restore |
| `historyRetentionDays` | `30` | Days to keep transcription history (0 = forever) |
| `startAtLogin` | `false` | Launch at login via SMAppService |
| `checkForUpdatesEnabled` | `true` | Auto-check for updates on launch |
| `skippedVersion` | `nil` | Version to skip in auto-update notifications |

## Testing

No formal test suite. Manual testing via the app itself.

## Conventions

- Swift 6.1 with strict concurrency (`@MainActor`, `Sendable`, `@unchecked Sendable` where needed)
- Each file = one responsibility
- `os_log` / `Logger` for logging (not `print`)
- Error handling: do/catch at boundaries, `NSAlert` for user-facing errors
- No third-party dependencies beyond CWhisper (local XCFramework)
- Settings singleton: `Settings.shared` — read directly, set triggers automatic save
- **Keep AGENTS.md up to date:** when you change architecture, dependencies, file layout, settings, or any substantial aspect of the project, update this file accordingly

## macOS Permissions

The app requires three permissions:
- **Accessibility** — to paste text into the focused app (CGEvent key press for Cmd+V)
- **Microphone** — to record audio (AVAudioEngine)
- **Input Monitoring** — to detect hotkey press/release (CGEventTap)

Permissions are checked via `Permissions.swift`. The app prompts on first launch. If permissions break after changes, remove from System Settings → Privacy & Security and re-add.

## Release Process

1. **Update version** in `VERSION` file (e.g. `1.1.0`)
2. **Build .app and DMG:**
   ```bash
   ./build.sh --dmg
   ```
   Output: `Auris.app` and `Auris-VERSION.dmg` in project root
3. **Create zip for Homebrew** (must use `-y` to preserve symlinks in frameworks):
   ```bash
   zip -r -y Auris-VERSION.zip Auris.app
   ```
4. **Compute sha256:**
   ```bash
   shasum -a 256 Auris-VERSION.zip
   ```
5. **Create GitHub release and upload assets:**
   ```bash
   gh release create vVERSION Auris-VERSION.dmg Auris-VERSION.zip \
     --repo vladzaets/auris --title "vVERSION" --notes "Release vVERSION"
   ```
6. **Update Homebrew tap** (`../homebrew-auris`):
   - Edit `Casks/auris.rb`: update `version` and `sha256`
   - Commit and push:
     ```bash
     git add -A && git commit -m "Bump to VERSION" && git push
     ```
7. **Commit version bump** in this repo (if not already committed)

## User Data

All in `~/.auris/`: `settings.json`, `transcriptions.jsonl`, `corrections.txt`, `prompt_terms.txt`.
