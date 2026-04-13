import Foundation

enum WhisperModel: String, CaseIterable, Codable {
    case small
    case medium
    case largeV3 = "large-v3"
    case largeV3Turbo = "large-v3-turbo"

    var displayName: String {
        switch self {
        case .small: "small (~500 MB)"
        case .medium: "medium (~1.5 GB)"
        case .largeV3: "large-v3 (~3 GB)"
        case .largeV3Turbo: "large-v3-turbo (~1.5 GB)"
        }
    }
}

enum RecordingHotkey: String, CaseIterable, Codable {
    case fn
    case rightOption = "right_option"
    case rightCommand = "right_command"

    var displayName: String {
        switch self {
        case .fn: "Fn"
        case .rightOption: "Right Option (\u{2325})"
        case .rightCommand: "Right Command (\u{2318})"
        }
    }
}

enum AppLanguage: String, CaseIterable, Codable {
    case en, ru, de, fr, es, it, pt, nl, ja, ko, zh, ar, hi, uk, pl, tr

    var displayName: String {
        switch self {
        case .en: "English"
        case .ru: "Русский"
        case .de: "Deutsch"
        case .fr: "Français"
        case .es: "Español"
        case .it: "Italiano"
        case .pt: "Português"
        case .nl: "Nederlands"
        case .ja: "日本語"
        case .ko: "한국어"
        case .zh: "中文"
        case .ar: "العربية"
        case .hi: "हिन्दी"
        case .uk: "Українська"
        case .pl: "Polski"
        case .tr: "Türkçe"
        }
    }
}

struct StoredSettings: Codable {
    var language: String = AppLanguage.en.rawValue
    var whisperModel: String = WhisperModel.largeV3Turbo.rawValue
    var recordingHotkey: String = RecordingHotkey.fn.rawValue
    var postProcessingEnabled: Bool = true
    var initialPromptEnabled: Bool = true
    var collectTrainingData: Bool = true
    var soundStart: String? = "Pop"
    var soundStop: String? = "Basso"
    var soundError: String? = "Basso"
    var soundComplete: String? = "Hero"
    var pasteDelaySeconds: Double = 0.05
    var clipboardRestoreDelaySeconds: Double = 0.2
    var historyRetentionDays: Int = 0
    var startAtLogin: Bool = false
}

final class Settings: @unchecked Sendable {
    static let shared = Settings()

    private(set) var isFirstLaunch: Bool
    private var stored: StoredSettings

    var language: AppLanguage {
        get { AppLanguage(rawValue: stored.language) ?? .en }
        set { stored.language = newValue.rawValue; save() }
    }
    var whisperModel: WhisperModel {
        get { WhisperModel(rawValue: stored.whisperModel) ?? .largeV3Turbo }
        set { stored.whisperModel = newValue.rawValue; save() }
    }
    var recordingHotkey: RecordingHotkey {
        get { RecordingHotkey(rawValue: stored.recordingHotkey) ?? .fn }
        set { stored.recordingHotkey = newValue.rawValue; save() }
    }
    var postProcessingEnabled: Bool {
        get { stored.postProcessingEnabled }
        set { stored.postProcessingEnabled = newValue; save() }
    }
    var initialPromptEnabled: Bool {
        get { stored.initialPromptEnabled }
        set { stored.initialPromptEnabled = newValue; save() }
    }
    var collectTrainingData: Bool {
        get { stored.collectTrainingData }
        set { stored.collectTrainingData = newValue; save() }
    }
    var soundStart: String? {
        get { stored.soundStart }
        set { stored.soundStart = newValue; save() }
    }
    var soundStop: String? {
        get { stored.soundStop }
        set { stored.soundStop = newValue; save() }
    }
    var soundError: String? {
        get { stored.soundError }
        set { stored.soundError = newValue; save() }
    }
    var soundComplete: String? {
        get { stored.soundComplete }
        set { stored.soundComplete = newValue; save() }
    }
    var pasteDelaySeconds: Double {
        get { stored.pasteDelaySeconds }
        set { stored.pasteDelaySeconds = newValue; save() }
    }
    var clipboardRestoreDelaySeconds: Double {
        get { stored.clipboardRestoreDelaySeconds }
        set { stored.clipboardRestoreDelaySeconds = newValue; save() }
    }
    var historyRetentionDays: Int {
        get { stored.historyRetentionDays }
        set { stored.historyRetentionDays = newValue; save() }
    }
    var startAtLogin: Bool {
        get { stored.startAtLogin }
        set { stored.startAtLogin = newValue; save() }
    }

    private init() {
        AppConstants.ensureDataDir()
        Self.migrateFromUserDefaults()
        let loaded = Self.loadFromDisk()
        isFirstLaunch = loaded == nil
        stored = loaded ?? StoredSettings()
        if isFirstLaunch { save() }
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        guard let data = try? encoder.encode(stored) else { return }
        try? data.write(to: AppConstants.settingsFile, options: .atomic)
    }

    private static func loadFromDisk() -> StoredSettings? {
        guard let data = try? Data(contentsOf: AppConstants.settingsFile) else { return nil }
        return try? JSONDecoder().decode(StoredSettings.self, from: data)
    }

    private static func migrateFromUserDefaults() {
        let defaults = UserDefaults.standard
        let key = "auris_settings_migrated"
        guard !defaults.bool(forKey: key) else { return }

        var s = StoredSettings()
        s.language = defaults.string(forKey: "language") ?? s.language
        s.whisperModel = defaults.string(forKey: "whisperModel") ?? s.whisperModel
        s.recordingHotkey = defaults.string(forKey: "recordingHotkey") ?? s.recordingHotkey
        if let v = defaults.object(forKey: "postProcessingEnabled") as? Bool { s.postProcessingEnabled = v }
        if let v = defaults.object(forKey: "collectTrainingData") as? Bool { s.collectTrainingData = v }
        if let v = defaults.string(forKey: "soundStart") { s.soundStart = v }
        if let v = defaults.string(forKey: "soundStop") { s.soundStop = v }
        if let v = defaults.string(forKey: "soundError") { s.soundError = v }
        if let v = defaults.string(forKey: "soundComplete") { s.soundComplete = v }
        let pds = defaults.double(forKey: "pasteDelaySeconds")
        if pds != 0 { s.pasteDelaySeconds = pds }
        let crds = defaults.double(forKey: "clipboardRestoreDelaySeconds")
        if crds != 0 { s.clipboardRestoreDelaySeconds = crds }
        let hrd = defaults.integer(forKey: "historyRetentionDays")
        if hrd != 0 { s.historyRetentionDays = hrd }
        if let v = defaults.object(forKey: "startAtLogin") as? Bool { s.startAtLogin = v }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        if let data = try? encoder.encode(s) {
            try? data.write(to: AppConstants.settingsFile, options: .atomic)
        }
        defaults.set(true, forKey: key)
    }
}
