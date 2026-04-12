import AppKit
import Foundation

@MainActor
final class TranscriptionsViewer: NSObject {
    private var window: NSWindow?
    private var textView: NSTextView?
    private var scrollView: NSScrollView?
    private var searchField: NSSearchField?
    private var entries: [[String: Any]] = []
    private var filtered: [(index: Int, entry: [String: Any])] = []
    private var entryRanges: [(start: Int, end: Int, originalIndex: Int)] = []

    func show() {
        entries = TranscriptionLog.load()
        if entries.isEmpty {
            showNotification("No Transcriptions", "No transcriptions recorded yet.")
            return
        }

        NSApp.setActivationPolicy(.regular)

        let style: NSWindow.StyleMask = [.titled, .closable, .resizable, .miniaturizable]
        let window = NSWindow(
            contentRect: NSRect(x: 200, y: 200, width: 750, height: 550),
            styleMask: style,
            backing: .buffered,
            defer: false
        )
        window.title = "Auris — Transcriptions (\(entries.count))"
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 500, height: 300)
        window.delegate = self
        self.window = window

        let searchField = NSSearchField(frame: NSRect(x: 12, y: 516, width: 480, height: 24))
        searchField.placeholderString = "Search transcriptions…"
        searchField.target = self
        searchField.action = #selector(onSearch(_:))
        searchField.autoresizingMask = [.width]
        self.searchField = searchField

        let copyBtn = NSButton(frame: NSRect(x: 500, y: 516, width: 62, height: 24))
        copyBtn.title = "Copy"
        copyBtn.bezelStyle = .rounded
        copyBtn.target = self
        copyBtn.action = #selector(onCopy(_:))
        copyBtn.autoresizingMask = [.minXMargin]

        let deleteBtn = NSButton(frame: NSRect(x: 568, y: 516, width: 68, height: 24))
        deleteBtn.title = "Delete"
        deleteBtn.bezelStyle = .rounded
        deleteBtn.target = self
        deleteBtn.action = #selector(onDelete(_:))
        deleteBtn.autoresizingMask = [.minXMargin]

