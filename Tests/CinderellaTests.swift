import XCTest
@testable import Cinderella

final class SettingsTests: XCTestCase {
    private let keys = [
        "WORK_END_TIME",
        "ENABLED",
        "IS_ACTIVE",
        "INTENSITY_TICK_MIN",
        "EVENT_INTENSITY_STEP",
        "NEW_EVENT_INTERVAL_MIN"
    ]

    override func setUp() {
        super.setUp()
        clearKeys()
    }

    override func tearDown() {
        clearKeys()
        super.tearDown()
    }

    func testSettingsDefaultValues() {
        XCTAssertEqual(Settings.workEndTime, "18:00")
        XCTAssertEqual(Settings.enabled, true)
        XCTAssertEqual(Settings.isActive, false)
        XCTAssertEqual(Settings.intensityTickMin, 10)
        XCTAssertEqual(Settings.eventIntensityStep, 1)
        XCTAssertEqual(Settings.newEventIntervalMin, 30)
    }

    func testSettingsPersistedValues() {
        Settings.workEndTime = "19:30"
        Settings.enabled = false
        Settings.isActive = true
        Settings.intensityTickMin = 5
        Settings.eventIntensityStep = 3
        Settings.newEventIntervalMin = 15

        XCTAssertEqual(Settings.workEndTime, "19:30")
        XCTAssertEqual(Settings.enabled, false)
        XCTAssertEqual(Settings.isActive, true)
        XCTAssertEqual(Settings.intensityTickMin, 5)
        XCTAssertEqual(Settings.eventIntensityStep, 3)
        XCTAssertEqual(Settings.newEventIntervalMin, 15)
    }

    private func clearKeys() {
        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}

final class EventManagerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        EventManager.shared.deactivateAll()
    }

    override func tearDown() {
        EventManager.shared.deactivateAll()
        super.tearDown()
    }

    func testDeactivateStopsApplyingEvent() {
        let event = TestEvent(id: "test_event")

        EventManager.shared.activate(event: event)
        NotificationCenter.default.post(name: .SchedulerDidUpdateIntensity, object: 1)

        XCTAssertEqual(event.applyCount, 2)

        EventManager.shared.deactivate(eventId: event.id)
        NotificationCenter.default.post(name: .SchedulerDidUpdateIntensity, object: 2)

        XCTAssertEqual(event.applyCount, 2)
        XCTAssertEqual(event.deactivateCount, 1)
    }
}

private final class TestEvent: CinderellaEvent {
    let id: String
    let name = "test"
    let baseIntensity = 1

    private(set) var applyCount = 0
    private(set) var deactivateCount = 0

    init(id: String) {
        self.id = id
    }

    func apply(intensity: Int) {
        applyCount += 1
    }

    func deactivate() {
        deactivateCount += 1
    }
}
