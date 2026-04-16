import Foundation
import AppKit

protocol CinderellaEvent {
    var id: String { get }
    var name: String { get }
    var baseIntensity: Int { get }
    func apply(intensity: Int)
}

final class EventManager {
    static let shared = EventManager()
    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(onIntensity(_:)), name: .SchedulerDidUpdateIntensity, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onNewEvent(_:)), name: .SchedulerDidAddNewEvent, object: nil)
    }

    private var activeEvents: [CinderellaEvent] = []

    @objc private func onIntensity(_ n: Notification) {
        guard let level = n.object as? Int else { return }
        for e in activeEvents { e.apply(intensity: level) }
    }

    @objc private func onNewEvent(_ n: Notification) {
        // add events in sequence: first hide windows, then fullscreen, then others
        let elapsed = n.object as? Int ?? 0
        DispatchQueue.main.async {
            if elapsed == 0 { return }
            // choose an event based on elapsed or randomness
            if elapsed % 60 == 0 {
                self.activate(event: FullscreenWarning())
            } else {
                self.activate(event: HideWindowsEvent())
            }
        }
    }

    func activate(event: CinderellaEvent) {
        activeEvents.append(event)
        // apply immediately with current intensity
        event.apply(intensity: EventScheduler.shared.intensity)
    }

    func clearEvents() {
        activeEvents.removeAll()
    }
}
