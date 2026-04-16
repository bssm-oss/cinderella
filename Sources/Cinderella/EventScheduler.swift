import Foundation
import AppKit

final class EventScheduler {
    static let shared = EventScheduler()
    private init() {}

    private var timer: DispatchSourceTimer?
    private var elapsedMinutes = 0
    private(set) var intensity = 0
    private var forceStart = false
    private let queue = DispatchQueue(label: "cinderella.scheduler")

    func startMonitoring(force: Bool = false) {
        stopMonitoring()
        elapsedMinutes = 0
        intensity = 1
        forceStart = force

        timer = DispatchSource.makeTimerSource(queue: queue)
        let fast = ProcessInfo.processInfo.environment["CINDERELLA_FAST_TICK"] == "1"
        let interval = fast ? 1 : 60
        timer?.schedule(deadline: .now(), repeating: .seconds(interval))
        timer?.setEventHandler { [weak self] in
            self?.tick()
        }
        timer?.resume()
        NotificationCenter.default.post(name: .SchedulerDidStart, object: nil)
    }

    func stopMonitoring() {
        timer?.cancel()
        timer = nil
        intensity = 0
        elapsedMinutes = 0
        forceStart = false
        NotificationCenter.default.post(name: .SchedulerDidStop, object: nil)
    }

    private func tick() {
        // allow dev forceStart to run even if Settings.isActive is false
        guard Settings.enabled && (Settings.isActive || forceStart) else { return }
        guard hasReachedWorkEndTime() || forceStart else { return }

        elapsedMinutes += 1

        let tickMin = max(1, Settings.intensityTickMin)
        let step = max(1, Settings.eventIntensityStep)

        if elapsedMinutes % tickMin == 0 {
            intensity += step
            DispatchQueue.main.async { [level = intensity] in
                NotificationCenter.default.post(name: .SchedulerDidUpdateIntensity, object: level)
            }
        }

        let newEventInterval = Settings.newEventIntervalMin
        if newEventInterval > 0 && elapsedMinutes % newEventInterval == 0 {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .SchedulerDidAddNewEvent, object: self.elapsedMinutes)
            }
        }
    }

    private func hasReachedWorkEndTime() -> Bool {
        let s = Settings.workEndTime
        let fmt = DateFormatter(); fmt.dateFormat = "HH:mm"
        guard let target = fmt.date(from: s) else { return false }
        let cal = Calendar.current
        var components = cal.dateComponents([.year,.month,.day], from: Date())
        let tComps = cal.dateComponents([.hour,.minute], from: target)
        components.hour = tComps.hour; components.minute = tComps.minute
        guard let targetDate = cal.date(from: components) else { return false }
        return Date() >= targetDate
    }
}

extension Notification.Name {
    static let SchedulerDidStart = Notification.Name("SchedulerDidStart")
    static let SchedulerDidStop = Notification.Name("SchedulerDidStop")
    static let SchedulerDidUpdateIntensity = Notification.Name("SchedulerDidUpdateIntensity")
    static let SchedulerDidAddNewEvent = Notification.Name("SchedulerDidAddNewEvent")
}
