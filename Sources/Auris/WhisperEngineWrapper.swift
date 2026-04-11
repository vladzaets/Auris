import Foundation
import MLXAudio
import MLX

@MainActor
final class WhisperEngineWrapper {
    private var engine: WhisperEngine?
    private(set) var isLoaded = false
    private(set) var loadedModel: WhisperModel?

    var modelSize: WhisperModelSize {
        switch Settings.shared.whisperModel {
        case .small: .small
        case .medium: .medium
        case .largeV3: .large
        case .largeV3Turbo: .largeTurbo
        }
    }

    func load(progressHandler: (@Sendable (Progress) -> Void)? = nil) async throws {
        if isLoaded, loadedModel == Settings.shared.whisperModel {
            return
        }

        if engine != nil {
            await engine?.unload()
            engine = nil
            isLoaded = false
        }

        MLX.GPU.set(cacheLimit: 20 * 1024 * 1024)

        let e = WhisperEngine(
            modelSize: modelSize,
            quantization: .q4
        )

        try await e.load(progressHandler: progressHandler)

        engine = e
        isLoaded = true
        loadedModel = Settings.shared.whisperModel
    }

    func unload() async {
        if let engine {
            await engine.unload()
        }
        engine = nil
        isLoaded = false
        loadedModel = nil
    }

    func transcribe(url: URL) async throws -> TranscriptionResult {
        guard let engine, isLoaded else {
            throw STTError.modelNotLoaded
        }

        let language = mapLanguage(Settings.shared.language)

        return try await engine.transcribe(
            url,
            language: language,
            temperature: 0.0,
            timestamps: .segment,
            hallucinationSilenceThreshold: 2.0
        )
    }

    private func mapLanguage(_ lang: AppLanguage) -> Language? {
        switch lang {
        case .en: .english
        case .ru: .russian
        case .de: .german
        case .fr: .french
        case .es: .spanish
        case .it: .italian
        case .pt: .portuguese
        case .nl: .dutch
        case .ja: .japanese
        case .ko: .korean
        case .zh: .chinese
        case .ar: .arabic
        case .hi: .hindi
        case .uk: .ukrainian
        case .pl: .polish
        case .tr: .turkish
        }
    }
}
