import Foundation
import MLXAudio

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

    var isRecording: Bool { recorder.isRecording }
    var recordingDuration: TimeInterval { recorder.duration }

    func loadEngine() async throws {
        state = .downloading
        try await engine.load { progress in
            Task { @MainActor in
                let pct = Int(progress.fractionCompleted * 100)
                AppDelegate.shared?.updateStatus("Downloading model… \(pct)%")
            }
        }

        PostProcessor.createCorrectionsTemplate()
        if Settings.shared.postProcessingEnabled {
            postProcessor = PostProcessor(vocabulary: Vocabulary.all)
        }

        state = .idle
    }

    func reloadEngine() async throws {
        await engine.unload()
        try await loadEngine()
    }

    func startRecording() throws {
        guard state == .idle else { return }
        guard engine.isLoaded else {
            AppDelegate.shared?.showErrorMessage("Backend not initialized")
            return
        }

        try recorder.startRecording()
        state = .recording
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

        state = .transcribing
        transcribingSince = Date()

        Task {
            do {
                let result = try await engine.transcribe(url: url)
                try? FileManager.default.removeItem(at: url)

                var text = result.text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else {
                    self.state = .idle
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
                AppDelegate.shared?.handleTranscriptionComplete(text, duration: lastTranscriptionDuration)

            } catch {
                try? FileManager.default.removeItem(at: url)
                lastTranscriptionDuration = transcribingSince.map { Date().timeIntervalSince($0) }
                state = .idle
                AppDelegate.shared?.handleTranscriptionError(error.localizedDescription)
            }
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
}
