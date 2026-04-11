import AppKit
import Foundation

enum SoundPlayer {
    static let availableSounds = [
        "Basso", "Blow", "Bottle", "Frog", "Funk",
        "Glass", "Hero", "Morse", "Ping", "Pop",
        "Purr", "Sosumi", "Submarine", "Tink",
    ]

    static func play(_ name: String?) {
        guard let name else { return }
        if let sound = NSSound(named: name) {
            sound.play()
        }
    }
}
