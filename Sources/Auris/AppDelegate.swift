import AppKit
import ApplicationServices

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate?

    private var statusItem: NSStatusItem!
    private let idleIcon: NSImage = {
        let url = Bundle.main.url(forResource: "54x54", withExtension: "png")!
        let img = NSImage(contentsOf: url)!
        img.size = NSSize(width: 18, height: 18)
        img.isTemplate = true
        return img
    }()
    private let pipeline = TranscriptionPipeline()
    private var hotkeyManager: HotkeyManager?
    private let viewer = TranscriptionsViewer()
    private var statusMenuItem: NSMenuItem!
    private var recordMenuItem: NSMenuItem!
    private var cancelMenuItem: NSMenuItem!
    private var modelSubmenu: NSMenu!
    private var languageSubmenu: NSMenu!
    private var soundSubmenus: [String: NSMenu] = [:]
    private var hotkeySubmenu: NSMenu!
    private var initialPromptMenuItem: NSMenuItem!
    private var autostartMenuItem: NSMenuItem!
    private var timer: Timer?
    private var recordingStartTime: Date?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self

        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = idleIcon
        }

        buildMenu()

        hotkeyManager = HotkeyManager(
            hotkey: Settings.shared.recordingHotkey,
            onStart: { [weak self] in Task { @MainActor in self?.handleHotkeyStart() } },
            onStop: { [weak self] in Task { @MainActor in self?.handleHotkeyStop() } }
        )

        requestPermissionsAndStart()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateRecordingTimer()
                self?.pipeline.checkTimeout()
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func requestPermissionsAndStart() {
        let accessible = Permissions.checkAccessibility(prompt: true)
        Permissions.triggerMicrophonePermission()

        Task {
            do {
                try await pipeline.loadEngine()
            } catch {
                showErrorMessage("Failed to initialize speech model: \(error.localizedDescription)")
                return
            }

            if accessible {
                hotkeyManager?.start()
            } else {
                showNotification("Hotkey Not Working",
                    "Accessibility permission is required. Go to System Settings → Privacy & Security → Accessibility and enable Auris, then relaunch.")
            }

            if Settings.shared.isFirstLaunch {
                let hotkeyLabel = Settings.shared.recordingHotkey.displayName
                showNotification("Welcome to Auris!",
                    "Hold the \(hotkeyLabel) key to dictate, release to transcribe and paste.")
            }
        }
    }

    // MARK: - Menu

    private func buildMenu() {
        let menu = NSMenu()

        statusMenuItem = NSMenuItem(title: "Status: Idle", action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        recordMenuItem = NSMenuItem(title: "Start Recording", action: #selector(toggleRecording), keyEquivalent: "")
        let cancelItem = NSMenuItem(title: "Cancel Transcription", action: #selector(cancelTranscription), keyEquivalent: "")
        cancelMenuItem = cancelItem
        cancelItem.isEnabled = false
        let pasteItem = NSMenuItem(title: "Paste Last Transcription", action: #selector(pasteLast), keyEquivalent: "")
        let viewItem = NSMenuItem(title: "View Transcriptions", action: #selector(viewTranscriptions), keyEquivalent: "")

        menu.addItem(statusMenuItem)
        menu.addItem(recordMenuItem)
        menu.addItem(cancelItem)
        menu.addItem(pasteItem)
        menu.addItem(viewItem)
        menu.addItem(NSMenuItem.separator())

        let modelItem = NSMenuItem(title: "Model", action: nil, keyEquivalent: "")
        modelSubmenu = NSMenu()
        for model in WhisperModel.allCases {
            let item = NSMenuItem(title: model.displayName, action: #selector(selectModel(_:)), keyEquivalent: "")
            item.representedObject = model.rawValue
            if model == Settings.shared.whisperModel { item.state = .on }
            modelSubmenu.addItem(item)
        }
        modelSubmenu.addItem(NSMenuItem.separator())
        let promptItem = NSMenuItem(title: "Initial Prompt", action: #selector(toggleInitialPrompt), keyEquivalent: "")
        promptItem.state = Settings.shared.initialPromptEnabled ? .on : .off
        initialPromptMenuItem = promptItem
        modelSubmenu.addItem(promptItem)
        modelItem.submenu = modelSubmenu
        menu.addItem(modelItem)

        let langItem = NSMenuItem(title: "Language", action: nil, keyEquivalent: "")
        languageSubmenu = NSMenu()
        for lang in AppLanguage.allCases {
            let item = NSMenuItem(title: lang.displayName, action: #selector(selectLanguage(_:)), keyEquivalent: "")
            item.representedObject = lang.rawValue
            if lang == Settings.shared.language { item.state = .on }
            languageSubmenu.addItem(item)
        }
        langItem.submenu = languageSubmenu
        menu.addItem(langItem)

        let soundsItem = NSMenuItem(title: "Sounds", action: nil, keyEquivalent: "")
        let soundsMenu = NSMenu()
        for (event, label) in [("start", "Start"), ("stop", "Stop"), ("complete", "Complete"), ("error", "Error")] {
            let sub = NSMenuItem(title: "\(label) Sound", action: nil, keyEquivalent: "")
            let subMenu = NSMenu()
            let noneItem = NSMenuItem(title: "None", action: #selector(selectSound(_:)), keyEquivalent: "")
            noneItem.representedObject = "\(event):None"
            let current = getSoundSetting(for: event)
            if current == nil { noneItem.state = .on }
            subMenu.addItem(noneItem)

            for soundName in SoundPlayer.availableSounds {
                let item = NSMenuItem(title: soundName, action: #selector(selectSound(_:)), keyEquivalent: "")
                item.representedObject = "\(event):\(soundName)"
                if current == soundName { item.state = .on }
                subMenu.addItem(item)
            }
            sub.submenu = subMenu
            soundSubmenus[event] = subMenu
            soundsMenu.addItem(sub)
        }
        soundsItem.submenu = soundsMenu
        menu.addItem(soundsItem)

        let vocabItem = NSMenuItem(title: "Vocabulary", action: nil, keyEquivalent: "")
        let vocabMenu = NSMenu()
        vocabMenu.addItem(NSMenuItem(title: "Edit Corrections", action: #selector(editCorrections), keyEquivalent: ""))
        vocabMenu.addItem(NSMenuItem(title: "Edit Prompt Terms", action: #selector(editPromptTerms), keyEquivalent: ""))
        vocabItem.submenu = vocabMenu
        menu.addItem(vocabItem)

        let hotkeyItem = NSMenuItem(title: "Hotkey", action: nil, keyEquivalent: "")
        hotkeySubmenu = NSMenu()
        for hk in RecordingHotkey.allCases {
            let item = NSMenuItem(title: hk.displayName, action: #selector(selectHotkey(_:)), keyEquivalent: "")
            item.representedObject = hk.rawValue
            if hk == Settings.shared.recordingHotkey { item.state = .on }
            hotkeySubmenu.addItem(item)
        }
        hotkeyItem.submenu = hotkeySubmenu
        menu.addItem(hotkeyItem)

        menu.addItem(NSMenuItem.separator())

        autostartMenuItem = NSMenuItem(title: "Start at Login", action: #selector(toggleAutostart), keyEquivalent: "")
        autostartMenuItem.state = Autostart.isEnabled ? .on : .off
        menu.addItem(autostartMenuItem)

        let permsItem = NSMenuItem(title: "Permissions", action: nil, keyEquivalent: "")
        let permsMenu = NSMenu()
        permsMenu.addItem(NSMenuItem(title: "Accessibility", action: #selector(openAccessibility), keyEquivalent: ""))
        permsMenu.addItem(NSMenuItem(title: "Input Monitoring", action: #selector(openInputMonitoring), keyEquivalent: ""))
        permsMenu.addItem(NSMenuItem(title: "Microphone", action: #selector(openMicrophone), keyEquivalent: ""))
        permsItem.submenu = permsMenu
        menu.addItem(permsItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Auris", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        menu.autoenablesItems = false
        statusItem.menu = menu
    }

    private func getSoundSetting(for event: String) -> String? {
        switch event {
        case "start": Settings.shared.soundStart
        case "stop": Settings.shared.soundStop
        case "complete": Settings.shared.soundComplete
        case "error": Settings.shared.soundError
        default: nil
        }
    }

    private func setSoundSetting(for event: String, value: String?) {
        switch event {
        case "start": Settings.shared.soundStart = value == "None" ? nil : value
        case "stop": Settings.shared.soundStop = value == "None" ? nil : value
        case "complete": Settings.shared.soundComplete = value == "None" ? nil : value
        case "error": Settings.shared.soundError = value == "None" ? nil : value
        default: break
        }
    }

    // MARK: - State Updates

    func updateStatus(_ text: String) {
        statusMenuItem.title = text
    }

    func handleTranscriptionComplete(_ text: String?, duration: TimeInterval? = nil) {
        resetToIdle()
        guard let text, !text.isEmpty else { return }

        SoundPlayer.play(Settings.shared.soundComplete)
        TranscriptionLog.save(text: text, model: Settings.shared.whisperModel.rawValue, duration: duration)

        if !TextInjector.inject(text) {
            showNotification("Error", "Failed to paste text. Check Accessibility permission.")
        }
    }

    func handleTranscriptionError(_ message: String) {
        resetToIdle()
        SoundPlayer.play(Settings.shared.soundError)
        showNotification("Transcription Error", message)
    }

    func showErrorMessage(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Auris Error"
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.alertStyle = .critical
        alert.runModal()
    }

    private func resetToIdle() {
        recordingStartTime = nil
        statusMenuItem.title = "Status: Idle"
        cancelMenuItem.isEnabled = false
        recordMenuItem.title = "Start Recording"
        if let button = statusItem.button {
            button.image = idleIcon
        }
    }

    private func setRecordingState() {
        recordingStartTime = Date()
        statusMenuItem.title = "Status: Recording... 0s"
        recordMenuItem.title = "Stop Recording"
        cancelMenuItem.isEnabled = false
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "record.circle", accessibilityDescription: "Recording")
            button.image?.size = NSSize(width: 18, height: 18)
        }
    }

    private func setTranscribingState() {
        statusMenuItem.title = "Status: Transcribing..."
        recordMenuItem.title = "Start Recording"
        cancelMenuItem.isEnabled = true
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "Processing")
            button.image?.size = NSSize(width: 18, height: 18)
        }
    }

    func setDownloadingState() {
        statusMenuItem.title = "Status: Downloading… 0%"
        recordMenuItem.title = "Start Recording"
        cancelMenuItem.isEnabled = false
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "arrow.down.circle", accessibilityDescription: "Downloading")
            button.image?.size = NSSize(width: 18, height: 18)
        }
    }

    private func updateRecordingTimer() {
        if pipeline.state == .recording, let start = recordingStartTime {
            let elapsed = Int(Date().timeIntervalSince(start))
            statusMenuItem.title = "Status: Recording... \(elapsed)s"
        }
    }

    // MARK: - Hotkey

    private func handleHotkeyStart() {
        guard pipeline.state == .idle else {
            SoundPlayer.play(Settings.shared.soundError)
            return
        }
        do {
            try pipeline.startRecording()
            SoundPlayer.play(Settings.shared.soundStart)
            setRecordingState()
        } catch {
            resetToIdle()
            showNotification("Error", "Failed to start recording: \(error.localizedDescription)")
        }
    }

    private func handleHotkeyStop() {
        guard pipeline.state == .recording else { return }
        pipeline.stopRecording()
        SoundPlayer.play(Settings.shared.soundStop)
        if pipeline.state == .transcribing {
            setTranscribingState()
        } else {
            resetToIdle()
        }
    }

    // MARK: - Actions

    @objc private func toggleRecording() {
        switch pipeline.state {
        case .idle:
            handleHotkeyStart()
        case .recording:
            handleHotkeyStop()
        default:
            break
        }
    }

    @objc private func cancelTranscription() {
        pipeline.cancelTranscription()
        resetToIdle()
    }

    @objc private func pasteLast() {
        guard let text = pipeline.lastText else {
            showNotification("No Transcription", "No transcription available to paste.")
            return
        }
        if !TextInjector.inject(text) {
            showNotification("Error", "Failed to paste. Check Accessibility permission.")
        }
    }

    @objc private func viewTranscriptions() {
        viewer.show()
    }

    @objc private func selectModel(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let model = WhisperModel(rawValue: raw),
              model != Settings.shared.whisperModel
        else { return }

        let old = Settings.shared.whisperModel
        Settings.shared.whisperModel = model
        updateMenuCheckmarks(submenu: modelSubmenu, selectedItem: sender)

        statusMenuItem.title = "Status: Switching model…"
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "Processing")
            button.image?.size = NSSize(width: 18, height: 18)
        }

        Task {
            do {
                try await pipeline.reloadEngine()
                resetToIdle()
                showNotification("Model Changed", "Now using \(model.displayName)")
            } catch {
                Settings.shared.whisperModel = old
                resetToIdle()
                showNotification("Error", "Failed to load \(model.displayName)")
            }
        }
    }

    @objc private func selectLanguage(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let lang = AppLanguage(rawValue: raw),
              lang != Settings.shared.language
        else { return }

        Settings.shared.language = lang
        updateMenuCheckmarks(submenu: languageSubmenu, selectedItem: sender)

        statusMenuItem.title = "Status: Switching language…"
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "Processing")
            button.image?.size = NSSize(width: 18, height: 18)
        }

        Task {
            do {
                try await pipeline.reloadEngine()
                resetToIdle()
            } catch {
                resetToIdle()
                showNotification("Error", "Failed to reload model: \(error.localizedDescription)")
            }
        }
    }

    @objc private func selectSound(_ sender: NSMenuItem) {
        guard let obj = sender.representedObject as? String else { return }
        let parts = obj.split(separator: ":", maxSplits: 1)
        guard parts.count == 2 else { return }
        let event = String(parts[0])
        let name = String(parts[1])

        setSoundSetting(for: event, value: name)
        if let submenu = soundSubmenus[event] {
            updateMenuCheckmarks(submenu: submenu, selectedItem: sender)
        }

        if name != "None" {
            SoundPlayer.play(name)
        }
    }

    @objc private func selectHotkey(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let hk = RecordingHotkey(rawValue: raw),
              hk != Settings.shared.recordingHotkey
        else { return }

        Settings.shared.recordingHotkey = hk
        updateMenuCheckmarks(submenu: hotkeySubmenu, selectedItem: sender)
        hotkeyManager?.setHotkey(hk)
    }

    @objc private func toggleAutostart() {
        if Autostart.isEnabled {
            Autostart.disable()
            autostartMenuItem.state = .off
            Settings.shared.startAtLogin = false
        } else {
            Autostart.enable()
            autostartMenuItem.state = .on
            Settings.shared.startAtLogin = true
        }
    }

    @objc private func toggleInitialPrompt() {
        let enabled = !Settings.shared.initialPromptEnabled
        Settings.shared.initialPromptEnabled = enabled
        initialPromptMenuItem.state = enabled ? .on : .off
    }

    @objc private func editCorrections() {
        PostProcessor.createCorrectionsTemplate()
        NSWorkspace.shared.open(AppConstants.correctionsFile)
    }

    @objc private func editPromptTerms() {
        AppConstants.ensureDataDir()
        let url = AppConstants.promptTermsFile
        if !FileManager.default.fileExists(atPath: url.path) {
            let template = """
            # Auris — Custom Prompt Terms
            #
            # Add words/phrases here that Whisper should recognise.
            # One term per line, or comma-separated.
            # Lines starting with # are comments.
            # Changes take effect on next app restart.

            """
            try? template.write(to: url, atomically: true, encoding: .utf8)
        }
        NSWorkspace.shared.open(url)
    }

    @objc private func openAccessibility() {
        Permissions.openAccessibilityPreferences()
    }

    @objc private func openInputMonitoring() {
        Permissions.openInputMonitoringPreferences()
    }

    @objc private func openMicrophone() {
        Permissions.openMicrophonePreferences()
    }

    // MARK: - Helpers

    private func updateMenuCheckmarks(submenu: NSMenu, selectedItem: NSMenuItem) {
        for item in submenu.items {
            item.state = item === selectedItem ? .on : .off
        }
    }

    private func showNotification(_ title: String, _ message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.alertStyle = .informational
        alert.runModal()
    }
}
