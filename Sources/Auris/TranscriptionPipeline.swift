import Foundation

enum AppState {
    case idle
    case recording
    case transcribing
    case downloading
}

@MainActor
final class TranscriptionPipeline {
    private let recorder = AudioRecorder()
    private let engine = WhisperEngineWrapper()
    private(set) var state: AppState = .idle
    var lastText: String?
    private(set) var lastTranscriptionDuration: TimeInterval?
    private var postProcessor: PostProcessor?
    private var transcribingSince: Date?
    private var unloadTimer: Timer?
    private var modelLoadTask: Task<Void, Never>?
    private var pendingAudioURL: URL?

    var isRecording: Bool { recorder.isRecording }
    var recordingDuration: TimeInterval { recorder.duration }
    var isEngineLoaded: Bool { engine.isLoaded }

    func loadEngine() async throws {
        let needsDownload = engine.needsDownload
        let isBackground = state == .recording

        if needsDownload && !isBackground {
            state = .downloading
            AppDelegate.shared?.setDownloadingState()
        }

        try await engine.load { progress in
            Task { @MainActor in
                if needsDownload && !isBackground {
                    let pct = Int(progress.fractionCompleted * 100)
                    AppDelegate.shared?.updateStatus("Status: Downloading… \(pct)%")
                }
            }
        }

        PostProcessor.createCorrectionsTemplate()
        Vocabulary.createPromptTermsTemplate()
        if Settings.shared.postProcessingEnabled {
            postProcessor = PostProcessor(vocabulary: Vocabulary.all)
        }

        if !isBackground {
            state = .idle
        }
        scheduleAutoUnload()
    }

    func reloadEngine() async throws {
        await engine.unload()
        try await loadEngine()
    }

    func startRecording() throws {
        guard state == .idle else { return }

        cancelAutoUnload()
        try recorder.startRecording()
        state = .recording

        if !engine.isLoaded {
            startLoadingModel()
        }
    }

    func stopRecording() {
        guard state == .recording else { return }

        guard let url = recorder.stopRecording() else {
            state = .idle
            return
        }

        let duration = recordingDuration
        if duration < 0.5 {
            state = .idle
            try? FileManager.default.removeItem(at: url)
            return
        }

        if engine.isLoaded {
            transcribe(url: url)
        } else {
            pendingAudioURL = url
            state = .transcribing
            transcribingSince = Date()
        }
    }

    func cancelTranscription() {
        guard state == .transcribing else { return }
        state = .idle
    }

    func checkTimeout() {
        guard state == .transcribing, let since = transcribingSince else { return }
        if Date().timeIntervalSince(since) > 60 {
            cancelTranscription()
            AppDelegate.shared?.handleTranscriptionError("Transcription timed out after 60s")
        }
    }

    func scheduleAutoUnload() {
        cancelAutoUnload()
        let interval = Settings.shared.autoUnloadInterval
        guard interval != .never else { return }

        unloadTimer = Timer.scheduledTimer(withTimeInterval: interval.timeInterval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.state == .idle, self.engine.isLoaded else { return }
                self.engine.unload()
            }
        }
    }

    func cancelAutoUnload() {
        unloadTimer?.invalidate()
        unloadTimer = nil
    }

    private func startLoadingModel() {
        guard modelLoadTask == nil else { return }
        modelLoadTask = Task {
            do {
                try await loadEngine()
                if let url = pendingAudioURL {
                    pendingAudioURL = nil
                    transcribe(url: url)
                }
            } catch {
                if let url = pendingAudioURL {
                    try? FileManager.default.removeItem(at: url)
                    pendingAudioURL = nil
                    state = .idle
                }
                AppDelegate.shared?.handleTranscriptionError("Failed to load model: \(error.localizedDescription)")
            }
            modelLoadTask = nil
        }
    }

    private func transcribe(url: URL) {
        state = .transcribing
        transcribingSince = Date()

        Task {
            do {
                let prompt = Settings.shared.initialPromptEnabled ? Vocabulary.buildInitialPrompt() : nil
                let result = try await engine.transcribe(url: url, initialPrompt: prompt)
                try? FileManager.default.removeItem(at: url)

                var text = result.text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else {
                    self.state = .idle
                    scheduleAutoUnload()
                    AppDelegate.shared?.handleTranscriptionComplete(nil)
                    return
                }

                text = TextCleaner.stripHallucinationLoops(text)
                text = TextCleaner.removeFillerWords(text)
                if let processor = postProcessor {
                    text = processor.apply(text)
                }

                lastText = text
                lastTranscriptionDuration = transcribingSince.map { Date().timeIntervalSince($0) }
                state = .idle
                scheduleAutoUnload()
                AppDelegate.shared?.handleTranscriptionComplete(text, duration: lastTranscriptionDuration)

            } catch {
                try? FileManager.default.removeItem(at: url)
                lastTranscriptionDuration = transcribingSince.map { Date().timeIntervalSince($0) }
                state = .idle
                scheduleAutoUnload()
                AppDelegate.shared?.handleTranscriptionError(error.localizedDescription)
            }
        }
    }
}
