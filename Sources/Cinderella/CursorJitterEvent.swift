import Foundation
import CoreGraphics

final class CursorJitterEvent: CinderellaEvent {
    let id = "cursor_jitter"
    let name = "Cursor Jitter"
    let baseIntensity = 1

    private var timer: DispatchSourceTimer?
    private var currentIntensity = 1
    private var currentInterval: TimeInterval = 0.40
    private var userInteractionUntil: Date = .distantPast
    private var lastJitterAnchor: CGPoint?
    private var lastJitterDistance: Int = 0

    func apply(intensity: Int) {
        currentIntensity = max(baseIntensity, intensity)
        ensureTimerRunning()
    }

    func deactivate() {
        timer?.cancel()
        timer = nil
    }

    private func ensureTimerRunning() {
        let isUserInteracting = Date() < userInteractionUntil
        let nextInterval = isUserInteracting ? 1.0 : computeInterval()
        guard timer == nil || abs(nextInterval - currentInterval) > 0.03 else { return }

        timer?.cancel()
        currentInterval = nextInterval

        let t = DispatchSource.makeTimerSource(queue: .main)
        t.schedule(deadline: .now() + currentInterval, repeating: currentInterval, leeway: .milliseconds(20))
        t.setEventHandler { [weak self] in
            guard let self = self else { return }
            guard Settings.isActive else { return }
            guard self.hasReachedWorkEndTime(), self.hasReachedWorkEndTimeByDate() else { return }
            guard let currentCursor = CGEvent(source: nil)?.location else { return }

            // If movement is larger than our own jitter radius, treat as user control and slow down.
            if let anchor = self.lastJitterAnchor {
                let moved = hypot(currentCursor.x - anchor.x, currentCursor.y - anchor.y)
                let userMoveThreshold = Double(self.lastJitterDistance + 10)
                if moved > userMoveThreshold {
                    self.userInteractionUntil = Date().addingTimeInterval(0.5)
                }
            }

            // As overtime grows, both jitter speed and distance increase.
            let level = max(self.currentIntensity, EventScheduler.shared.intensity)
            let overtimeBoost = min(2, self.overtimeMinutes() / 30)
            let distance = min(8, 2 + level / 2 + overtimeBoost)
            self.lastJitterAnchor = currentCursor
            self.lastJitterDistance = distance
            CursorModule.shared.jitter(distance: distance)

            // Re-check interval; during user input this becomes 1s, otherwise dynamic.
            self.ensureTimerRunning()
        }
        t.resume()
        timer = t
    }

    private func computeInterval() -> TimeInterval {
        // Base speed for shaking effect, still allowing user override control.
        let base: TimeInterval = 0.40

        // Shorten interval as intensity rises.
        let level = max(1, currentIntensity)
        let intensityShortening = min(0.08, Double(level - 1) * 0.015)

        // After work end time, shorten further as minutes pass (caps at 2 hours).
        let overtime = overtimeMinutes()
        let overtimeRatio = min(1.0, Double(overtime) / 120.0)
        let overtimeShortening = 0.08 * overtimeRatio

        // Keep jitter noticeable but always controllable.
        return max(0.22, base - intensityShortening - overtimeShortening)
    }

    private func overtimeMinutes() -> Int {
        let raw = Settings.workEndTime.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = raw.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]),
              (0...23).contains(hour),
              (0...59).contains(minute) else {
            return 0
        }

        let calendar = Calendar.current
        let now = Date()
        let nowTotal = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        let targetTotal = hour * 60 + minute
        return max(0, nowTotal - targetTotal)
    }

    private func hasReachedWorkEndTime() -> Bool {
        let raw = Settings.workEndTime.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = raw.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]),
              (0...23).contains(hour),
              (0...59).contains(minute) else {
            return false
        }

        let calendar = Calendar.current
        let now = Date()
        let nowTotal = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        let targetTotal = hour * 60 + minute
        return nowTotal >= targetTotal
    }

    private func hasReachedWorkEndTimeByDate() -> Bool {
        let raw = Settings.workEndTime.trimmingCharacters(in: .whitespacesAndNewlines)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "HH:mm"
        guard let parsed = formatter.date(from: raw) else { return false }

        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        let hm = calendar.dateComponents([.hour, .minute], from: parsed)
        components.hour = hm.hour
        components.minute = hm.minute
        components.second = 0

        guard let target = calendar.date(from: components) else { return false }
        return now >= target
    }

}
