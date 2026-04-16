import Cocoa

let kWorkEndTimeKey = "WORK_END_TIME"
let kIsActiveKey = "IS_ACTIVE"

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("[AppDelegate] didFinishLaunching, env: \(ProcessInfo.processInfo.environment)")
        // Initialize modules and register hotkey
        _ = SoundModule.shared
        _ = CursorModule.shared
        _ = EventManager.shared
        PanicHotkey.register()

        setupStatusBar()

        // Restore enabled events
        restoreEnabledEvents()

        // Dev: allow forcing scheduler start with env var CINDERELLA_FORCE_START=1
        if ProcessInfo.processInfo.environment["CINDERELLA_FORCE_START"] == "1" {
            print("[AppDelegate] forcing scheduler start (dev)")
            EventScheduler.shared.startMonitoring(force: true)
            // activate demo events that don't require Accessibility
            UserDefaults.standard.set(true, forKey: "event_enabled_fullscreen_warning")
            UserDefaults.standard.set(true, forKey: "event_enabled_hide_windows")
            EventManager.shared.activate(event: FullscreenWarning())
            EventManager.shared.activate(event: HideWindowsEvent())

            // write an explicit marker to the logfile so users can see activity without Accessibility
            let logPath = "/tmp/cinderella.log"
            let marker = "DEMO_STARTED: \(Date())\n"
            if let data = marker.data(using: .utf8) {
                if FileManager.default.fileExists(atPath: logPath) {
                    if let fh = FileHandle(forWritingAtPath: logPath) {
                        fh.seekToEndOfFile()
                        fh.write(data)
                        try? fh.close()
                    }
                } else {
                    FileManager.default.createFile(atPath: logPath, contents: data, attributes: [FileAttributeKey.posixPermissions: 0o644])
                }
            }

            // show a quick user-visible alert and beep so the tester notices the app started
            DispatchQueue.main.async {
                NSSound.beep()
                let alert = NSAlert()
                alert.messageText = "Cinderella (demo) started"
                alert.informativeText = "Demo events activated: FullscreenWarning, HideWindows. Close this alert to continue."
                alert.runModal()

                // show stronger fullscreen overlay demo (repeated) so it's visible without Accessibility
                self.showStrongDemoOverlay(repeatCount: 2, interval: 3)
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        PanicHotkey.unregister()
        InputInterceptor.shared.stopIntercepting()
    }

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatusTitle()
        let menu = NSMenu()
        let startItem = NSMenuItem(title: "Start (출근)", action: #selector(onStart), keyEquivalent: "s")
        startItem.target = self
        let stopItem = NSMenuItem(title: "Stop (퇴근)", action: #selector(onStop), keyEquivalent: "t")
        stopItem.target = self
        menu.addItem(startItem)
        menu.addItem(stopItem)

        menu.addItem(.separator())

        // Events submenu
        let eventsItem = NSMenuItem(title: "Events", action: nil, keyEquivalent: "")
        let eventsSubmenu = NSMenu(title: "Events")
        let eventIds = ["hide_windows","fullscreen_warning","key_substitution"]
        for id in eventIds {
            let title = id.replacingOccurrences(of: "_", with: " ")
            let item = NSMenuItem(title: title, action: #selector(toggleEvent(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = id
            item.state = UserDefaults.standard.bool(forKey: "event_enabled_\(id)") ? .on : .off
            item.isEnabled = true
            eventsSubmenu.addItem(item)
        }
        // add disable all
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

        let quitSep = NSMenuItem.separator()
        menu.addItem(quitSep)

        let quitItem = NSMenuItem(title: "Quit", action: #selector(onQuit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        statusItem.menu = menu
    }

    private func restoreEnabledEvents() {
        let eventIds = ["hide_windows","fullscreen_warning","key_substitution"]
        for id in eventIds where UserDefaults.standard.bool(forKey: "event_enabled_\(id)") {
            if let ev = makeEvent(id: id) { EventManager.shared.activate(event: ev) }
        }
    }

    private func updateStatusTitle() {
        let workEnd = UserDefaults.standard.string(forKey: kWorkEndTimeKey) ?? "18:00"
        statusItem.button?.title = "퇴근 \(workEnd)"
    }

    @objc func onStart() {
        UserDefaults.standard.set(true, forKey: kIsActiveKey)
        EventScheduler.shared.startMonitoring()
    }

    @objc func onStop() {
        UserDefaults.standard.set(false, forKey: kIsActiveKey)
        EventScheduler.shared.stopMonitoring()
    }

    @objc func onQuit() {
        NSApp.terminate(nil)
    }

    @objc func toggleEvent(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        let newState = sender.state == .on ? false : true
        sender.state = newState ? .on : .off
        UserDefaults.standard.set(newState, forKey: "event_enabled_\(id)")
        if newState {
            // activate event immediately
            if let ev = makeEvent(id: id) { EventManager.shared.activate(event: ev) }
        } else {
            EventManager.shared.deactivate(eventId: id)
        }
    }

    @objc func disableAllEvents() {
        let menu = statusItem.menu
        menu?.items.forEach { item in
            if let submenu = item.submenu {
                for si in submenu.items where si.representedObject != nil {
                    si.state = .off
                    if let id = si.representedObject as? String {
                        UserDefaults.standard.set(false, forKey: "event_enabled_\(id)")
                    }
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
        default: return nil
        }
    }

    @objc func showPreferences() {
        let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 360, height: 220), styleMask: [.titled, .closable], backing: .buffered, defer: false)
        w.title = "Cinderella Preferences"

        let content = NSView(frame: NSRect(x: 0, y: 0, width: 360, height: 220))

        let label = NSTextField(labelWithString: "Work end time (HH:mm):")
        label.frame = NSRect(x: 16, y: 170, width: 200, height: 20)
        content.addSubview(label)

        let tf = NSTextField(string: UserDefaults.standard.string(forKey: kWorkEndTimeKey) ?? "18:00")
        tf.frame = NSRect(x: 16, y: 140, width: 120, height: 24)
        tf.identifier = NSUserInterfaceItemIdentifier("pref_work_end")
        content.addSubview(tf)

        // event checkboxes
        let eventIds = ["hide_windows","fullscreen_warning","key_substitution"]
        var y = 100
        for id in eventIds {
            let title = id.replacingOccurrences(of: "_", with: " ")
            let cb = NSButton(checkboxWithTitle: title, target: self, action: #selector(prefCheckboxToggled(_:)))
            cb.frame = NSRect(x: 16, y: y, width: 300, height: 20)
            cb.state = UserDefaults.standard.bool(forKey: "event_enabled_\(id)") ? .on : .off
            cb.identifier = NSUserInterfaceItemIdentifier(id)
            content.addSubview(cb)
            y -= 28
        }

        let saveBtn = NSButton(title: "Save", target: self, action: #selector(prefSaveAndClose(_:)))
        saveBtn.frame = NSRect(x: 200, y: 12, width: 70, height: 30)
        content.addSubview(saveBtn)

        let closeBtn = NSButton(title: "Close", target: self, action: #selector(prefClose(_:)))
        closeBtn.frame = NSRect(x: 280, y: 12, width: 70, height: 30)
        content.addSubview(closeBtn)

        w.contentView = content
        w.center()
        w.makeKeyAndOrderFront(nil)
    }

    @objc func prefCheckboxToggled(_ sender: NSButton) {
        guard let id = sender.identifier?.rawValue else { return }
        let enabled = sender.state == .on
        UserDefaults.standard.set(enabled, forKey: "event_enabled_\(id)")
        if enabled {
            if let ev = makeEvent(id: id) { EventManager.shared.activate(event: ev) }
        } else {
            EventManager.shared.deactivate(eventId: id)
        }
    }

    @objc func prefSaveAndClose(_ sender: NSButton) {
        guard let window = sender.window, let tf = window.contentView?.subviews.first(where: { $0.identifier?.rawValue == "pref_work_end" }) as? NSTextField else { return }
        let s = tf.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        UserDefaults.standard.set(s, forKey: kWorkEndTimeKey)
        updateStatusTitle()
        window.close()
    }

    @objc func prefClose(_ sender: NSButton) {
        sender.window?.close()
    }

    // Strong visual demo overlay used in dev mode (no Accessibility required)
    func showStrongDemoOverlay(repeatCount: Int = 1, interval: TimeInterval = 2) {
        DispatchQueue.main.async {
            guard let screenFrame = NSScreen.main?.frame else { return }
            let w = NSWindow(contentRect: screenFrame, styleMask: .borderless, backing: .buffered, defer: false)
            w.level = .screenSaver
            w.isOpaque = false
            w.backgroundColor = NSColor(calibratedWhite: 0, alpha: 0.85)
            w.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

            let tv = NSTextField(labelWithString: "집에 가세요!")
            tv.font = NSFont.systemFont(ofSize: 120, weight: .bold)
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

            w.makeKeyAndOrderFront(nil)

            // show overlay for a short time and optionally repeat
            var remaining = repeatCount
            let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { t in
                remaining -= 1
                if remaining <= 0 {
                    w.orderOut(nil)
                    t.invalidate()
                } else {
                    // briefly flash by bringing to front again
                    w.orderFrontRegardless()
                }
            }
            RunLoop.main.add(timer, forMode: .common)
        }
    }
}
