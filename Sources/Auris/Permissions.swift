import AppKit
import AVFoundation
import Foundation

enum Permissions {
    static func checkAccessibility(prompt: Bool = false) -> Bool {
        let key = "AXTrustedCheckOptionPrompt" as CFString
        let dict = [key: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(dict)
    }

    static func triggerMicrophonePermission() {
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        guard format.sampleRate > 0 else { return }
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { _, _ in }
        do {
            try engine.start()
            engine.stop()
        } catch {
            engine.stop()
        }
        inputNode.removeTap(onBus: 0)
    }

    static func openAccessibilityPreferences() {
        openPrefs("Privacy_Accessibility")
    }

    static func openInputMonitoringPreferences() {
        openPrefs("Privacy_ListenEvent")
    }

    static func openMicrophonePreferences() {
        openPrefs("Privacy_Microphone")
    }

    private static func openPrefs(_ pane: String) {
        let urlStr = "x-apple.systempreferences:com.apple.preference.security?\(pane)"
        guard let url = URL(string: urlStr) else { return }
        NSWorkspace.shared.open(url)
    }
}
