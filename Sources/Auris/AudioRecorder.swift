import AVFoundation
import Foundation

@MainActor
final class AudioRecorder: NSObject, AVAudioRecorderDelegate {
    private var recorder: AVAudioRecorder?
    private(set) var isRecording = false
    private(set) var recordingURL: URL?
    private var _duration: TimeInterval = 0
    private var durationTimer: Timer?

    var duration: TimeInterval { _duration }

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
        _duration = 0
        startDurationTimer()
    }

    func stopRecording() -> URL? {
        guard isRecording else { return nil }
        stopDurationTimer()
        recorder?.stop()
        isRecording = false
        return recordingURL
    }

    private func startDurationTimer() {
        durationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.isRecording else { return }
                self._duration = self.recorder?.currentTime ?? 0
            }
        }
    }

    private func stopDurationTimer() {
        durationTimer?.invalidate()
        durationTimer = nil
    }

    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            self.isRecording = false
            self.stopDurationTimer()
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
