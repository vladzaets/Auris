import AppKit
import CoreGraphics
import Foundation

enum TextInjector {
    private static let vkAnsiV: CGKeyCode = 9
    private static let maxPasteDelay: TimeInterval = 0.1
    private static let maxRestoreDelay: TimeInterval = 1.0

    @MainActor
    static func inject(_ text: String) -> Bool {
        guard !text.isEmpty else { return false }

        let pb = NSPasteboard.general
        let oldContents = pb.string(forType: .string)
        let oldChangeCount = pb.changeCount

        pb.clearContents()
        pb.setString(text, forType: .string)
        let ourChangeCount = pb.changeCount

        let pasteDelay = min(Settings.shared.pasteDelaySeconds, maxPasteDelay)
        Thread.sleep(forTimeInterval: pasteDelay)

        simulateCmdV()

        let restoreDelay = min(Settings.shared.clipboardRestoreDelaySeconds, maxRestoreDelay)
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + restoreDelay) {
            let currentPB = NSPasteboard.general
            if currentPB.changeCount == ourChangeCount {
                currentPB.clearContents()
                if let old = oldContents {
                    currentPB.setString(old, forType: .string)
                }
            }
        }

        return true
    }

    private static func simulateCmdV() {
        let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: vkAnsiV, keyDown: true)
        keyDown?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)

        let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: vkAnsiV, keyDown: false)
        keyUp?.flags = .maskCommand
        keyUp?.post(tap: .cghidEventTap)
    }
}
