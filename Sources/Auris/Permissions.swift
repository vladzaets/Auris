import AppKit
import Foundation

enum Permissions {
    static func checkAccessibility(prompt: Bool = false) -> Bool {
        let key = "AXTrustedCheckOptionPrompt" as CFString
        let dict = [key: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(dict)
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
