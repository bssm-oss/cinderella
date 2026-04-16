import Foundation
import AppKit

final class HideWindowsEvent: CinderellaEvent {
    let id = "hide_windows"
    let name = "Hide All Windows"
    let baseIntensity = 1

    func apply(intensity: Int) {
        // Hide other running applications to force attention to 'go home' message
        let apps = NSWorkspace.shared.runningApplications
        for app in apps {
            // skip this app
            if app.bundleIdentifier == Bundle.main.bundleIdentifier { continue }
            // try to hide
            if app.isFinishedLaunching && !app.isTerminated {
                app.hide()
            }
        }
        // Also optionally play a short sound
        SoundModule.shared.play(id: "hide_windows", volume: 0.5)
    }
}
