import XCTest
@testable import EazyCal

@MainActor
final class ApplicationWorkflowTests: XCTestCase {
    func testReminderUseCaseCompletesAndReloadsSnapshot() async throws {
        let repository = WorkflowRepositorySpy()
        let reminder = makeReminder()
        repository.reminders = [reminder]
        repository.scheduledReminders = [reminder]
        let useCase = ReminderUseCase(repository: repository)
        let visibleDate = try XCTUnwrap(CalendarMath.date(year: 2025, month: 2, day: 7))

        let snapshot = try await useCase.complete(identifier: reminder.id, visibleDate: visibleDate)

        XCTAssertEqual(repository.completeReminderCount, 1)
        XCTAssertEqual(repository.reminderLoadCount, 1)
        XCTAssertEqual(repository.scheduledReminderLoadCount, 1)
        XCTAssertEqual(snapshot.reminders.count, 1)
        XCTAssertEqual(snapshot.scheduledReminders.count, 1)
    }

    func testCalendarEventUseCaseUpdatesAndReloadsBothEventLists() async throws {
        let repository = WorkflowRepositorySpy()
        let event = makeEvent()
        repository.events = [event]
        repository.upcomingEvents = [event]
        let useCase = CalendarEventUseCase(repository: repository)
        let visibleDate = try XCTUnwrap(CalendarMath.date(year: 2025, month: 2, day: 7))

        let snapshot = try await useCase.update(
            event,
            visibleDate: visibleDate,
            visibleCalendarIdentifiers: []
        )

        XCTAssertEqual(repository.updateEventCount, 1)
        XCTAssertEqual(repository.eventLoadCount, 1)
        XCTAssertEqual(repository.upcomingLoadCount, 1)
        XCTAssertEqual(snapshot.events.count, 1)
        XCTAssertEqual(snapshot.upcomingEvents.count, 1)
    }

    func testDropCoordinatorRequestsEventMoveByIdentifier() async throws {
        let handler = DropEventHandlerSpy()
        let targetDate = try XCTUnwrap(CalendarMath.date(year: 2025, month: 2, day: 7))

        await CalendarDropCoordinator(eventHandler: handler)
            .perform(.event(identifier: "event"), on: targetDate)

        XCTAssertEqual(handler.movedEventIdentifier, "event")
        XCTAssertEqual(handler.movedTargetDate, targetDate)
    }

    func testEventScheduleMovesEventAndPreservesDuration() throws {
        var event = makeEvent()
        event.startDate = try XCTUnwrap(CalendarMath.date(year: 2025, month: 1, day: 3, hour: 9, minute: 0))
        event.endDate = try XCTUnwrap(CalendarMath.date(year: 2025, month: 1, day: 3, hour: 10, minute: 30))
        let targetDate = try XCTUnwrap(CalendarMath.date(year: 2025, month: 2, day: 7))

        let movedEvent = try XCTUnwrap(EventSchedule.moving(event, toDay: targetDate))

        XCTAssertEqual(
            movedEvent.endDate.timeIntervalSince(movedEvent.startDate),
            90 * 60,
            accuracy: 0.1
        )
        XCTAssertEqual(Calendar.current.component(.day, from: movedEvent.startDate), 7)
    }

    func testDropCoordinatorMovesOvernightTemplateEndToNextDay() async throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let eventCalendar = CalendarItem(id: "calendar", title: "Calendar", color: .clear)
        let handler = DropEventHandlerSpy(calendars: [eventCalendar])
        let template = Template(
            title: "Night shift",
            startTime: try XCTUnwrap(CalendarMath.date(year: 2025, month: 1, day: 1, hour: 23, minute: 0, calendar: calendar)),
            endTime: try XCTUnwrap(CalendarMath.date(year: 2025, month: 1, day: 1, hour: 1, minute: 0, calendar: calendar)),
            todos: [],
            calendarId: eventCalendar.id
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

    private func makeEvent() -> EventItem {
        EventItem(
            id: "event",
            calendar: CalendarItem(id: "calendar", title: "Calendar", color: .clear),
            title: "Event",
            isAllDay: false,
            startDate: Date(),
            endDate: Date().addingTimeInterval(60),
            repeatType: .oneDay,
            url: nil,
            notes: ""
        )
    }

    private func makeReminder() -> ReminderItem {
        ReminderItem(
            id: "reminder",
            title: "Reminder",
            priority: 0,
            dueDateComponents: nil,
            isCompleted: false,
            color: .clear
        )
    }
}

private final class WorkflowRepositorySpy: CalendarRepository, ReminderRepository {
    var calendarAuthorizationStatus: AuthorizationStatus = .fullAccess
    var reminderAuthorizationStatus: AuthorizationStatus = .fullAccess
    var events: [EventItem] = []
    var upcomingEvents: [EventItem] = []
    var reminders: [ReminderItem] = []
    var scheduledReminders: [ReminderItem] = []
    var eventLoadCount = 0
    var upcomingLoadCount = 0
    var reminderLoadCount = 0
    var scheduledReminderLoadCount = 0
    var completeReminderCount = 0
    var updateEventCount = 0

    func requestCalendarAccess() async throws -> Bool { true }
    func requestReminderAccess() async throws -> Bool { true }
    func loadCalendars() async throws -> [CalendarItem] { [] }

    func loadUpcomingEvents() async throws -> [EventItem] {
        upcomingLoadCount += 1
        return upcomingEvents
    }

    func loadEvents(forDate date: Date, calendarIdentifiers: Set<String>) async throws -> [EventItem] {
        eventLoadCount += 1
        return events
    }

    func loadAllReminders() async throws -> [ReminderItem] {
        reminderLoadCount += 1
        return reminders
    }

    func loadScheduledReminders(from startDate: Date, to endDate: Date) async throws -> [ReminderItem] {
        scheduledReminderLoadCount += 1
        return scheduledReminders
    }

    func completeReminder(identifier: String) async throws {
        completeReminderCount += 1
    }

    func updateReminder(_ reminder: ReminderItem) async throws {}
    func createNewReminder(_ draft: ReminderDraft) async throws {}
    func createNewCalendar() async throws {}
    func updateCalendar(_ calendar: CalendarItem) async throws {}
    func removeCalendar(identifier: String) async throws {}
    func saveEvent(_ draft: EventDraft) async throws {}

    func updateEvent(_ event: EventItem) async throws {
        updateEventCount += 1
    }

    func removeEvent(identifier: String) async throws {}
}

@MainActor
private final class DropEventHandlerSpy: CalendarDropEventHandling {
    let calendars: [CalendarItem]
    var movedEventIdentifier: String?
    var movedTargetDate: Date?
    var savedStartDate: Date?
    var savedEndDate: Date?

    init(calendars: [CalendarItem] = []) {
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
        calendarIdentifier: String
    ) async throws {
        savedStartDate = startDate
        savedEndDate = endDate
    }

    func moveEvent(identifier: String, to targetDate: Date) async throws {
        movedEventIdentifier = identifier
        movedTargetDate = targetDate
    }

    func rescheduleReminder(identifier: String, to targetDate: Date) async throws {}
}
