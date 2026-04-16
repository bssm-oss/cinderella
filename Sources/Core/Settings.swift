import Foundation

// Settings: small wrapper around UserDefaults for WORK_END_TIME, ENABLED, IS_ACTIVE
enum Settings {
    static var workEndTime: String {
        get { UserDefaults.standard.string(forKey: "WORK_END_TIME") ?? "18:00" }
        set { UserDefaults.standard.set(newValue, forKey: "WORK_END_TIME") }
    }
}
