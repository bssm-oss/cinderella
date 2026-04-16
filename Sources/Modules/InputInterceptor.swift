import Foundation
import CoreGraphics

final class InputInterceptor {
    static let shared = InputInterceptor()
    private init() {}

    private var eventTap: CFMachPort?

    func startIntercepting() {
        guard eventTap == nil else { return }
        let mask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        if let tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap, eventsOfInterest: CGEventMask(mask), callback: { proxy, type, event, refcon in
            if type == .keyDown {
                let kc = event.getIntegerValueField(.keyboardEventKeycode)
                // keycode mapping for i,o,u varies by layout; for demo, do nothing
                // Could substitute chars by posting new events (requires careful handling)
            }
            return Unmanaged.passRetained(event)
        }, userInfo: nil) {
            eventTap = tap
            let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
            CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
            print("[InputInterceptor] started")
        } else {
            print("[InputInterceptor] failed to create event tap (accessibility needed)")
        }
    }

    func stopIntercepting() {
        if let tap = eventTap {
            CFMachPortInvalidate(tap)
            eventTap = nil
            print("[InputInterceptor] stopped")
        }
    }
}