        let clearBtn = NSButton(frame: NSRect(x: 642, y: 516, width: 96, height: 24))
        clearBtn.title = "Clear All"
        clearBtn.bezelStyle = .rounded
        clearBtn.target = self
        clearBtn.action = #selector(onClearAll(_:))
        clearBtn.autoresizingMask = [.minXMargin]

        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 750, height: 508))
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .noBorder
        scrollView.autoresizingMask = [.width, .height]
        self.scrollView = scrollView

        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 730, height: 508))
        textView.isEditable = false
        textView.isSelectable = true
        textView.autoresizingMask = [.width, .height]
        textView.textContainerInset = NSSize(width: 8, height: 8)
        scrollView.documentView = textView
        self.textView = textView

        applyFilter("")
        buildText()

        let content = NSView(frame: NSRect(x: 0, y: 0, width: 750, height: 550))
        content.addSubview(scrollView)
        content.addSubview(searchField)
        content.addSubview(copyBtn)
        content.addSubview(deleteBtn)
        content.addSubview(clearBtn)
        window.contentView = content

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        scrollToBottom()
    }

    private func applyFilter(_ query: String) {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        if q.isEmpty {
            filtered = entries.enumerated().map { (index: $0.offset, entry: $0.element) }
        } else {
            filtered = entries.enumerated().compactMap { i, e in
                if let text = e["text"] as? String, text.lowercased().contains(q) {
                    return (index: i, entry: e)
                }
                return nil
            }
        }
    }

    private func buildText() {
        guard let textView else { return }

        let bodyFont = NSFont.systemFont(ofSize: 13.0)
        let metaFont = NSFont.monospacedSystemFont(ofSize: 11.0, weight: .regular)
        let metaColor = NSColor.secondaryLabelColor
        let bodyColor = NSColor.labelColor
        let separatorColor = NSColor.separatorColor

        let attributed = NSMutableAttributedString()
        entryRanges = []

        let count = filtered.count
        let headerText = "\(count) transcription\(count == 1 ? "" : "s")\n\n"
        let header = NSMutableAttributedString(string: headerText)
        header.addAttribute(.foregroundColor, value: metaColor, range: NSRange(location: 0, length: header.length))
        header.addAttribute(.font, value: metaFont, range: NSRange(location: 0, length: header.length))
        attributed.append(header)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        for (_, entry) in filtered {
            let sectionStart = attributed.length

            let ts: String
            if let timestamp = entry["timestamp"] as? String,
               let date = ISO8601DateFormatter().date(from: timestamp)
            {
                ts = dateFormatter.string(from: date)
            } else {
                ts = entry["timestamp"] as? String ?? ""
            }

            let model = entry["model"] as? String ?? ""
            var metaParts = ["[\(ts)]", model]
            if let duration = entry["duration"] as? Double {
                metaParts.append(String(format: "%.2fs", duration))
            }
            let meta = NSMutableAttributedString(string: metaParts.joined(separator: "  ") + "\n")
            meta.addAttribute(.foregroundColor, value: metaColor, range: NSRange(location: 0, length: meta.length))
            meta.addAttribute(.font, value: metaFont, range: NSRange(location: 0, length: meta.length))
            attributed.append(meta)

            let text = entry["text"] as? String ?? ""
            let body = NSMutableAttributedString(string: "\(text)\n")
            body.addAttribute(.foregroundColor, value: bodyColor, range: NSRange(location: 0, length: body.length))
            body.addAttribute(.font, value: bodyFont, range: NSRange(location: 0, length: body.length))
            attributed.append(body)

            let sep = NSMutableAttributedString(string: "\(String(repeating: "─", count: 70))\n")
            sep.addAttribute(.foregroundColor, value: separatorColor, range: NSRange(location: 0, length: sep.length))
            sep.addAttribute(.font, value: metaFont, range: NSRange(location: 0, length: sep.length))
            attributed.append(sep)

            let sectionEnd = attributed.length
        }

        textView.textStorage?.setAttributedString(attributed)
    }

    private func scrollToBottom() {
        guard let textView else { return }
        let length = textView.textStorage?.length ?? 0
        if length > 0 {
            textView.scrollRangeToVisible(NSRange(location: length - 1, length: 1))
        }
    }

    private func entryAtCursor() -> Int? {
        guard let textView else { return nil }
        let cursor = textView.selectedRange().location
        for range in entryRanges {
            if range.start <= cursor && cursor < range.end {
                return range.originalIndex
            }
        }
        return nil
    }

    private func refreshAfterChange() {
        let query = searchField?.stringValue ?? ""
        applyFilter(query)
        buildText()
        scrollToBottom()
        if let window {
            window.title = "Auris — Transcriptions (\(entries.count))"
        }
    }

    private func showNotification(_ title: String, _ message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func onSearch(_ sender: Any?) {
        let query = searchField?.stringValue ?? ""
        applyFilter(query)
        buildText()
        scrollToBottom()
    }

    @objc private func onCopy(_ sender: Any?) {
        guard let idx = entryAtCursor() else { return }
        guard idx < entries.count else { return }
        let text = entries[idx]["text"] as? String ?? ""
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
    }

    @objc private func onDelete(_ sender: Any?) {
        guard let idx = entryAtCursor() else { return }
        TranscriptionLog.delete(at: idx)
        entries = TranscriptionLog.load()
        if entries.isEmpty {
            window?.close()
            return
        }
        refreshAfterChange()
    }

    @objc private func onClearAll(_ sender: Any?) {
        let alert = NSAlert()
        alert.messageText = "Clear All Transcriptions?"
        alert.informativeText = "This will permanently delete all transcription history. This action cannot be undone."
        alert.addButton(withTitle: "Clear All")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            TranscriptionLog.clearAll()
            entries = []
            filtered = []
            entryRanges = []
            window?.close()
        }
    }
}

extension TranscriptionsViewer: NSWindowDelegate {
    nonisolated func windowWillClose(_ notification: Notification) {
        Task { @MainActor in
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
