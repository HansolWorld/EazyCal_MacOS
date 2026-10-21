//
//  EventKitUseCases.swift
//  EazyCal
//

import Foundation

struct CalendarEventSnapshot {
    let events: [EventItem]
    let upcomingEvents: [EventItem]
}

struct CalendarEventUseCase {
    private let repository: any CalendarRepository

    init(repository: any CalendarRepository) {
        self.repository = repository
    }

    func loadSnapshot(for date: Date, calendarIdentifiers: Set<String>) async throws -> CalendarEventSnapshot {
        let events = try await repository.loadEvents(
            forDate: date,
            calendarIdentifiers: calendarIdentifiers
        )
        let upcomingEvents = try await repository.loadUpcomingEvents()
        return CalendarEventSnapshot(events: events, upcomingEvents: upcomingEvents)
    }

    func saveEvent(
        draft: EventDraft,
        visibleDate: Date,
        visibleCalendarIdentifiers: Set<String>
    ) async throws -> CalendarEventSnapshot {
        try await repository.saveEvent(draft)
        return try await loadSnapshot(
            for: visibleDate,
            calendarIdentifiers: visibleCalendarIdentifiers
        )
    }

    func update(
        _ event: EventItem,
        visibleDate: Date,
        visibleCalendarIdentifiers: Set<String>
    ) async throws -> CalendarEventSnapshot {
        try await repository.updateEvent(event)
        return try await loadSnapshot(
            for: visibleDate,
            calendarIdentifiers: visibleCalendarIdentifiers
        )
    }

    func remove(
        identifier: String,
        visibleDate: Date,
        visibleCalendarIdentifiers: Set<String>
    ) async throws -> CalendarEventSnapshot {
        try await repository.removeEvent(identifier: identifier)
        return try await loadSnapshot(
            for: visibleDate,
            calendarIdentifiers: visibleCalendarIdentifiers
        )
    }
}

struct ReminderSnapshot {
    let reminders: [ReminderItem]
    let scheduledReminders: [ReminderItem]
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
        draft: ReminderDraft,
        visibleDate: Date
    ) async throws -> ReminderSnapshot {
        try await repository.createNewReminder(draft)
        return try await loadSnapshot(for: visibleDate)
    }

    func complete(identifier: String, visibleDate: Date) async throws -> ReminderSnapshot {
        try await repository.completeReminder(identifier: identifier)
        return try await loadSnapshot(for: visibleDate)
    }

    func update(_ reminder: ReminderItem, visibleDate: Date) async throws -> ReminderSnapshot {
        try await repository.updateReminder(reminder)
        return try await loadSnapshot(for: visibleDate)
    }

    func reschedule(
        _ reminder: ReminderItem,
        to targetDate: Date,
        visibleDate: Date
    ) async throws -> ReminderSnapshot {
        var reminder = reminder
        reminder.dueDateComponents = ReminderSchedule.moving(
            reminder.dueDateComponents,
            toDay: targetDate
        )
        return try await update(reminder, visibleDate: visibleDate)
    }
}
