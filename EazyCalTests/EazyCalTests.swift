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
        XCTAssertEqual(ReminderPriority.low.rawValue, 9)
        XCTAssertEqual(ReminderPriority.medium.rawValue, 5)
        XCTAssertEqual(ReminderPriority.high.rawValue, 1)
        XCTAssertEqual(ReminderPriority(eventKitValue: 0), .none)
        XCTAssertEqual(ReminderPriority(eventKitValue: 3), .high)
        XCTAssertEqual(ReminderPriority(eventKitValue: 7), .low)
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
        let event = EventItem(
            id: "event",
            calendar: CalendarItem(id: "calendar", title: "Calendar", color: .clear),
            title: "Event",
            isAllDay: true,
            startDate: try XCTUnwrap(CalendarMath.date(year: 2025, month: 1, day: 3)),
            endDate: try XCTUnwrap(CalendarMath.date(year: 2025, month: 1, day: 4)),
            repeatType: .oneDay,
            url: nil,
            notes: ""
        )

        let entry = CalendarEntryMapper.map(event)

        XCTAssertEqual(
            Calendar.current.component(.day, from: entry.endDate),
            3
        )
    }
}

final class MonthCalendarStateTests: XCTestCase {
    func testCategoryFilterKeepsRemindersVisible() throws {
        let date = try XCTUnwrap(CalendarMath.date(year: 2025, month: 2, day: 7))
        let entries = [
            makeEntry(id: "first", kind: .event, calendarIdentifier: "work", date: date),
            makeEntry(id: "second", kind: .event, calendarIdentifier: "home", date: date),
            makeEntry(id: "reminder", kind: .reminder, calendarIdentifier: nil, date: date)
        ]

        let state = MonthCalendarState(
            entries: entries,
            filter: .calendars(["work"])
        )

        XCTAssertEqual(state.entries.map(\.entry.id), ["first", "reminder"])
    }

    func testEntriesReturnsOnlyItemsCoveringRequestedDay() throws {
        let firstDay = try XCTUnwrap(CalendarMath.date(year: 2025, month: 2, day: 7))
        let secondDay = try XCTUnwrap(CalendarMath.date(year: 2025, month: 2, day: 8))
        let state = MonthCalendarState(
            entries: [
                makeEntry(id: "first", kind: .event, calendarIdentifier: "work", date: firstDay),
                makeEntry(id: "second", kind: .event, calendarIdentifier: "work", date: secondDay)
            ],
            filter: .all
        )

        XCTAssertEqual(state.entries(on: firstDay).map(\.entry.id), ["first"])
    }

    private func makeEntry(
        id: String,
        kind: CalendarEntryKind,
        calendarIdentifier: String?,
        date: Date
    ) -> CalendarEntry {
        CalendarEntry(
            id: id,
            sourceIdentifier: id,
            kind: kind,
            calendarIdentifier: calendarIdentifier,
            title: id,
            startDate: date,
            endDate: date,
            isAllDay: true
        )
    }
}

@MainActor
final class EventStorePermissionStoreTests: XCTestCase {
    func testReminderPermissionIsRequestedWhenCalendarPermissionRequestFails() async {
        let repository = FakeEventStore()
        repository.calendarAuthorizationStatus = .notDetermined
        repository.reminderAuthorizationStatus = .notDetermined
        repository.shouldFailCalendarAccessRequest = true
        let store = EventStorePermissionStore(
            calendarRepository: repository,
            reminderRepository: repository
        )

        await store.requestAccess()

        XCTAssertEqual(repository.calendarAccessRequestCount, 1)
        XCTAssertEqual(repository.reminderAccessRequestCount, 1)
        XCTAssertEqual(store.calendarAuthorizationStatus, .notDetermined)
        XCTAssertEqual(store.reminderAuthorizationStatus, .fullAccess)
        XCTAssertNotNil(store.lastErrorMessage)
    }
}

