import Foundation

enum Settings {
    static var workEndTime: String {
        get { UserDefaults.standard.string(forKey: "WORK_END_TIME") ?? "18:00" }
        set { UserDefaults.standard.set(newValue, forKey: "WORK_END_TIME") }
    }
    static var enabled: Bool {
        get { UserDefaults.standard.object(forKey: "ENABLED") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "ENABLED") }
    }
    static var isActive: Bool {
        get { UserDefaults.standard.object(forKey: "IS_ACTIVE") as? Bool ?? false }
        set { UserDefaults.standard.set(newValue, forKey: "IS_ACTIVE") }
    }
    static var intensityTickMin: Int {
        get { UserDefaults.standard.integer(forKey: "INTENSITY_TICK_MIN") == 0 ? 10 : UserDefaults.standard.integer(forKey: "INTENSITY_TICK_MIN") }
        set { UserDefaults.standard.set(newValue, forKey: "INTENSITY_TICK_MIN") }
    }
    static var eventIntensityStep: Int {
        get { UserDefaults.standard.integer(forKey: "EVENT_INTENSITY_STEP") == 0 ? 1 : UserDefaults.standard.integer(forKey: "EVENT_INTENSITY_STEP") }
        set { UserDefaults.standard.set(newValue, forKey: "EVENT_INTENSITY_STEP") }
    }
    static var newEventIntervalMin: Int {
        get { UserDefaults.standard.integer(forKey: "NEW_EVENT_INTERVAL_MIN") == 0 ? 30 : UserDefaults.standard.integer(forKey: "NEW_EVENT_INTERVAL_MIN") }
        set { UserDefaults.standard.set(newValue, forKey: "NEW_EVENT_INTERVAL_MIN") }
    }
}
