import XCTest
import EventKit
@testable import EazyCal

final class CalendarMathTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testVisibleMonthIntervalCrossesYearBoundary() throws {
        let date = try XCTUnwrap(CalendarMath.date(year: 2025, month: 1, day: 15, calendar: calendar))
        let interval = try CalendarMath.visibleMonthInterval(containing: date, calendar: calendar)

        XCTAssertEqual(calendar.dateComponents([.year, .month, .day], from: interval.start), DateComponents(year: 2024, month: 12, day: 1))
        XCTAssertEqual(calendar.dateComponents([.year, .month, .day], from: interval.end), DateComponents(year: 2025, month: 3, day: 1))
    }

    func testMovingDatePreservesTime() throws {
        let source = try XCTUnwrap(CalendarMath.date(year: 2024, month: 12, day: 31, hour: 23, minute: 45, calendar: calendar))
        let target = try XCTUnwrap(CalendarMath.date(year: 2025, month: 2, day: 2, calendar: calendar))
        let moved = try XCTUnwrap(CalendarMath.moving(source, toDay: target, calendar: calendar))

        XCTAssertEqual(
            calendar.dateComponents([.year, .month, .day, .hour, .minute], from: moved),
            DateComponents(year: 2025, month: 2, day: 2, hour: 23, minute: 45)
        )
    }

    func testOverlappingSchedulesUseDifferentLayers() throws {
        let firstStart = try XCTUnwrap(CalendarMath.date(year: 2025, month: 1, day: 10, calendar: calendar))
        let firstEnd = try XCTUnwrap(CalendarMath.date(year: 2025, month: 1, day: 13, calendar: calendar))
        let secondStart = try XCTUnwrap(CalendarMath.date(year: 2025, month: 1, day: 12, calendar: calendar))
        let secondEnd = try XCTUnwrap(CalendarMath.date(year: 2025, month: 1, day: 14, calendar: calendar))

        let result = CalendarMath.layerAssignments(
            for: [
                .init(index: 0, start: firstStart, end: firstEnd),
                .init(index: 1, start: secondStart, end: secondEnd)
            ],
            calendar: calendar
        )

        XCTAssertEqual(result, [1, 2])
    }

    func testSameMonthAndDayInDifferentYearsCanReuseLayer() throws {
        let first = try XCTUnwrap(CalendarMath.date(year: 2024, month: 1, day: 10, calendar: calendar))
        let second = try XCTUnwrap(CalendarMath.date(year: 2025, month: 1, day: 10, calendar: calendar))

        let result = CalendarMath.layerAssignments(
            for: [
                .init(index: 0, start: first, end: first.addingTimeInterval(3600)),
                .init(index: 1, start: second, end: second.addingTimeInterval(3600))
            ],
            calendar: calendar
        )

        XCTAssertEqual(result, [1, 1])
    }
}

final class EventRuleTests: XCTestCase {
    func testOneDayHasNoRecurrenceRule() {
        XCTAssertNil(RecurrenceRuleFactory.rules(for: .oneDay))
    }

    func testYearlyRecurrenceDoesNotExpireAfterEightWeeks() throws {
        let rule = try XCTUnwrap(RecurrenceRuleFactory.rules(for: .everyYear)?.first)
        XCTAssertEqual(rule.frequency, .yearly)
        XCTAssertNil(rule.recurrenceEnd)
    }

    func testReminderPriorities() {
        XCTAssertEqual(ReminderPriority.priority(for: String(localized: "LOW")), 9)
        XCTAssertEqual(ReminderPriority.priority(for: String(localized: "MID")), 5)
        XCTAssertEqual(ReminderPriority.priority(for: String(localized: "HIGH")), 1)
        XCTAssertEqual(ReminderPriority.priority(for: "unknown"), 0)
    }
}

final class ReminderScheduleTests: XCTestCase {
    func testMovingAllDayReminderKeepsItAllDay() throws {
        let components = DateComponents(year: 2025, month: 1, day: 3)
        let targetDate = try XCTUnwrap(CalendarMath.date(year: 2025, month: 2, day: 7))

        let moved = ReminderSchedule.moving(components, toDay: targetDate)

        XCTAssertEqual(moved.year, 2025)
        XCTAssertEqual(moved.month, 2)
        XCTAssertEqual(moved.day, 7)
        XCTAssertNil(moved.hour)
        XCTAssertNil(moved.minute)
    }

    func testEventEntryUsesExclusiveEndDateForDisplay() throws {
        let event = EKEvent(eventStore: EKEventStore())
        event.startDate = try XCTUnwrap(CalendarMath.date(year: 2025, month: 1, day: 3))
        event.endDate = try XCTUnwrap(CalendarMath.date(year: 2025, month: 1, day: 4))

        let entry = CalendarEntry(event: event)

        XCTAssertEqual(
            Calendar.current.component(.day, from: entry.endDate),
            3
        )
    }
}

