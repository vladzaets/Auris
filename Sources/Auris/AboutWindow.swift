import AppKit

@MainActor
final class AboutWindow: NSObject {
    private var window: NSWindow?

    func show() {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let size = NSSize(width: 420, height: 340)
        let style: NSWindow.StyleMask = [.titled, .closable]
        let win = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: style,
            backing: .buffered,
            defer: false
        )
        win.title = "About Auris"
        win.isReleasedWhenClosed = false
        win.delegate = self
        self.window = win

        let content = NSView(frame: NSRect(origin: .zero, size: size))

        let iconSize: CGFloat = 80
        let icon: NSImageView
        if let url = Bundle.main.url(forResource: "icon", withExtension: "icns"),
           let img = NSImage(contentsOf: url)
        {
            img.size = NSSize(width: iconSize, height: iconSize)
            icon = NSImageView(image: img)
        } else {
            icon = NSImageView(image: NSApp.applicationIconImage)
        }
        icon.frame = NSRect(x: (size.width - iconSize) / 2, y: size.height - iconSize - 20, width: iconSize, height: iconSize)
        icon.imageScaling = .scaleProportionallyUpOrDown
        content.addSubview(icon)

        let appName = makeLabel("Auris", fontSize: 22, weight: .bold, color: .labelColor)
        appName.frame = NSRect(x: 0, y: icon.frame.origin.y - 38, width: size.width, height: 28)
        appName.alignment = .center
        content.addSubview(appName)

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        let versionText = makeLabel("Version \(version) (\(build))", fontSize: 12, weight: .regular, color: .secondaryLabelColor)
        versionText.frame = NSRect(x: 0, y: appName.frame.origin.y - 20, width: size.width, height: 18)
        versionText.alignment = .center
        content.addSubview(versionText)

        let desc = makeLabel(
            "On-device speech-to-text for macOS.\nHold a hotkey, speak, release — your words\nare transcribed and pasted automatically.\n100% private. No data leaves your Mac.",
            fontSize: 13, weight: .regular, color: .labelColor
        )
        desc.frame = NSRect(x: 30, y: versionText.frame.origin.y - 80, width: size.width - 60, height: 72)
        desc.alignment = .center
        content.addSubview(desc)

        let githubLabel = ClickableLabel()
        githubLabel.setup(
            text: "github.com/vladzaets/Auris",
            url: URL(string: "https://github.com/vladzaets/Auris")!,
            fontSize: 13
        )
        githubLabel.frame = NSRect(x: 0, y: desc.frame.origin.y - 24, width: size.width, height: 20)
        githubLabel.alignment = .center
        content.addSubview(githubLabel)

        let copyright = makeLabel("© 2026 Vlad Zaets. All rights reserved.", fontSize: 11, weight: .regular, color: .tertiaryLabelColor)
        copyright.frame = NSRect(x: 0, y: 12, width: size.width, height: 16)
        copyright.alignment = .center
        content.addSubview(copyright)

        win.contentView = content
        win.center()
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
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

extension AboutWindow: NSWindowDelegate {
    nonisolated func windowWillClose(_ notification: Notification) {}
}

private final class ClickableLabel: NSTextField {
    private var linkURL: URL?
    private var trackingArea: NSTrackingArea?

    func setup(text: String, url: URL, fontSize: CGFloat) {
        self.linkURL = url
        self.isBezeled = false
        self.isEditable = false
        self.isSelectable = false
        self.backgroundColor = .clear
        self.font = NSFont.systemFont(ofSize: fontSize, weight: .regular)
        self.textColor = NSColor.linkColor

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .foregroundColor: NSColor.linkColor,
            .font: NSFont.systemFont(ofSize: fontSize, weight: .regular),
            .paragraphStyle: paragraphStyle,
        ]
        self.attributedStringValue = NSAttributedString(string: text, attributes: attrs)

        let area = NSTrackingArea(
            rect: self.bounds,
            options: [.inVisibleRect, .activeAlways, .cursorUpdate],
            owner: self,
            userInfo: nil
        )
        self.addTrackingArea(area)
        self.trackingArea = area
    }

    override func cursorUpdate(with event: NSEvent) {
        NSCursor.pointingHand.set()
    }

    override func mouseDown(with event: NSEvent) {
        if let url = linkURL {
            NSWorkspace.shared.open(url)
        }
    }
}
