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
        for e in activeEvents { e.apply(intensity: level) }
    }

    @objc private func onNewEvent(_ n: Notification) {
        let elapsed = n.object as? Int ?? 0
        DispatchQueue.main.async {
            if elapsed == 0 { return }
            if elapsed % 60 == 0 {
                self.activate(event: FullscreenWarning())
            } else if elapsed % 30 == 0 {
                self.activate(event: KeySubstitutionEvent())
            } else {
                self.activate(event: HideWindowsEvent())
            }

        }
    }

    func activate(event: CinderellaEvent) {
        activeEvents.append(event)
        event.apply(intensity: EventScheduler.shared.intensity)
    }

    func clearEvents() {
        activeEvents.removeAll()
    }
}
