import Foundation
import AppKit

final class EventManager {
    static let shared = EventManager()

    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(onIntensity(_:)), name: .SchedulerDidUpdateIntensity, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onNewEvent(_:)), name: .SchedulerDidAddNewEvent, object: nil)
    }

    private var activeEvents: [CinderellaEvent] = []

    @objc private func onIntensity(_ notification: Notification) {
        guard let level = notification.object as? Int else { return }
        for event in activeEvents {
            event.apply(intensity: level)
        }
    }

    @objc private func onNewEvent(_ notification: Notification) {
        let elapsed = notification.object as? Int ?? 0
        guard elapsed > 0 else { return }

        if elapsed % 60 == 0 {
            activateIfEnabled(id: "fullscreen_warning")
        } else if elapsed % 30 == 0 {
            activateIfEnabled(id: "key_substitution")
        } else {
            activateIfEnabled(id: "hide_windows")
        }
    }

    func activate(event: CinderellaEvent) {
        // Replace existing event with the same id to avoid duplicate side effects.
        if activeEvents.contains(where: { $0.id == event.id }) {
            deactivate(eventId: event.id)
        }

        activeEvents.append(event)
        event.apply(intensity: EventScheduler.shared.intensity)
    }

    func deactivate(eventId: String) {
        for event in activeEvents where event.id == eventId {
            event.deactivate()
        }
        activeEvents.removeAll { $0.id == eventId }
    }

    func deactivateAll() {
        for event in activeEvents {
            event.deactivate()
        }
        activeEvents.removeAll()
    }

    func clearEvents() {
        activeEvents.removeAll()
    }

    private func activateIfEnabled(id: String) {
        guard UserDefaults.standard.bool(forKey: "event_enabled_\(id)") else { return }

        switch id {
        case "hide_windows": activate(event: HideWindowsEvent())
        case "fullscreen_warning": activate(event: FullscreenWarning())
        case "key_substitution": activate(event: KeySubstitutionEvent())
        case "cursor_jitter": activate(event: CursorJitterEvent())
        default: break
        }
    }
}
