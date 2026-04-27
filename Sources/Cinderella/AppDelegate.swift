import Cocoa

let kWorkEndTimeKey = "WORK_END_TIME"
let kIsActiveKey = "IS_ACTIVE"
let kOverdueMessageKey = "OVERDUE_MESSAGE"
let kDefaultOverdueMessage = "퇴근해야 해요"

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var statusItem: NSStatusItem!
    private var preferencesWindowController: NSWindowController?
    private var statusRefreshTimer: Timer?
    private var isWorkingNow = false
    private weak var prefWorkEndField: NSTextField?
    private weak var prefOverdueMessageField: NSTextField?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        UserDefaults.standard.set(false, forKey: kIsActiveKey)

        // Initialize modules early so notification observers are active.
        _ = SoundModule.shared
        _ = CursorModule.shared
        _ = EventManager.shared
        PanicHotkey.register()
        NotificationCenter.default.addObserver(self, selector: #selector(onSchedulerDidStart), name: .SchedulerDidStart, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onSchedulerDidStop), name: .SchedulerDidStop, object: nil)

        setupStatusBar()
        writeStatusDiagnostics(reason: "after-setup")

        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.accessory)
            self.updateStatusTitle()
            self.startStatusRefreshTimer()
            self.writeStatusDiagnostics(reason: "after-launch")
        }

        restoreEnabledEvents()

        if ProcessInfo.processInfo.environment["CINDERELLA_FORCE_START"] == "1" {
            EventScheduler.shared.startMonitoring(force: true)
            UserDefaults.standard.set(true, forKey: "event_enabled_fullscreen_warning")
            UserDefaults.standard.set(true, forKey: "event_enabled_hide_windows")
            UserDefaults.standard.set(true, forKey: "event_enabled_cursor_jitter")
            EventManager.shared.activate(event: FullscreenWarning())
            EventManager.shared.activate(event: HideWindowsEvent())
            EventManager.shared.activate(event: CursorJitterEvent())

            if ProcessInfo.processInfo.environment["CINDERELLA_FORCE_OVERLAY"] == "1" {
                showStrongDemoOverlay(repeatCount: 2, interval: 3)
            }
        }
    }

    private func writeStatusDiagnostics(reason: String) {
        let path = "/tmp/cinderella_status.log"
        var lines: [String] = []
        lines.append("time=\(Date()) reason=\(reason)")
        lines.append("policy=\(NSApp.activationPolicy().rawValue)")
        if let button = statusItem?.button {
            lines.append("button=true")
            lines.append("title=\(button.title)")
            lines.append("hasImage=\(button.image != nil)")
            lines.append("isVisible=\(statusItem.isVisible)")
            lines.append("length=\(statusItem.length)")
        } else {
            lines.append("button=false")
        }
        lines.append("")
        let text = lines.joined(separator: "\n")
        if let data = text.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: path),
               let handle = FileHandle(forWritingAtPath: path) {
                handle.seekToEndOfFile()
                handle.write(data)
                try? handle.close()
            } else {
                FileManager.default.createFile(atPath: path, contents: data)
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        statusRefreshTimer?.invalidate()
        statusRefreshTimer = nil
        PanicHotkey.unregister()
        InputInterceptor.shared.stopIntercepting()
    }

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.isVisible = true
        statusItem.button?.image = nil
        statusItem.button?.alternateImage = nil
        statusItem.button?.imagePosition = .noImage

        let menu = NSMenu()

        let startItem = NSMenuItem(title: "Start (출근)", action: #selector(onStart), keyEquivalent: "s")
        startItem.target = self
        menu.addItem(startItem)

        let stopItem = NSMenuItem(title: "Stop (퇴근)", action: #selector(onStop), keyEquivalent: "t")
        stopItem.target = self
        menu.addItem(stopItem)

        menu.addItem(.separator())

        let eventsItem = NSMenuItem(title: "Events", action: nil, keyEquivalent: "")
        let eventsSubmenu = NSMenu(title: "Events")
        let eventIds = ["hide_windows", "fullscreen_warning", "key_substitution", "cursor_jitter"]
        for id in eventIds {
            let title = id.replacingOccurrences(of: "_", with: " ")
            let item = NSMenuItem(title: title, action: #selector(toggleEvent(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = id
            item.state = UserDefaults.standard.bool(forKey: "event_enabled_\(id)") ? .on : .off
            eventsSubmenu.addItem(item)
        }

        eventsSubmenu.addItem(.separator())
        let disableAll = NSMenuItem(title: "Disable All Events", action: #selector(disableAllEvents), keyEquivalent: "")
        disableAll.target = self
        eventsSubmenu.addItem(disableAll)

        eventsItem.submenu = eventsSubmenu
        menu.addItem(eventsItem)

        menu.addItem(.separator())

        let prefsItem = NSMenuItem(title: "Preferences...", action: #selector(showPreferences), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(onQuit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        updateStatusTitle()
    }

    private func restoreEnabledEvents() {
        let eventIds = ["hide_windows", "fullscreen_warning", "key_substitution", "cursor_jitter"]
        for id in eventIds where UserDefaults.standard.bool(forKey: "event_enabled_\(id)") {
            if let event = makeEvent(id: id) {
                EventManager.shared.activate(event: event)
            }
        }
    }

    private func updateStatusTitle() {
        let workEnd = UserDefaults.standard.string(forKey: kWorkEndTimeKey) ?? "18:00"
        let isOverTime = hasReachedWorkEndTime()
        let overdueRaw = (UserDefaults.standard.string(forKey: kOverdueMessageKey) ?? kDefaultOverdueMessage)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let overdueMessage = overdueRaw.isEmpty ? kDefaultOverdueMessage : overdueRaw
        let suffix: String
        if isWorkingNow && isOverTime {
            suffix = " (\(overdueMessage))"
        } else if isWorkingNow {
            suffix = " (근무중)"
        } else {
            suffix = ""
        }
        statusItem.button?.image = nil
        statusItem.button?.alternateImage = nil
        statusItem.button?.imagePosition = .noImage

        let text = "퇴근 \(workEnd)\(suffix)"
        let color: NSColor = (isWorkingNow && isOverTime) ? .systemRed : .labelColor
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: color,
            .font: NSFont.systemFont(ofSize: 12, weight: .semibold)
        ]
        let textWidth = (text as NSString).size(withAttributes: attributes).width
        statusItem.length = max(NSStatusItem.variableLength, textWidth + 18)
        statusItem.button?.title = ""
        statusItem.button?.attributedTitle = NSAttributedString(string: text, attributes: attributes)
    }

    private func startStatusRefreshTimer() {
        statusRefreshTimer?.invalidate()
        statusRefreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.updateStatusTitle()
        }
        if let timer = statusRefreshTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func hasReachedWorkEndTime() -> Bool {
        let raw = (UserDefaults.standard.string(forKey: kWorkEndTimeKey) ?? "18:00")
            .trimmingCharacters(in: .whitespacesAndNewlines)
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
        let nowHour = calendar.component(.hour, from: now)
        let nowMinute = calendar.component(.minute, from: now)

        let nowTotal = nowHour * 60 + nowMinute
        let targetTotal = hour * 60 + minute
        return nowTotal >= targetTotal
    }

    @objc func onStart() {
        EventScheduler.shared.startMonitoring()
    }

    @objc func onStop() {
        EventScheduler.shared.stopMonitoring()
    }

    @objc private func onSchedulerDidStart() {
        UserDefaults.standard.set(true, forKey: kIsActiveKey)
        isWorkingNow = true
        updateStatusTitle()
    }

    @objc private func onSchedulerDidStop() {
        UserDefaults.standard.set(false, forKey: kIsActiveKey)
        isWorkingNow = false
        updateStatusTitle()
    }

    @objc func onQuit() {
        NSApp.terminate(nil)
    }

    @objc func toggleEvent(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }

        let newState = sender.state != .on
        sender.state = newState ? .on : .off
        UserDefaults.standard.set(newState, forKey: "event_enabled_\(id)")

        if newState {
            if let event = makeEvent(id: id) {
                EventManager.shared.activate(event: event)
            }
        } else {
            EventManager.shared.deactivate(eventId: id)
        }
    }

    @objc func disableAllEvents() {
        statusItem.menu?.items.forEach { item in
            guard let submenu = item.submenu else { return }
            for subItem in submenu.items where subItem.representedObject != nil {
                subItem.state = .off
                if let id = subItem.representedObject as? String {
                    UserDefaults.standard.set(false, forKey: "event_enabled_\(id)")
                }
            }
        }
        EventManager.shared.deactivateAll()
    }

    private func makeEvent(id: String) -> CinderellaEvent? {
        switch id {
        case "hide_windows": return HideWindowsEvent()
        case "fullscreen_warning": return FullscreenWarning()
        case "key_substitution": return KeySubstitutionEvent()
        case "cursor_jitter": return CursorJitterEvent()
        default: return nil
        }
    }

    @objc func showPreferences() {
        if let existing = preferencesWindowController?.window {
            NSApp.activate(ignoringOtherApps: true)
            existing.makeKeyAndOrderFront(nil)
            existing.orderFrontRegardless()
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 220),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Cinderella Preferences"

        let content = NSView(frame: NSRect(x: 0, y: 0, width: 360, height: 220))

        let label = NSTextField(labelWithString: "Work end time (HH:mm):")
        label.frame = NSRect(x: 16, y: 170, width: 200, height: 20)
        content.addSubview(label)

        let timeField = NSTextField(string: UserDefaults.standard.string(forKey: kWorkEndTimeKey) ?? "18:00")
        timeField.frame = NSRect(x: 16, y: 142, width: 120, height: 24)
        timeField.identifier = NSUserInterfaceItemIdentifier("pref_work_end")
        content.addSubview(timeField)
        prefWorkEndField = timeField

        let messageLabel = NSTextField(labelWithString: "After work-end message:")
        messageLabel.frame = NSRect(x: 16, y: 106, width: 240, height: 20)
        content.addSubview(messageLabel)

        let messageField = NSTextField(string: UserDefaults.standard.string(forKey: kOverdueMessageKey) ?? kDefaultOverdueMessage)
        messageField.frame = NSRect(x: 16, y: 78, width: 328, height: 24)
        messageField.identifier = NSUserInterfaceItemIdentifier("pref_overdue_message")
        content.addSubview(messageField)
        prefOverdueMessageField = messageField

        let saveButton = NSButton(title: "Save", target: self, action: #selector(prefSaveAndClose(_:)))
        saveButton.frame = NSRect(x: 200, y: 12, width: 70, height: 30)
        content.addSubview(saveButton)

        let closeButton = NSButton(title: "Close", target: self, action: #selector(prefClose(_:)))
        closeButton.frame = NSRect(x: 280, y: 12, width: 70, height: 30)
        content.addSubview(closeButton)

        window.contentView = content
        window.delegate = self
        window.isReleasedWhenClosed = false
        window.center()
        preferencesWindowController = NSWindowController(window: window)
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }

    @objc func prefSaveAndClose(_ sender: NSButton) {
        persistPreferences()
        sender.window?.close()
    }

    @objc func prefClose(_ sender: NSButton) {
        persistPreferences()
        sender.window?.close()
    }

    func windowWillClose(_ notification: Notification) {
        guard notification.object as? NSWindow === preferencesWindowController?.window else { return }
        prefWorkEndField = nil
        prefOverdueMessageField = nil
        preferencesWindowController = nil
        updateStatusTitle()
        statusItem.isVisible = true
    }

    private func persistPreferences() {
        let value = prefWorkEndField?.stringValue.trimmingCharacters(in: .whitespacesAndNewlines) ?? (UserDefaults.standard.string(forKey: kWorkEndTimeKey) ?? "18:00")
        let rawMessage = prefOverdueMessageField?.stringValue.trimmingCharacters(in: .whitespacesAndNewlines) ?? (UserDefaults.standard.string(forKey: kOverdueMessageKey) ?? kDefaultOverdueMessage)
        let message = rawMessage.isEmpty ? kDefaultOverdueMessage : rawMessage
        UserDefaults.standard.set(value, forKey: kWorkEndTimeKey)
        UserDefaults.standard.set(message, forKey: kOverdueMessageKey)
        updateStatusTitle()
    }

    func showStrongDemoOverlay(repeatCount: Int = 1, interval: TimeInterval = 2) {
        DispatchQueue.main.async {
            guard let screenFrame = NSScreen.main?.frame else { return }

            let window = NSWindow(contentRect: screenFrame, styleMask: .borderless, backing: .buffered, defer: false)
            window.level = .screenSaver
            window.isOpaque = false
            window.backgroundColor = NSColor(calibratedWhite: 0, alpha: 0.85)
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

            let titleView = NSTextField(labelWithString: "집에 가세요!")
            titleView.font = NSFont.systemFont(ofSize: 120, weight: .bold)
            titleView.textColor = .white
            titleView.alignment = .center
            titleView.translatesAutoresizingMaskIntoConstraints = false

            let content = NSView(frame: screenFrame)
            content.addSubview(titleView)
            window.contentView = content

            NSLayoutConstraint.activate([
                titleView.centerXAnchor.constraint(equalTo: content.centerXAnchor),
                titleView.centerYAnchor.constraint(equalTo: content.centerYAnchor)
            ])

            window.makeKeyAndOrderFront(nil)

            var remaining = repeatCount
            let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
                remaining -= 1
                if remaining <= 0 {
                    window.orderOut(nil)
                    timer.invalidate()
                } else {
                    window.orderFrontRegardless()
                }
            }
            RunLoop.main.add(timer, forMode: .common)
        }
    }
}
