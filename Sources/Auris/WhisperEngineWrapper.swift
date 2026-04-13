import Foundation
import CWhisper

enum STTError: LocalizedError {
    case modelNotLoaded
    case modelLoadFailed(String)
    case transcriptionFailed(String)
    case audioReadFailed(String)

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded: "Model not loaded"
        case .modelLoadFailed(let path): "Failed to load model at \(path)"
        case .transcriptionFailed(let reason): "Transcription failed: \(reason)"
        case .audioReadFailed(let reason): "Audio read failed: \(reason)"
        }
    }
}

private final class ModelDownloadDelegate: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    let progress: Progress
    let handler: (@Sendable (Progress) -> Void)?
    private let destURL: URL
    private var continuation: CheckedContinuation<URL, Error>?
    private var resumed = false

    init(progress: Progress, handler: (@Sendable (Progress) -> Void)?, destURL: URL) {
        self.progress = progress
        self.handler = handler
        self.destURL = destURL
        super.init()
    }

    func setContinuation(_ continuation: CheckedContinuation<URL, Error>) {
        self.continuation = continuation
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if totalBytesExpectedToWrite > 0 {
            progress.totalUnitCount = totalBytesExpectedToWrite
        }
        progress.completedUnitCount = totalBytesWritten
        handler?(progress)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let statusCode = (downloadTask.response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200...299).contains(statusCode) else {
            try? FileManager.default.removeItem(at: location)
            guard !resumed else { return }
            resumed = true
            continuation?.resume(throwing: STTError.modelLoadFailed("Download failed with status \(statusCode)"))
            return
        }

        do {
            try? FileManager.default.removeItem(at: destURL)
            try FileManager.default.moveItem(at: location, to: destURL)
            guard !resumed else { return }
            resumed = true
            continuation?.resume(returning: destURL)
        } catch {
            guard !resumed else { return }
            resumed = true
            continuation?.resume(throwing: error)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error, !resumed else { return }
        resumed = true
        continuation?.resume(throwing: error)
    }
}

struct TranscriptionResult {
    let text: String
}

struct WhisperContext: @unchecked Sendable {
    let pointer: OpaquePointer

    static func load(path: String) throws -> WhisperContext {
        var cparams = whisper_context_default_params()
        cparams.use_gpu = true
        cparams.flash_attn = true

        guard let ctx = whisper_init_from_file_with_params(path, cparams) else {
            throw STTError.modelLoadFailed(path)
        }
        return WhisperContext(pointer: ctx)
    }

    func free() {
        whisper_free(pointer)
    }
}

@MainActor
final class WhisperEngineWrapper {
    private var context: WhisperContext?
    private(set) var isLoaded = false
    private(set) var loadedModel: WhisperModel?

