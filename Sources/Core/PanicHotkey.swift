import Foundation
import CoreGraphics

final class PanicHotkey {
    private static var tap: CFMachPort?

    static func register() {
        guard tap == nil else { return }
        let mask = (1 << CGEventType.keyDown.rawValue)
        if let t = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap, eventsOfInterest: CGEventMask(mask), callback: { proxy, type, event, refcon in
            if type == .keyDown {
                let keycode = event.getIntegerValueField(.keyboardEventKeycode)
                let flags = event.flags
                // ESC keycode is 53 on macOS
                if keycode == 53 && flags.contains(.maskControl) && flags.contains(.maskAlternate) && flags.contains(.maskCommand) && flags.contains(.maskShift) {
                    // Stop scheduler
                    DispatchQueue.main.async {
                        EventScheduler.shared.stopMonitoring()
                    }
                }
            }
            return Unmanaged.passRetained(event)
        }, userInfo: nil) {
            tap = t
            let src = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, t, 0)
            CFRunLoopAddSource(CFRunLoopGetMain(), src, .commonModes)
            CGEvent.tapEnable(tap: t, enable: true)
            print("[PanicHotkey] registered")
        } else {
            print("[PanicHotkey] failed to register (Accessibility may be required)")
        }
    }

    static func unregister() {
        if let t = tap {
            CFMachPortInvalidate(t)
            tap = nil
        }
    }
}
