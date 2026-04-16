import Foundation

// EventScheduler skeleton: tick logic and intensity management
final class EventScheduler {
    static let shared = EventScheduler()
    private init() {}

    private var elapsedMinutes = 0
    private(set) var intensity = 0

    func start() {
        // start timer
    }
    func stop() {
        // stop timer
    }
}
