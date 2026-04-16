import Cocoa

let kWorkEndTimeKey = "WORK_END_TIME"
let kIsActiveKey = "IS_ACTIVE"

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusController: Any?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Initialize modules and register hotkey
        _ = SoundModule.shared
        _ = CursorModule.shared
        PanicHotkey.register()
        // Note: UI code exists in other files; minimal runtime ready
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        PanicHotkey.unregister()
        InputInterceptor.shared.stopIntercepting()
    }
}
