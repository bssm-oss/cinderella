import Foundation

// CursorModule stub: jitter, icon swap, inversion
final class CursorModule {
    static let shared = CursorModule()
    private init() {}

    func jitter(distance: Int) {}
    func swapIconTemporarily() {}
    func invertMovement(duration: TimeInterval) {}
}