    private static let modelsDirectory: URL = {
        let dir = AppConstants.dataDir.appendingPathComponent("models")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private var modelPath: String {
        let filename: String = switch Settings.shared.whisperModel {
        case .small: "ggml-small.bin"
        case .medium: "ggml-medium.bin"
        case .largeV3: "ggml-large-v3.bin"
        case .largeV3Turbo: "ggml-large-v3-turbo.bin"
        }
        return Self.modelsDirectory.appendingPathComponent(filename).path
    }

    func load(progressHandler: (@Sendable (Progress) -> Void)? = nil) async throws {
        if isLoaded, loadedModel == Settings.shared.whisperModel {
            return
        }

        unload()

        let path = modelPath
        if !FileManager.default.fileExists(atPath: path) {
            try await downloadModel(progressHandler: progressHandler)
        }

        guard FileManager.default.fileExists(atPath: path) else {
            throw STTError.modelLoadFailed(path)
        }

        let ctx = try WhisperContext.load(path: path)

        context = ctx
        isLoaded = true
        loadedModel = Settings.shared.whisperModel
    }

    func unload() {
        if let context {
            context.free()
        }
        context = nil
        isLoaded = false
        loadedModel = nil
    }

    func transcribe(url: URL, initialPrompt: String? = nil) async throws -> TranscriptionResult {
        guard let context, isLoaded else {
            throw STTError.modelNotLoaded
        }

        let samples = try readPCMSamples(from: url)
        let langCode = mapLanguageCode(Settings.shared.language)
        let ctx = context

        let text = try await Task.detached {
            try Self.runTranscription(context: ctx, samples: samples, languageCode: langCode, initialPrompt: initialPrompt)
        }.value

        return TranscriptionResult(text: text)
    }

    nonisolated private static func runTranscription(
        context: WhisperContext,
        samples: [Float],
        languageCode: String,
        initialPrompt: String? = nil
    ) throws -> String {
        let maxThreads = max(1, min(8, ProcessInfo.processInfo.processorCount - 2))
        let ctx = context.pointer

        return try languageCode.withCString { lang in
            var params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY)
            params.print_realtime = false
            params.print_progress = false
            params.print_timestamps = false
            params.print_special = false
            params.translate = false
            params.language = lang
            params.n_threads = Int32(maxThreads)
            params.offset_ms = 0
            params.no_context = true
            params.single_segment = false
            params.no_timestamps = false
            params.temperature = 0.0
            params.suppress_blank = true
            params.carry_initial_prompt = initialPrompt != nil

            let result: Int32
            if let prompt = initialPrompt {
                result = prompt.withCString { promptPtr in
                    params.initial_prompt = promptPtr
                    return samples.withUnsafeBufferPointer { buf in
                        whisper_full(ctx, params, buf.baseAddress, Int32(buf.count))
                    }
                }
            } else {
                params.initial_prompt = nil
                result = samples.withUnsafeBufferPointer { buf in
                    whisper_full(ctx, params, buf.baseAddress, Int32(buf.count))
                }
            }

            guard result == 0 else {
                throw STTError.transcriptionFailed("whisper_full returned \(result)")
            }

            var text = ""
            let nSegments = whisper_full_n_segments(ctx)
            for i in 0..<nSegments {
                if let segment = whisper_full_get_segment_text(ctx, i) {
                    text += String(cString: segment)
                }
            }
            return text
        }
    }

    private func readPCMSamples(from url: URL) throws -> [Float] {
        let data = try Data(contentsOf: url)
        guard data.count > 44 else {
            throw STTError.audioReadFailed("File too small")
        }
        return stride(from: 44, to: data.count - 1, by: 2).map {
            let short = data[$0..<$0 + 2].withUnsafeBytes {
                Int16(littleEndian: $0.load(as: Int16.self))
            }
            return max(-1.0, min(Float(short) / 32767.0, 1.0))
        }
    }

    private func mapLanguageCode(_ lang: AppLanguage) -> String {
        switch lang {
        case .en: "en"
        case .ru: "ru"
        case .de: "de"
        case .fr: "fr"
        case .es: "es"
        case .it: "it"
        case .pt: "pt"
        case .nl: "nl"
        case .ja: "ja"
        case .ko: "ko"
        case .zh: "zh"
        case .ar: "ar"
        case .hi: "hi"
        case .uk: "uk"
        case .pl: "pl"
        case .tr: "tr"
        }
    }

    var needsDownload: Bool {
        !FileManager.default.fileExists(atPath: modelPath)
    }

    private func downloadModel(progressHandler: (@Sendable (Progress) -> Void)? = nil) async throws {
        let filename: String
        switch Settings.shared.whisperModel {
        case .small: filename = "ggml-small.bin"
        case .medium: filename = "ggml-medium.bin"
        case .largeV3: filename = "ggml-large-v3.bin"
        case .largeV3Turbo: filename = "ggml-large-v3-turbo.bin"
        }

        let baseURL = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main"
        guard let url = URL(string: "\(baseURL)/\(filename)") else {
            throw STTError.modelLoadFailed("Invalid download URL")
        }

        let destURL = Self.modelsDirectory.appendingPathComponent(filename)
        let progress = Progress(totalUnitCount: 1)
        let delegate = ModelDownloadDelegate(progress: progress, handler: progressHandler, destURL: destURL)
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)

        let finalURL: URL = try await withCheckedThrowingContinuation { continuation in
            delegate.setContinuation(continuation)
            session.downloadTask(with: url).resume()
        }

        session.finishTasksAndInvalidate()

        guard FileManager.default.fileExists(atPath: finalURL.path) else {
            throw STTError.modelLoadFailed(finalURL.path)
        }
    }
}
