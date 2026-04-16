import Foundation
import CoreGraphics

final class CursorModule {
    static let shared = CursorModule()
    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleIntensity(_:)), name: .SchedulerDidUpdateIntensity, object: nil)
    }

    @objc private func handleIntensity(_ n: Notification) {
        guard let level = n.object as? Int else { return }
        // Increase jitter frequency based on level
        print("[CursorModule] intensity -> \(level)")
    }

    func jitter(distance: Int) {
        let loc = CGEvent(source: nil)?.location ?? .zero
        let dx = Int.random(in: -distance...distance)
        let dy = Int.random(in: -distance...distance)
        let new = CGPoint(x: Int(loc.x) + dx, y: Int(loc.y) + dy)
        CGWarpMouseCursorPosition(new)
    }

    func swapIconTemporarily() {
        // Placeholder: real cursor image swap requires NSCursor APIs
        print("[CursorModule] swap icon temporarily")
    }

    func invertMovement(duration: TimeInterval) {
        // Complex: would require intercepting mouse deltas; placeholder
        print("[CursorModule] invert movement for \(duration)s")
    }
}

