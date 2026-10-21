//
//  EventStore.swift
//  EazyCal
//

import EventKit

protocol EventStoreProviding: AnyObject {
    var calendarAuthorizationStatus: EKAuthorizationStatus { get }
    var reminderAuthorizationStatus: EKAuthorizationStatus { get }

    func requestCalendarAccess() async throws -> Bool
    func requestReminderAccess() async throws -> Bool
    func loadCalendars() async throws -> [EKCalendar]
    func loadUpcomingEvents() async throws -> [EKEvent]
    func loadEvents(forDate date: Date, calendars: [EKCalendar]) async throws -> [EKEvent]
    func loadAllReminders() async throws -> [EKReminder]
    func loadScheduledReminders(from startDate: Date, to endDate: Date) async throws -> [EKReminder]
    func completeReminder(reminder: EKReminder) async throws
    func updateReminder(reminder: EKReminder) async throws
    func createNewReminder(title: String, date: Date?, highlight: String) async throws
    func createNewCalendar() async throws
    func updateCalendar(calendar: EKCalendar) async throws
    func removeCalendar(calendar: EKCalendar) async throws
    func saveEvent(title: String, isAllDay: Bool, startDate: Date, endDate: Date, repeatDate: RepeatType, url: URL?, notes: [String], calendar: EKCalendar) async throws
    func updateEvent(event: EKEvent) async throws
    func removeEvent(event: EKEvent) async throws
}

final class EventStore: ObservableObject, EventStoreProviding {
    let eventStore = EKEventStore()

