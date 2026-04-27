import Foundation
import AppKit

final class FullscreenWarning: CinderellaEvent {
    let id = "fullscreen_warning"
    let name = "Fullscreen Warning"
    let baseIntensity = 2

    private var window: NSWindow?
    private var repeatTimer: Timer?
    private var lastShownAt: Date?
    private var keyMonitor: Any?
    private var canShowWarning = false

    private let warningInterval: TimeInterval = 5 * 60
    private let checkInterval: TimeInterval = 30
    private let warningDuration: TimeInterval = 15

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(onSchedulerIntensity(_:)), name: .SchedulerDidUpdateIntensity, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onSchedulerStop), name: .SchedulerDidStop, object: nil)
    }

    func apply(intensity: Int) {
        DispatchQueue.main.async {
            self.ensureTimerRunning()
            self.showWarningIfNeeded(force: true)
        }
    }

    private func ensureTimerRunning() {
        guard repeatTimer == nil else { return }
        let timer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { [weak self] _ in
            self?.showWarningIfNeeded(force: false)
        }
        RunLoop.main.add(timer, forMode: .common)
        repeatTimer = timer
    }

    private func showWarningIfNeeded(force: Bool) {
        guard Settings.isActive else { return }
        guard canShowWarning else { return }
        guard hasReachedWorkEndTime() else { return }

        if !force, let lastShownAt, Date().timeIntervalSince(lastShownAt) < warningInterval {
            return
        }
        showWarning(duration: warningDuration)
    }

    private func showWarning(duration: TimeInterval) {
        guard window == nil else { return }
        let screenFrame = NSScreen.main?.frame ?? NSRect(x:0,y:0,width:800,height:600)
        let w = NSWindow(contentRect: screenFrame, styleMask: .borderless, backing: .buffered, defer: false)
        w.level = .statusBar
        w.isOpaque = false
        w.backgroundColor = NSColor(calibratedWhite: 0, alpha: 0.85)
        w.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let tv = NSTextField(labelWithString: "집에 가세요!")
        tv.font = NSFont.systemFont(ofSize: 96, weight: .bold)
        tv.textColor = .white
        tv.alignment = .center
        tv.translatesAutoresizingMaskIntoConstraints = false

        let content = NSView(frame: screenFrame)
        content.addSubview(tv)
        w.contentView = content

        NSLayoutConstraint.activate([
            tv.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            tv.centerYAnchor.constraint(equalTo: content.centerYAnchor)
        ])

        window = w
        lastShownAt = Date()
        w.makeKeyAndOrderFront(nil)

        // dismiss on click or ESC
        let gesture = NSClickGestureRecognizer(target: self, action: #selector(dismiss))
        content.addGestureRecognizer(gesture)

        if keyMonitor == nil {
            keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] ev in
                if ev.keyCode == 53 { // ESC
                    self?.dismiss()
                    return nil
                }
                return ev
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.dismiss()
        }

        // play a warning sound
        SoundModule.shared.play(id: "warning", volume: 0.8)
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

        let now = Date()
        let calendar = Calendar.current
        let nowTotal = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        let targetTotal = hour * 60 + minute
        return nowTotal >= targetTotal
    }

    @objc private func onSchedulerIntensity(_ notification: Notification) {
        // SchedulerDidUpdateIntensity is only posted after work-end condition is met.
        canShowWarning = true
    }

    @objc private func onSchedulerStop() {
        canShowWarning = false
    }

    @objc private func dismiss() {
        window?.orderOut(nil)
        window = nil
    }

    func deactivate() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.repeatTimer?.invalidate()
            self.repeatTimer = nil
            self.lastShownAt = nil
            self.canShowWarning = false
            if let keyMonitor = self.keyMonitor {
                NSEvent.removeMonitor(keyMonitor)
                self.keyMonitor = nil
            }
            self.dismiss()
        }
    }
}
