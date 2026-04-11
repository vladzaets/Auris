import CoreGraphics
import Foundation

final class HotkeyManager: @unchecked Sendable {
    private var onStart: @Sendable () -> Void
    private var onStop: @Sendable () -> Void
    private var hotkey: RecordingHotkey
    private var keyPressed = false
    private var runLoop: CFRunLoop?
    private var tapOK = false
    private let lock = NSLock()

    private let fnFlag: CGEventFlags = CGEventFlags(rawValue: 0x800000)

    init(hotkey: RecordingHotkey, onStart: @Sendable @escaping () -> Void, onStop: @Sendable @escaping () -> Void) {
        self.hotkey = hotkey
        self.onStart = onStart
        self.onStop = onStop
    }

    var isListening: Bool {
        lock.lock()
        defer { lock.unlock() }
        return tapOK
    }

    func start() {
        let t = Thread(target: self, selector: #selector(runTap), object: nil)
        t.name = "Auris Hotkey"
        t.start()
    }

    func stop() {
        lock.lock()
        let rl = runLoop
        lock.unlock()
        if let rl {
            CFRunLoopStop(rl)
        }
        lock.lock()
        runLoop = nil
        lock.unlock()
    }

    func setHotkey(_ newHotkey: RecordingHotkey) {
        stop()
        lock.lock()
        hotkey = newHotkey
        keyPressed = false
        lock.unlock()
        start()
    }

    @objc private func runTap() {
        let eventMask: CGEventMask = (1 << CGEventType.flagsChanged.rawValue)

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: eventMask,
            callback: { proxy, type, event, userInfo -> Unmanaged<CGEvent>? in
                guard let userInfo else { return Unmanaged.passRetained(event) }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(userInfo).takeUnretainedValue()
                manager.handleEvent(type: type, event: event)
                return Unmanaged.passRetained(event)
            },
            userInfo: selfPtr
        ) else {
            return
        }

        let source = CFMachPortCreateRunLoopSource(nil, tap, 0)
        let rl = CFRunLoopGetCurrent()
        CFRunLoopAddSource(rl, source, .defaultMode)
        CGEvent.tapEnable(tap: tap, enable: true)

        lock.lock()
        tapOK = true
        runLoop = rl
        lock.unlock()

        CFRunLoopRun()

        lock.lock()
        tapOK = false
        lock.unlock()
    }

    private func handleEvent(type: CGEventType, event: CGEvent) {
        lock.lock()
        let currentHotkey = hotkey
        lock.unlock()

        switch currentHotkey {
        case .fn:
            handleFn(event: event)
        case .rightOption:
            handleKeycode(event: event, targetKeycode: 61)
        case .rightCommand:
            handleKeycode(event: event, targetKeycode: 54)
        }
    }

    private func handleFn(event: CGEvent) {
        let flags = event.flags
        let fnNow = flags.contains(fnFlag)

        lock.lock()
        let wasPressed = keyPressed
        lock.unlock()

        if fnNow && !wasPressed {
            lock.lock()
            keyPressed = true
            lock.unlock()
            onStart()
        } else if !fnNow && wasPressed {
            lock.lock()
            keyPressed = false
            lock.unlock()
            onStop()
        }
    }

    private func handleKeycode(event: CGEvent, targetKeycode: Int64) {
        let keycode = event.getIntegerValueField(.keyboardEventKeycode)
        guard keycode == targetKeycode else { return }

        lock.lock()
        let wasPressed = keyPressed
        lock.unlock()

        if !wasPressed {
            lock.lock()
            keyPressed = true
            lock.unlock()
            onStart()
        } else {
            lock.lock()
            keyPressed = false
            lock.unlock()
            onStop()
        }
    }
}
