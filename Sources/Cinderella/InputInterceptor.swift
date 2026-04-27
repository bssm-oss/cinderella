import Foundation
import CoreGraphics

final class InputInterceptor {
    static let shared = InputInterceptor()
    private init() {}

    private var eventTap: CFMachPort?
    private var substitutionMap: [Character: [Character]] = [:]
    private var substitutionEnabled = false

    func startIntercepting() {
        guard eventTap == nil else { return }
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        if let tap = CGEvent.tapCreate(tap: .cgSessionEventTap,
                                       place: .headInsertEventTap,
                                       options: .defaultTap,
                                       eventsOfInterest: mask,
                                       callback: { proxy, type, event, refcon in
            return InputInterceptor.handleEvent(proxy: proxy, type: type, event: event)
        }, userInfo: nil) {
            eventTap = tap
            let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
            CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
            print("[InputInterceptor] started")
        } else {
            print("[InputInterceptor] failed to create event tap (Accessibility needed)")
        }
    }

    func stopIntercepting() {
        if let tap = eventTap {
            CFMachPortInvalidate(tap)
            eventTap = nil
            print("[InputInterceptor] stopped")
        }
        substitutionEnabled = false
        substitutionMap = [:]
    }

    func disableSubstitution() {
        substitutionEnabled = false
        substitutionMap = [:]
        print("[InputInterceptor] substitution disabled (manual)")
    }

    static func handleEvent(proxy: CGEventTapProxy?, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        guard type == .keyDown else { return Unmanaged.passRetained(event) }
        let inst = InputInterceptor.shared
        if !inst.substitutionEnabled { return Unmanaged.passRetained(event) }

        // extract typed unicode string
        var length: Int = 0
        let maxLen = 4
        var buffer = [UniChar](repeating: 0, count: maxLen)
        event.keyboardGetUnicodeString(maxStringLength: maxLen, actualStringLength: &length, unicodeString: &buffer)
        if length <= 0 { return Unmanaged.passRetained(event) }
        let s = String(utf16CodeUnits: buffer, count: length)
        guard let ch = s.first?.lowercased().first else { return Unmanaged.passRetained(event) }

        if let subs = inst.substitutionMap[ch], !subs.isEmpty {
            // pick a random substitution
            let substitute = subs.randomElement()!
            // create new event with substituted unicode
            if let new = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true) {
                // copy flags
                new.flags = event.flags
                // set unicode string
                let uni = Array(substitute.utf16)
                uni.withUnsafeBufferPointer { buf in
                    new.keyboardSetUnicodeString(stringLength: buf.count, unicodeString: buf.baseAddress)
                }
                new.post(tap: .cghidEventTap)
            }
            // swallow original
            return nil
        }

        return Unmanaged.passRetained(event)
    }

    func enableSubstitution(map: [Character: [Character]], duration: TimeInterval) {
        substitutionMap = map
        substitutionEnabled = true
        startIntercepting()
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            guard let self = self else { return }
            self.substitutionEnabled = false
            self.substitutionMap = [:]
            print("[InputInterceptor] substitution disabled after duration")
        }
        print("[InputInterceptor] substitution enabled for \(duration)s")
    }
}
