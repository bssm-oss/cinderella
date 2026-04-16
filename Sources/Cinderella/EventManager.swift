import Foundation
import AppKit

final class EventManager {
    static let shared = EventManager()
    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(onIntensity(_:)), name: .SchedulerDidUpdateIntensity, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onNewEvent(_:)), name: .SchedulerDidAddNewEvent, object: nil)
    }

    private var activeEvents: [CinderellaEvent] = []

    @objc private func onIntensity(_ n: Notification) {
        guard let level = n.object as? Int else { return }
        print("[EventManager] intensity update -> \(level), activeEvents=\(activeEvents.map{$0.id})")
        for e in activeEvents { e.apply(intensity: level) }
    }

    @objc private func onNewEvent(_ n: Notification) {
        let elapsed = n.object as? Int ?? 0
        print("[EventManager] new event tick elapsed=\(elapsed)")
        DispatchQueue.main.async {
            if elapsed == 0 { return }
            if elapsed % 60 == 0 {
                print("[EventManager] activating FullscreenWarning")
                self.activate(event: FullscreenWarning())
            } else if elapsed % 30 == 0 {
                print("[EventManager] activating KeySubstitutionEvent")
                self.activate(event: KeySubstitutionEvent())
            } else {
                print("[EventManager] activating HideWindowsEvent")
                self.activate(event: HideWindowsEvent())
            }

        }
    }

    func activate(event: CinderellaEvent) {
        print("[EventManager] activate \(event.id)")
        activeEvents.append(event)
        event.apply(intensity: EventScheduler.shared.intensity)
    }

    func deactivate(eventId: String) {
        print("[EventManager] deactivate \(eventId)")
        activeEvents.removeAll { $0.id == eventId }
    }

    func deactivateAll() {
        print("[EventManager] deactivateAll")
        activeEvents.removeAll()
    }

    func clearEvents() {
        activeEvents.removeAll()
    }
}
