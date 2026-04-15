import AppKit

@MainActor
final class UpdateAvailableWindow: NSObject {
    static let shared = UpdateAvailableWindow()

    private var window: NSWindow?
    private var currentRelease: RemoteRelease?

    func show(release: RemoteRelease, currentVersion: Version) {
        if let window {
            window.orderOut(nil)
            self.window = nil
        }

        currentRelease = release
        let remote = Version(release.tagName)

        let width: CGFloat = 480
        let height: CGFloat = 380
        let size = NSSize(width: width, height: height)
        let style: NSWindow.StyleMask = [.titled, .closable]

        let win = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: style,
            backing: .buffered,
            defer: false
        )
        win.title = "Update Available"
        win.isReleasedWhenClosed = false
        win.delegate = self
        self.window = win

        let content = NSView(frame: NSRect(origin: .zero, size: size))

        let iconSize: CGFloat = 48
        let icon = NSImageView(image: NSApp.applicationIconImage)
        icon.frame = NSRect(x: 24, y: size.height - iconSize - 24, width: iconSize, height: iconSize)
        icon.imageScaling = .scaleProportionallyUpOrDown
        content.addSubview(icon)

        let title = makeLabel("A new version of Auris is available!", fontSize: 16, weight: .semibold, color: .labelColor)
        title.frame = NSRect(x: 84, y: size.height - 36, width: width - 108, height: 22)
        content.addSubview(title)

        let subtitle = makeLabel("Auris \(currentVersion.displayString) → \(remote.displayString)", fontSize: 13, weight: .regular, color: .secondaryLabelColor)
        subtitle.frame = NSRect(x: 84, y: title.frame.origin.y - 22, width: width - 108, height: 18)
        content.addSubview(subtitle)

        let notesLabel = makeLabel("Release Notes", fontSize: 12, weight: .semibold, color: .labelColor)
        notesLabel.frame = NSRect(x: 24, y: subtitle.frame.origin.y - 24, width: width - 48, height: 18)
        content.addSubview(notesLabel)

        let scrollView = NSScrollView()
        let textHeight: CGFloat = 160
        scrollView.frame = NSRect(x: 24, y: 72, width: width - 48, height: textHeight)
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .bezelBorder

        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 6, height: 6)

        let body = release.body.isEmpty ? "No release notes available." : release.body
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: .regular),
            .foregroundColor: NSColor.labelColor,
        ]
        textView.textStorage?.setAttributedString(NSAttributedString(string: body, attributes: attrs))
        textView.sizeToFit()

        scrollView.documentView = textView
        if let docView = scrollView.documentView {
            docView.scroll(NSPoint(x: 0, y: docView.bounds.size.height - textHeight))
        }
        content.addSubview(scrollView)

        let downloadBtn = NSButton(title: "Download", target: self, action: #selector(openDownload))
        downloadBtn.bezelStyle = .rounded
        downloadBtn.keyEquivalent = "\r"
        downloadBtn.frame = NSRect(x: width - 228, y: 20, width: 96, height: 32)
        content.addSubview(downloadBtn)

        let skipBtn = NSButton(title: "Skip This Version", target: self, action: #selector(skipVersion))
        skipBtn.bezelStyle = .rounded
        skipBtn.frame = NSRect(x: width - 124, y: 20, width: 100, height: 32)
        content.addSubview(skipBtn)

        let laterBtn = NSButton(title: "Remind Me Later", target: self, action: #selector(remindLater))
        laterBtn.bezelStyle = .rounded
        laterBtn.frame = NSRect(x: 24, y: 20, width: 140, height: 32)
        content.addSubview(laterBtn)

        win.contentView = content
        win.center()
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func openDownload() {
        if let url = URL(string: currentRelease?.htmlURL ?? "") {
            NSWorkspace.shared.open(url)
        }
        closeWindow()
    }

    @objc private func skipVersion() {
        if let release = currentRelease {
            Settings.shared.skippedVersion = Version(release.tagName).displayString
        }
        closeWindow()
    }

    @objc private func remindLater() {
        closeWindow()
    }

    private func closeWindow() {
        window?.orderOut(nil)
        window = nil
        currentRelease = nil
    }

    private func makeLabel(_ text: String, fontSize: CGFloat, weight: NSFont.Weight, color: NSColor) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: fontSize, weight: weight)
        label.textColor = color
        label.isBezeled = false
        label.isEditable = false
        label.isSelectable = false
        label.backgroundColor = .clear
        return label
    }
}

extension UpdateAvailableWindow: NSWindowDelegate {
    nonisolated func windowWillClose(_ notification: Notification) {}
}
