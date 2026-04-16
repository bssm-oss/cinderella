import Foundation

// SoundModule stub: play/stop sounds, set intensity
final class SoundModule {
    static let shared = SoundModule()
    private init() {}

    func play(_ id: String, volume: Float) {}
    func stop(_ id: String) {}
}