    func loadCalendars() async throws -> [EKCalendar] {
        try requireFullAccess(for: .event)

        let calendars = eventStore.calendars(for: .event)
        let untitled = calendars.filter { $0.title == "무제" || $0.title == "Untitled" }
        let titled = calendars.filter { $0.title != "무제" && $0.title != "Untitled" }
        return titled.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending } + untitled
    }

    func loadUpcomingEvents() async throws -> [EKEvent] {
        try requireFullAccess(for: .event)

        let startOfDay = Calendar.current.startOfDay(for: Date())
        guard let endDate = Calendar.current.date(byAdding: .day, value: 30, to: startOfDay) else {
            throw EventStoreError.invalidDate
        }
        let predicate = eventStore.predicateForEvents(
            withStart: startOfDay,
            end: endDate,
            calendars: eventStore.calendars(for: .event)
        )
        return eventStore.events(matching: predicate).sorted { $0.startDate < $1.startDate }
    }

    func loadEvents(forDate date: Date, calendars: [EKCalendar]) async throws -> [EKEvent] {
        try requireFullAccess(for: .event)
        let interval = try CalendarMath.visibleMonthInterval(containing: date)
        let predicate = eventStore.predicateForEvents(
            withStart: interval.start,
            end: interval.end,
            calendars: calendars
        )
        return eventStore.events(matching: predicate).sorted { $0.startDate < $1.startDate }
    }

    func loadAllReminders() async throws -> [EKReminder] {
        try requireFullAccess(for: .reminder)
        let predicate = eventStore.predicateForIncompleteReminders(
            withDueDateStarting: nil,
            ending: nil,
            calendars: nil
        )
        return try await eventStore.reminders(matching: predicate)
    }

    func loadScheduledReminders(from startDate: Date, to endDate: Date) async throws -> [EKReminder] {
        try requireFullAccess(for: .reminder)
        let predicate = eventStore.predicateForIncompleteReminders(
            withDueDateStarting: startDate,
            ending: endDate,
            calendars: nil
        )
        return try await eventStore.reminders(matching: predicate).sorted {
            let left = ReminderSchedule.date(from: $0.dueDateComponents) ?? .distantFuture
            let right = ReminderSchedule.date(from: $1.dueDateComponents) ?? .distantFuture
            return left < right
        }
    }

    func completeReminder(reminder: EKReminder) async throws {
        try requireFullAccess(for: .reminder)
        reminder.isCompleted = true
        try eventStore.save(reminder, commit: true)
    }

    func updateReminder(reminder: EKReminder) async throws {
        try requireFullAccess(for: .reminder)
        try eventStore.save(reminder, commit: true)
    }

    func createNewReminder(title: String, date: Date?, highlight: String) async throws {
        try requireFullAccess(for: .reminder)
        guard let calendar = eventStore.defaultCalendarForNewReminders() else {
            throw EventStoreError.missingDefaultCalendar
        }

        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.priority = ReminderPriority.priority(for: highlight)
        if let date {
            reminder.dueDateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: date
            )
        }
        reminder.calendar = calendar
        try eventStore.save(reminder, commit: true)
    }

    func createNewCalendar() async throws {
        try requireFullAccess(for: .event)
        guard let source = eventStore.defaultCalendarForNewEvents?.source else {
            throw EventStoreError.missingDefaultCalendar
        }

        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        calendar.title = String(localized: "DEFAULT_CALENDAR_TITLE")
        calendar.cgColor = CGColor(
            red: Double.random(in: 0...1),
            green: Double.random(in: 0...1),
            blue: Double.random(in: 0...1),
            alpha: 1
        )
        calendar.source = source
        try eventStore.saveCalendar(calendar, commit: true)
    }

    func updateCalendar(calendar: EKCalendar) async throws {
        try requireFullAccess(for: .event)
        try eventStore.saveCalendar(calendar, commit: true)
    }

    func removeCalendar(calendar: EKCalendar) async throws {
        try requireFullAccess(for: .event)
        try eventStore.removeCalendar(calendar, commit: true)
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
        try requireFullAccess(for: .event)

        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.isAllDay = isAllDay
        event.startDate = startDate
        event.endDate = max(startDate, endDate)
        event.notes = notes.map { "☐" + $0 }.joined(separator: "\n")
        event.calendar = calendar
        event.url = url
        event.recurrenceRules = RecurrenceRuleFactory.rules(for: repeatDate)
        try eventStore.save(event, span: .thisEvent, commit: true)
    }

    func updateEvent(event: EKEvent) async throws {
        try requireFullAccess(for: .event)
        try eventStore.save(event, span: .thisEvent, commit: true)
    }

    func removeEvent(event: EKEvent) async throws {
        try requireFullAccess(for: .event)
        try eventStore.remove(event, span: .thisEvent, commit: true)
    }

    private func requireFullAccess(for entityType: EKEntityType) throws {
        let status = EKEventStore.authorizationStatus(for: entityType)
        guard status == .fullAccess else {
            throw status.eventStoreError ?? EventStoreError.denied
        }
    }
}

enum RecurrenceRuleFactory {
    static func rules(for repeatType: RepeatType) -> [EKRecurrenceRule]? {
        let frequency: EKRecurrenceFrequency
        switch repeatType {
        case .oneDay:
            return nil
        case .everyDay:
            frequency = .daily
        case .everyWeek:
            frequency = .weekly
        case .everyMonth:
            frequency = .monthly
        case .everyYear:
            frequency = .yearly
        }
        return [EKRecurrenceRule(recurrenceWith: frequency, interval: 1, end: nil)]
    }
}

enum ReminderPriority {
    static func priority(for localizedValue: String) -> Int {
        switch localizedValue {
        case String(localized: "LOW"):
            return 9
        case String(localized: "MID"):
            return 5
        case String(localized: "HIGH"):
            return 1
        default:
            return 0
        }
    }
}

extension EKEventStore {
    func reminders(matching predicate: NSPredicate) async throws -> [EKReminder] {
        try await withCheckedThrowingContinuation { continuation in
            fetchReminders(matching: predicate) { reminders in
                if let reminders {
                    continuation.resume(returning: reminders)
                } else {
                    continuation.resume(throwing: EventStoreError.unknown)
                }
            }
        }
    }
}
