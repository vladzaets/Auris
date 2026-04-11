import AVFoundation
import Foundation

@MainActor
final class AudioRecorder: NSObject, AVAudioRecorderDelegate {
    private var recorder: AVAudioRecorder?
    private(set) var isRecording = false
    private(set) var recordingURL: URL?
    private var recordingStartTime: Date?
    private var _finalDuration: TimeInterval = 0

    var duration: TimeInterval {
        if isRecording, let start = recordingStartTime {
            return Date().timeIntervalSince(start)
        }
        return _finalDuration
    }

    func startRecording() throws {
        guard !isRecording else { return }

        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "auris_\(Int(Date().timeIntervalSince1970 * 1000)).wav"
        let fileURL = tempDir.appendingPathComponent(fileName)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
        ]

        let audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
        audioRecorder.delegate = self
        audioRecorder.isMeteringEnabled = true

        guard audioRecorder.record() else {
            throw RecordingError.failedToStart
        }

        recorder = audioRecorder
        recordingURL = fileURL
        isRecording = true
        recordingStartTime = Date()
        _finalDuration = 0
    }

    func stopRecording() -> URL? {
        guard isRecording else { return nil }
        if let start = recordingStartTime {
            _finalDuration = Date().timeIntervalSince(start)
        }
        recorder?.stop()
        isRecording = false
        recordingStartTime = nil
        return recordingURL
    }

    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            if let start = self.recordingStartTime {
                self._finalDuration = Date().timeIntervalSince(start)
            }
            self.isRecording = false
            self.recordingStartTime = nil
        }
    }
}

enum RecordingError: LocalizedError {
    case failedToStart
    case recordingFailed
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .failedToStart: "Failed to start recording"
        case .recordingFailed: "Recording failed"
        case .permissionDenied: "Microphone permission denied"
        }
    }
}