@MainActor
final class CalendarFeatureStoreTests: XCTestCase {
    func testReloadPublishesDataAndInitializesVisibleCalendars() async throws {
        let repository = FakeEventStore()
        let workCalendar = CalendarItem(id: "work", title: "Work", color: .clear)
        let homeCalendar = CalendarItem(id: "home", title: "Home", color: .clear)
        let event = EventItem(
            id: "event",
            calendar: workCalendar,
            title: "Meeting",
            isAllDay: false,
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            repeatType: .oneDay,
            url: nil,
            notes: ""
        )
        repository.calendarsResult = [workCalendar, homeCalendar]
        repository.eventsResult = [event]
        repository.upcomingEventsResult = [event]
        let suiteName = "CalendarFeatureStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = CalendarFeatureStore(repository: repository, userDefaults: defaults)

        await store.reloadAll()

        XCTAssertEqual(store.calendars, [workCalendar, homeCalendar])
        XCTAssertEqual(store.events, [event])
        XCTAssertEqual(store.upcomingEvents, [event])
        XCTAssertEqual(repository.lastRequestedCalendarIdentifiers, ["work", "home"])

        await store.setCalendar(identifier: "home", isChecked: false)

        XCTAssertFalse(store.isCalendarChecked(identifier: "home"))
        XCTAssertEqual(repository.lastRequestedCalendarIdentifiers, ["work"])
    }

    func testEventLoadingFailureIsRecordedByCalendarStore() async throws {
        let repository = FakeEventStore()
        repository.shouldFailEventLoading = true
        let suiteName = "CalendarFeatureStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = CalendarFeatureStore(repository: repository, userDefaults: defaults)

        await store.refreshEvents()

        XCTAssertNotNil(store.lastErrorMessage)
    }
}

@MainActor
final class ReminderFeatureStoreTests: XCTestCase {
    func testReloadPublishesAllAndScheduledReminders() async {
        let repository = FakeEventStore()
        let allReminder = ReminderItem(
            id: "all",
            title: "All",
            priority: .none,
            dueDateComponents: nil,
            isCompleted: false,
            color: .clear
        )
        let scheduledReminder = ReminderItem(
            id: "scheduled",
            title: "Scheduled",
            priority: .medium,
            dueDateComponents: Calendar.current.dateComponents(
                [.year, .month, .day],
                from: Date()
            ),
            isCompleted: false,
            color: .clear
        )
        repository.remindersResult = [allReminder]
        repository.scheduledRemindersResult = [scheduledReminder]
        let store = ReminderFeatureStore(repository: repository)

        await store.reloadAll()

        XCTAssertEqual(store.reminders, [allReminder])
        XCTAssertEqual(store.scheduledReminders, [scheduledReminder])
    }
}

@MainActor
final class EventStoreManagerTests: XCTestCase {
    func testPrepareLoadsEachAuthorizedDataSource() async throws {
        let store = FakeEventStore()
        let suiteName = "EventStoreManagerTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let manager = EventStoreManager(
            calendarRepository: store,
            reminderRepository: store,
            userDefaults: defaults
        )

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
        let manager = EventStoreManager(
            calendarRepository: store,
            reminderRepository: store,
            userDefaults: defaults
        )

        try await manager.createNewReminder(title: "Test", date: nil, priority: .none)

