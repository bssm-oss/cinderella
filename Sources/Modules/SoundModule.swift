import Foundation
import AppKit

final class SoundModule {
    static let shared = SoundModule()
    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleIntensity(_:)), name: .SchedulerDidUpdateIntensity, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNewEvent(_:)), name: .SchedulerDidAddNewEvent, object: nil)
    }

    @objc private func handleIntensity(_ n: Notification) {
        guard let level = n.object as? Int else { return }
        setGlobalSoundIntensity(level)
    }

    @objc private func handleNewEvent(_ n: Notification) {
        // Play a distinctive sound for new events
        playBeep(times: 2)
    }

    func play(_ id: String, volume: Float = 0.5) {
        // Simple: use NSBeep or NSSound named if available
        if let s = NSSound(named: NSSound.Name("Submarine")) {
            s.volume = volume
            s.play()
        } else {
            NSSound.beep()
        }
    }

    func stop(_ id: String) {
        // no-op for now
    }

    private func playBeep(times: Int) {
        for _ in 0..<times { DispatchQueue.main.async { NSSound.beep() } }
    }

    private func setGlobalSoundIntensity(_ level: Int) {
        // Optional: adjust frequency/volume of scheduled sounds
        print("[SoundModule] set intensity to \(level)")
    }
}

