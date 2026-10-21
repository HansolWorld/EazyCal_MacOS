import EventKit
import XCTest
@testable import EazyCal

@MainActor
final class ApplicationWorkflowTests: XCTestCase {
    func testReminderUseCaseCompletesAndReloadsSnapshot() async throws {
        let repository = WorkflowRepositorySpy()
        let reminder = EKReminder(eventStore: EKEventStore())
        repository.reminders = [reminder]
        repository.scheduledReminders = [reminder]
        let useCase = ReminderUseCase(repository: repository)
        let visibleDate = try XCTUnwrap(CalendarMath.date(year: 2025, month: 2, day: 7))

        let snapshot = try await useCase.complete(reminder, visibleDate: visibleDate)

        XCTAssertEqual(repository.completeReminderCount, 1)
        XCTAssertEqual(repository.reminderLoadCount, 1)
        XCTAssertEqual(repository.scheduledReminderLoadCount, 1)
        XCTAssertEqual(snapshot.reminders.count, 1)
        XCTAssertEqual(snapshot.scheduledReminders.count, 1)
    }

    func testCalendarEventUseCaseUpdatesAndReloadsBothEventLists() async throws {
        let repository = WorkflowRepositorySpy()
        let event = EKEvent(eventStore: EKEventStore())
        repository.events = [event]
        repository.upcomingEvents = [event]
        let useCase = CalendarEventUseCase(repository: repository)
        let visibleDate = try XCTUnwrap(CalendarMath.date(year: 2025, month: 2, day: 7))

        let snapshot = try await useCase.update(
            event,
            visibleDate: visibleDate,
            visibleCalendars: []
        )

        XCTAssertEqual(repository.updateEventCount, 1)
        XCTAssertEqual(repository.eventLoadCount, 1)
        XCTAssertEqual(repository.upcomingLoadCount, 1)
        XCTAssertEqual(snapshot.events.count, 1)
        XCTAssertEqual(snapshot.upcomingEvents.count, 1)
    }

    func testDropCoordinatorMovesEventAndPreservesDuration() async throws {
        let handler = DropEventHandlerSpy()
        let event = EKEvent(eventStore: EKEventStore())
        event.startDate = try XCTUnwrap(CalendarMath.date(year: 2025, month: 1, day: 3, hour: 9, minute: 0))
        event.endDate = try XCTUnwrap(CalendarMath.date(year: 2025, month: 1, day: 3, hour: 10, minute: 30))
        let targetDate = try XCTUnwrap(CalendarMath.date(year: 2025, month: 2, day: 7))

        await CalendarDropCoordinator(eventHandler: handler).perform(.event(event), on: targetDate)

        XCTAssertEqual(handler.updateEventCount, 1)
        XCTAssertEqual(
            event.endDate.timeIntervalSince(event.startDate),
            90 * 60,
            accuracy: 0.1
        )
        XCTAssertEqual(Calendar.current.component(.day, from: event.startDate), 7)
    }

    func testDropCoordinatorMovesOvernightTemplateEndToNextDay() async throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let eventStore = EKEventStore()
        let eventCalendar = EKCalendar(for: .event, eventStore: eventStore)
        let handler = DropEventHandlerSpy(calendars: [eventCalendar])
        let template = Template(
            title: "Night shift",
            startTime: try XCTUnwrap(CalendarMath.date(year: 2025, month: 1, day: 1, hour: 23, minute: 0, calendar: calendar)),
            endTime: try XCTUnwrap(CalendarMath.date(year: 2025, month: 1, day: 1, hour: 1, minute: 0, calendar: calendar)),
            todos: [],
            calendarId: eventCalendar.calendarIdentifier
        )
        let targetDate = try XCTUnwrap(CalendarMath.date(year: 2025, month: 2, day: 7, calendar: calendar))

        await CalendarDropCoordinator(eventHandler: handler, calendar: calendar)
            .perform(.template(template), on: targetDate)

        let startDate = try XCTUnwrap(handler.savedStartDate)
        let endDate = try XCTUnwrap(handler.savedEndDate)
        XCTAssertEqual(endDate.timeIntervalSince(startDate), 2 * 60 * 60, accuracy: 0.1)
        XCTAssertEqual(calendar.component(.day, from: startDate), 7)
        XCTAssertEqual(calendar.component(.day, from: endDate), 8)
    }
}

private final class WorkflowRepositorySpy: CalendarRepository, ReminderRepository {
    var calendarAuthorizationStatus: EKAuthorizationStatus = .fullAccess
    var reminderAuthorizationStatus: EKAuthorizationStatus = .fullAccess
    var events: [EKEvent] = []
    var upcomingEvents: [EKEvent] = []
    var reminders: [EKReminder] = []
    var scheduledReminders: [EKReminder] = []
    var eventLoadCount = 0
    var upcomingLoadCount = 0
    var reminderLoadCount = 0
    var scheduledReminderLoadCount = 0
    var completeReminderCount = 0
    var updateEventCount = 0

    func requestCalendarAccess() async throws -> Bool { true }
    func requestReminderAccess() async throws -> Bool { true }
    func loadCalendars() async throws -> [EKCalendar] { [] }

    func loadUpcomingEvents() async throws -> [EKEvent] {
        upcomingLoadCount += 1
        return upcomingEvents
    }

    func loadEvents(forDate date: Date, calendars: [EKCalendar]) async throws -> [EKEvent] {
        eventLoadCount += 1
        return events
    }

    func loadAllReminders() async throws -> [EKReminder] {
        reminderLoadCount += 1
        return reminders
    }

    func loadScheduledReminders(from startDate: Date, to endDate: Date) async throws -> [EKReminder] {
        scheduledReminderLoadCount += 1
        return scheduledReminders
    }

    func completeReminder(reminder: EKReminder) async throws {
        completeReminderCount += 1
    }

    func updateReminder(reminder: EKReminder) async throws {}
    func createNewReminder(title: String, date: Date?, highlight: String) async throws {}
    func createNewCalendar() async throws {}
    func updateCalendar(calendar: EKCalendar) async throws {}
    func removeCalendar(calendar: EKCalendar) async throws {}
    func saveEvent(title: String, isAllDay: Bool, startDate: Date, endDate: Date, repeatDate: RepeatType, url: URL?, notes: [String], calendar: EKCalendar) async throws {}

    func updateEvent(event: EKEvent) async throws {
        updateEventCount += 1
    }

    func removeEvent(event: EKEvent) async throws {}
}

@MainActor
private final class DropEventHandlerSpy: CalendarDropEventHandling {
    let calendars: [EKCalendar]
    var updateEventCount = 0
    var savedStartDate: Date?
    var savedEndDate: Date?

    init(calendars: [EKCalendar] = []) {
        self.calendars = calendars
    }

    func saveEvent(
        title: String,
        isAllDay: Bool,
        startDate: Date,
        endDate: Date,
        repeatDate: RepeatType,
        url: URL?,
        notes: [String],
        calendar: EKCalendar
    ) async throws {
        savedStartDate = startDate
        savedEndDate = endDate
    }

    func updateEvent(event: EKEvent) async throws {
        updateEventCount += 1
    }

    func rescheduleReminder(_ reminder: EKReminder, to targetDate: Date) async throws {}
}