        XCTAssertEqual(store.createReminderCount, 1)
        XCTAssertEqual(store.reminderLoadCount, 1)
        XCTAssertEqual(store.scheduledReminderLoadCount, 1)
    }

    func testReschedulingReminderPreservesTimeAndReloadsReminderData() async throws {
        let store = FakeEventStore()
        let suiteName = "EventStoreManagerTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let manager = EventStoreManager(
            calendarRepository: store,
            reminderRepository: store,
            userDefaults: defaults
        )
        let reminder = ReminderItem(
            id: "reminder",
            title: "Reminder",
            priority: .none,
            dueDateComponents: DateComponents(
                year: 2025,
                month: 1,
                day: 3,
                hour: 14,
                minute: 25
            ),
            isCompleted: false,
            color: .clear
        )
        let targetDate = try XCTUnwrap(CalendarMath.date(year: 2025, month: 2, day: 7))

        manager.reminders = [reminder]
        try await manager.rescheduleReminder(identifier: reminder.id, to: targetDate)

        XCTAssertEqual(store.updatedReminder?.dueDateComponents?.year, 2025)
        XCTAssertEqual(store.updatedReminder?.dueDateComponents?.month, 2)
        XCTAssertEqual(store.updatedReminder?.dueDateComponents?.day, 7)
        XCTAssertEqual(store.updatedReminder?.dueDateComponents?.hour, 14)
        XCTAssertEqual(store.updatedReminder?.dueDateComponents?.minute, 25)
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
        let manager = EventStoreManager(
            calendarRepository: store,
            reminderRepository: store,
            userDefaults: defaults
        )

        await manager.refreshCalendarEntries()

        XCTAssertEqual(store.eventLoadCount, 1)
        XCTAssertEqual(store.scheduledReminderLoadCount, 1)
        XCTAssertNotNil(manager.lastErrorMessage)
    }
}

private final class FakeEventStore: CalendarRepository, ReminderRepository {
    var calendarAuthorizationStatus: AuthorizationStatus = .fullAccess
    var reminderAuthorizationStatus: AuthorizationStatus = .fullAccess
    var calendarLoadCount = 0
    var eventLoadCount = 0
    var upcomingLoadCount = 0
    var reminderLoadCount = 0
    var scheduledReminderLoadCount = 0
    var createReminderCount = 0
    var updateReminderCount = 0
    var calendarAccessRequestCount = 0
    var reminderAccessRequestCount = 0
    var updatedReminder: ReminderItem?
    var shouldFailEventLoading = false
    var shouldFailCalendarAccessRequest = false
    var calendarsResult: [CalendarItem] = []
    var eventsResult: [EventItem] = []
    var upcomingEventsResult: [EventItem] = []
    var remindersResult: [ReminderItem] = []
    var scheduledRemindersResult: [ReminderItem] = []
    var lastRequestedCalendarIdentifiers: Set<String> = []

    func requestCalendarAccess() async throws -> Bool {
        calendarAccessRequestCount += 1
        if shouldFailCalendarAccessRequest {
            throw EventStoreError.denied
        }
        calendarAuthorizationStatus = .fullAccess
        return true
    }

    func requestReminderAccess() async throws -> Bool {
        reminderAccessRequestCount += 1
        reminderAuthorizationStatus = .fullAccess
        return true
    }

    func loadCalendars() async throws -> [CalendarItem] {
        calendarLoadCount += 1
        return calendarsResult
    }

    func loadUpcomingEvents() async throws -> [EventItem] {
        upcomingLoadCount += 1
        return upcomingEventsResult
    }

    func loadEvents(forDate date: Date, calendarIdentifiers: Set<String>) async throws -> [EventItem] {
        eventLoadCount += 1
        lastRequestedCalendarIdentifiers = calendarIdentifiers
        if shouldFailEventLoading {
            throw EventStoreError.unknown
        }
        return eventsResult
    }

    func loadAllReminders() async throws -> [ReminderItem] {
        reminderLoadCount += 1
        return remindersResult
    }

    func loadScheduledReminders(from startDate: Date, to endDate: Date) async throws -> [ReminderItem] {
        scheduledReminderLoadCount += 1
        return scheduledRemindersResult
    }

    func completeReminder(identifier: String) async throws {}
    func updateReminder(_ reminder: ReminderItem) async throws {
        updateReminderCount += 1
        updatedReminder = reminder
    }

    func createNewReminder(_ draft: ReminderDraft) async throws {
        createReminderCount += 1
    }

    func createNewCalendar() async throws {}
    func updateCalendar(_ calendar: CalendarItem) async throws {}
    func removeCalendar(identifier: String) async throws {}
    func saveEvent(_ draft: EventDraft) async throws {}
    func updateEvent(_ event: EventItem) async throws {}
    func removeEvent(identifier: String) async throws {}
}
