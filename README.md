<div align="center">

# Auris

<img src="Resources/icon.png" alt="Auris icon" width="250">

</div></br>
A native macOS menu bar dictation tool that runs entirely on-device. Hold the **Fn** key to record, release to transcribe and paste into any app.

No cloud services, no subscriptions, no data leaves your Mac.

## Features

- **Native Swift app** — built with AppKit, no Python runtime or external dependencies
- **Menu bar icon** — lives quietly in your menu bar
- **Push-to-talk dictation** via Fn, Right Option (⌥), or Right Command (⌘) key
- **MLX Whisper backend** — Apple Silicon GPU-accelerated, 4 model sizes
- **Live model/language switching** from the menu bar (no restart needed)
- **Post-processing pipeline:**
  - Hallucination loop detection and removal
  - Filler word removal (um, uh, you know, etc.)
  - Vocabulary corrections via user-editable files
- **Transcription history** viewer with copy support
- **Paste Last Transcription** — re-inject the last result into any app
- **16 languages** supported

## Quick Start

### Option 1: Build from source

**Prerequisites:** Xcode 16+, macOS 15.4+, Apple Silicon Mac

```bash
git clone https://github.com/vladzaets/Auris.git
cd Auris
./build.sh
```

This builds `Auris.app` in the project root. Drag it to Applications and launch.

### Option 2: Download

Download the latest release from [Releases](https://github.com/vladzaets/Auris/releases), drag Auris to Applications, and launch it.

> **First launch:** macOS will ask for **Microphone**, **Accessibility**, and **Input Monitoring** permissions. Grant all three — the app needs the microphone to record, Accessibility to paste text into other apps, and Input Monitoring to detect the hotkey.

### Usage

Look for the microphone icon in your menu bar:

1. **Hold Fn** (or Right Option / Right Command) to start recording (recording indicator appears)
2. **Release** to stop and transcribe
3. Text is automatically pasted into the focused app

## Troubleshooting

**If the app doesn't work** (hotkey not detected, text not pasted), macOS may have cached incorrect permissions. To fix:

1. Open **System Settings → Privacy & Security**
2. Remove Auris from permission lists (Accessibility, Input Monitoring)
3. Re-add it separately to **each** permission by drag and drop app file from **Applications** directory.
4. Restart the app.

## Requirements

- macOS 15.4+ (Sequoia or later)
- Apple Silicon Mac (M1/M2/M3/M4)

## License

MIT License with Commons Clause — see [LICENSE](LICENSE).
