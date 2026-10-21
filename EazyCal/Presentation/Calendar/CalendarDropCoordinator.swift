//
//  CalendarDropCoordinator.swift
//  EazyCal
//

import Foundation

enum CalendarDropItem {
    case template(Template)
    case event(EventItem)
    case reminder(ReminderItem)
}

@MainActor
protocol CalendarDropEventHandling: AnyObject {
    var calendars: [CalendarItem] { get }

    func saveEvent(
        title: String,
        isAllDay: Bool,
        startDate: Date,
        endDate: Date,
        repeatDate: RepeatType,
        url: URL?,
        notes: [String],
        calendar: CalendarItem
    ) async throws
    func updateEvent(event: EventItem) async throws
    func rescheduleReminder(_ reminder: ReminderItem, to targetDate: Date) async throws
}

extension EventStoreManager: CalendarDropEventHandling {}

@MainActor
struct CalendarDropCoordinator {
    private let eventHandler: any CalendarDropEventHandling
    private let calendar: Calendar

    init(
        eventHandler: any CalendarDropEventHandling,
        calendar: Calendar = .current
    ) {
        self.eventHandler = eventHandler
        self.calendar = calendar
    }

    func perform(_ item: CalendarDropItem, on targetDate: Date) async {
        do {
            switch item {
            case .template(let template):
                try await createEvent(from: template, on: targetDate)
            case .event(let event):
                try await move(event, to: targetDate)
            case .reminder(let reminder):
                try await eventHandler.rescheduleReminder(reminder, to: targetDate)
            }
        } catch {
            // EventStoreManager records repository errors for user-facing presentation.
        }
    }

    private func createEvent(from template: Template, on targetDate: Date) async throws {
        guard let eventCalendar = eventHandler.calendars.first(where: {
            $0.id == template.calendarId
        }),
        let startDate = CalendarMath.moving(template.startTime, toDay: targetDate, calendar: calendar),
        var endDate = CalendarMath.moving(template.endTime, toDay: targetDate, calendar: calendar) else {
            return
        }

        if endDate < startDate {
            endDate = calendar.date(byAdding: .day, value: 1, to: endDate) ?? startDate
        }

        try await eventHandler.saveEvent(
            title: template.title,
            isAllDay: template.isAllDay,
            startDate: startDate,
            endDate: endDate,
            repeatDate: .oneDay,
            url: nil,
            notes: template.todos,
            calendar: eventCalendar
        )
    }

    private func move(_ event: EventItem, to targetDate: Date) async throws {
        guard let movedStartDate = CalendarMath.moving(
            event.startDate,
            toDay: targetDate,
            calendar: calendar
        ) else {
            return
        }

        var event = event
        let duration = event.endDate.timeIntervalSince(event.startDate)
        event.startDate = movedStartDate
        event.endDate = movedStartDate.addingTimeInterval(duration)
        try await eventHandler.updateEvent(event: event)
    }
}
