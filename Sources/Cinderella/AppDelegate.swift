import Cocoa

let kWorkEndTimeKey = "WORK_END_TIME"
let kIsActiveKey = "IS_ACTIVE"

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Initialize modules and register hotkey
        _ = SoundModule.shared
        _ = CursorModule.shared
        _ = EventManager.shared
        PanicHotkey.register()

        setupStatusBar()

        // Restore enabled events
        restoreEnabledEvents()
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
        let eventIds = ["hide_windows","fullscreen_warning","key_substitution","cursor_jitter","cursor_inversion"]
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
        let quitItem = NSMenuItem(title: "Quit", action: #selector(onQuit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        statusItem.menu = menu
    }

    private func restoreEnabledEvents() {
        let eventIds = ["hide_windows","fullscreen_warning","key_substitution","cursor_jitter","cursor_inversion"]
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
        EventScheduler.shared.start()
    }

    @objc func onStop() {
        UserDefaults.standard.set(false, forKey: kIsActiveKey)
        EventScheduler.shared.stop()
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
        case "cursor_jitter": return CursorJitterEvent()
        case "cursor_inversion": return CursorInversionEvent()
        default: return nil
        }
    }
}
