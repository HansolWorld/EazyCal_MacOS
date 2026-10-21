//
//  EventKitUseCases.swift
//  EazyCal
//

import EventKit

struct CalendarEventSnapshot {
    let events: [EKEvent]
    let upcomingEvents: [EKEvent]
}

struct CalendarEventUseCase {
    private let repository: any CalendarRepository

    init(repository: any CalendarRepository) {
        self.repository = repository
    }

    func loadSnapshot(for date: Date, calendars: [EKCalendar]) async throws -> CalendarEventSnapshot {
        let events = try await repository.loadEvents(forDate: date, calendars: calendars)
        let upcomingEvents = try await repository.loadUpcomingEvents()
        return CalendarEventSnapshot(events: events, upcomingEvents: upcomingEvents)
    }

    func saveEvent(
        title: String,
        isAllDay: Bool,
        startDate: Date,
        endDate: Date,
        repeatDate: RepeatType,
        url: URL?,
        notes: [String],
        calendar: EKCalendar,
        visibleDate: Date,
        visibleCalendars: [EKCalendar]
    ) async throws -> CalendarEventSnapshot {
        try await repository.saveEvent(
            title: title,
            isAllDay: isAllDay,
            startDate: startDate,
            endDate: endDate,
            repeatDate: repeatDate,
            url: url,
            notes: notes,
            calendar: calendar
        )
        return try await loadSnapshot(for: visibleDate, calendars: visibleCalendars)
    }

    func update(
        _ event: EKEvent,
        visibleDate: Date,
        visibleCalendars: [EKCalendar]
    ) async throws -> CalendarEventSnapshot {
        try await repository.updateEvent(event: event)
        return try await loadSnapshot(for: visibleDate, calendars: visibleCalendars)
    }

    func remove(
        _ event: EKEvent,
        visibleDate: Date,
        visibleCalendars: [EKCalendar]
    ) async throws -> CalendarEventSnapshot {
        try await repository.removeEvent(event: event)
        return try await loadSnapshot(for: visibleDate, calendars: visibleCalendars)
    }
}

struct ReminderSnapshot {
    let reminders: [EKReminder]
    let scheduledReminders: [EKReminder]
}

struct ReminderUseCase {
    private let repository: any ReminderRepository

    init(repository: any ReminderRepository) {
        self.repository = repository
    }

    func loadSnapshot(for date: Date) async throws -> ReminderSnapshot {
        let interval = try CalendarMath.visibleMonthInterval(containing: date)
        let reminders = try await repository.loadAllReminders()
        let scheduledReminders = try await repository.loadScheduledReminders(
            from: interval.start,
            to: interval.end
        )
        return ReminderSnapshot(
            reminders: reminders,
            scheduledReminders: scheduledReminders
        )
    }

    func create(
        title: String,
        date: Date?,
        highlight: String,
        visibleDate: Date
    ) async throws -> ReminderSnapshot {
        try await repository.createNewReminder(title: title, date: date, highlight: highlight)
        return try await loadSnapshot(for: visibleDate)
    }

    func complete(_ reminder: EKReminder, visibleDate: Date) async throws -> ReminderSnapshot {
        try await repository.completeReminder(reminder: reminder)
        return try await loadSnapshot(for: visibleDate)
    }

    func update(_ reminder: EKReminder, visibleDate: Date) async throws -> ReminderSnapshot {
        try await repository.updateReminder(reminder: reminder)
        return try await loadSnapshot(for: visibleDate)
    }

    func reschedule(
        _ reminder: EKReminder,
        to targetDate: Date,
        visibleDate: Date
    ) async throws -> ReminderSnapshot {
        reminder.dueDateComponents = ReminderSchedule.moving(
            reminder.dueDateComponents,
            toDay: targetDate
        )
        return try await update(reminder, visibleDate: visibleDate)
    }
}
