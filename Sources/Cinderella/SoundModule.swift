import Foundation
import AVFoundation

final class SoundModule {
    static let shared = SoundModule()
    private init() {
        do { try AVAudioSession.sharedInstance().setCategory(.playback) } catch {}
        NotificationCenter.default.addObserver(self, selector: #selector(handleIntensity(_:)), name: .SchedulerDidUpdateIntensity, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNewEvent(_:)), name: .SchedulerDidAddNewEvent, object: nil)
    }

    private var players: [String: AVAudioPlayer] = [:]

    @objc private func handleIntensity(_ n: Notification) {
        guard let level = n.object as? Int else { return }
        setGlobalSoundIntensity(level)
    }

    @objc private func handleNewEvent(_ n: Notification) {
        play(id: "event_tone", loops: 0, volume: 0.6)
    }

    func play(id: String, resource: String? = nil, ext: String? = "wav", loops: Int = 0, volume: Float = 0.5) {
        // resource: if nil, try builtin mapping
        let resourceName = resource ?? id
        if let p = players[id] {
            p.volume = volume
            p.numberOfLoops = loops
            p.play()
            return
        }

        if let url = Bundle.main.url(forResource: resourceName, withExtension: ext) {
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.volume = volume
                player.numberOfLoops = loops
                player.prepareToPlay()
                player.play()
                players[id] = player
            } catch {
                print("[SoundModule] failed to play resource: \(resourceName). Error: \(error)")
            }
        } else {
            // fallback to system beep
            NSSound.beep()
        }
    }

    func stop(id: String) {
        if let p = players[id] { p.stop(); players.removeValue(forKey: id) }
    }

    private func setGlobalSoundIntensity(_ level: Int) {
        // Example policy: increase volume of background loop per level
        let vol = min(1.0, 0.2 + Float(level) * 0.08)
        for (_, p) in players { p.volume = vol }
        print("[SoundModule] global volume -> \(vol) for level \(level)")
    }
}