@MainActor
final class EventStoreManagerTests: XCTestCase {
    func testPrepareLoadsEachAuthorizedDataSource() async throws {
        let store = FakeEventStore()
        let suiteName = "EventStoreManagerTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let manager = EventStoreManager(eventStore: store, userDefaults: defaults)

        await manager.prepare()

        XCTAssertEqual(store.calendarLoadCount, 1)
        XCTAssertEqual(store.eventLoadCount, 1)
        XCTAssertEqual(store.upcomingLoadCount, 1)
        XCTAssertEqual(store.reminderLoadCount, 1)
        XCTAssertEqual(store.scheduledReminderLoadCount, 1)
    }

    func testReminderMutationReloadsReminders() async throws {
        let store = FakeEventStore()
        let suiteName = "EventStoreManagerTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let manager = EventStoreManager(eventStore: store, userDefaults: defaults)

        try await manager.createNewReminder(title: "Test", date: nil, highlight: "unknown")

        XCTAssertEqual(store.createReminderCount, 1)
        XCTAssertEqual(store.reminderLoadCount, 1)
        XCTAssertEqual(store.scheduledReminderLoadCount, 1)
    }

    func testReschedulingReminderPreservesTimeAndReloadsReminderData() async throws {
        let store = FakeEventStore()
        let suiteName = "EventStoreManagerTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let manager = EventStoreManager(eventStore: store, userDefaults: defaults)
        let reminder = EKReminder(eventStore: EKEventStore())
        reminder.dueDateComponents = DateComponents(
            year: 2025,
            month: 1,
            day: 3,
            hour: 14,
            minute: 25
        )
        let targetDate = try XCTUnwrap(CalendarMath.date(year: 2025, month: 2, day: 7))

        try await manager.rescheduleReminder(reminder, to: targetDate)

        XCTAssertEqual(reminder.dueDateComponents?.year, 2025)
        XCTAssertEqual(reminder.dueDateComponents?.month, 2)
        XCTAssertEqual(reminder.dueDateComponents?.day, 7)
        XCTAssertEqual(reminder.dueDateComponents?.hour, 14)
        XCTAssertEqual(reminder.dueDateComponents?.minute, 25)
        XCTAssertEqual(store.updateReminderCount, 1)
        XCTAssertEqual(store.reminderLoadCount, 1)
        XCTAssertEqual(store.scheduledReminderLoadCount, 1)
    }

    func testCalendarRefreshStillLoadsRemindersWhenEventLoadingFails() async {
        let store = FakeEventStore()
        store.shouldFailEventLoading = true
        let suiteName = "EventStoreManagerTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            return XCTFail("Unable to create isolated user defaults")
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let manager = EventStoreManager(eventStore: store, userDefaults: defaults)

        await manager.refreshCalendarEntries()

        XCTAssertEqual(store.eventLoadCount, 1)
        XCTAssertEqual(store.scheduledReminderLoadCount, 1)
        XCTAssertNotNil(manager.lastErrorMessage)
    }
}

private final class FakeEventStore: EventStoreProviding {
    var calendarAuthorizationStatus: EKAuthorizationStatus = .fullAccess
    var reminderAuthorizationStatus: EKAuthorizationStatus = .fullAccess
    var calendarLoadCount = 0
    var eventLoadCount = 0
    var upcomingLoadCount = 0
    var reminderLoadCount = 0
    var scheduledReminderLoadCount = 0
    var createReminderCount = 0
    var updateReminderCount = 0
    var shouldFailEventLoading = false

    func requestCalendarAccess() async throws -> Bool { true }
    func requestReminderAccess() async throws -> Bool { true }

    func loadCalendars() async throws -> [EKCalendar] {
        calendarLoadCount += 1
        return []
    }

    func loadUpcomingEvents() async throws -> [EKEvent] {
        upcomingLoadCount += 1
        return []
    }

    func loadEvents(forDate date: Date, calendars: [EKCalendar]) async throws -> [EKEvent] {
        eventLoadCount += 1
        if shouldFailEventLoading {
            throw EventStoreError.unknown
        }
        return []
    }

    func loadAllReminders() async throws -> [EKReminder] {
        reminderLoadCount += 1
        return []
    }

    func loadScheduledReminders(from startDate: Date, to endDate: Date) async throws -> [EKReminder] {
        scheduledReminderLoadCount += 1
        return []
    }

    func completeReminder(reminder: EKReminder) async throws {}
    func updateReminder(reminder: EKReminder) async throws {
        updateReminderCount += 1
    }

    func createNewReminder(title: String, date: Date?, highlight: String) async throws {
        createReminderCount += 1
    }

    func createNewCalendar() async throws {}
    func updateCalendar(calendar: EKCalendar) async throws {}
    func removeCalendar(calendar: EKCalendar) async throws {}
    func saveEvent(title: String, isAllDay: Bool, startDate: Date, endDate: Date, repeatDate: RepeatType, url: URL?, notes: [String], calendar: EKCalendar) async throws {}
    func updateEvent(event: EKEvent) async throws {}
    func removeEvent(event: EKEvent) async throws {}
}
