import Foundation
import AppKit

final class HideWindowsEvent: CinderellaEvent {
    let id = "hide_windows"
    let name = "Hide All Windows"
    let baseIntensity = 1

    private var hiddenProcessIDs = Set<pid_t>()

    func apply(intensity: Int) {
        hiddenProcessIDs.removeAll()

        for app in NSWorkspace.shared.runningApplications {
            if app.bundleIdentifier == Bundle.main.bundleIdentifier { continue }
            if !app.isFinishedLaunching || app.isTerminated || app.isHidden { continue }

            hiddenProcessIDs.insert(app.processIdentifier)
            app.hide()
        }

        SoundModule.shared.play(id: "hide_windows", volume: 0.5)
    }

    func deactivate() {
        guard !hiddenProcessIDs.isEmpty else { return }

        for app in NSWorkspace.shared.runningApplications where hiddenProcessIDs.contains(app.processIdentifier) {
            if !app.isTerminated {
                app.unhide()
            }
        }
        hiddenProcessIDs.removeAll()
    }
}
