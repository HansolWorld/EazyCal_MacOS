//
//  EventStore.swift
//  EazyCal
//

import EventKit

final class EventStore: ObservableObject, CalendarRepository, ReminderRepository, EventStoreChangeObserving {
    let eventStore = EKEventStore()
    private var changeObserver: NSObjectProtocol?

    func loadCalendars() async throws -> [CalendarItem] {
        try requireFullAccess(for: .event)

        let calendars = eventStore.calendars(for: .event)
        let untitled = calendars.filter { $0.title == "무제" || $0.title == "Untitled" }
        let titled = calendars.filter { $0.title != "무제" && $0.title != "Untitled" }
        return (titled.sorted {
            $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        } + untitled).map(EventKitMapper.calendar)
    }

    func loadUpcomingEvents() async throws -> [EventItem] {
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
        return eventStore.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }
            .map(EventKitMapper.event)
    }

    func loadEvents(
        forDate date: Date,
        calendarIdentifiers: Set<String>
    ) async throws -> [EventItem] {
        try requireFullAccess(for: .event)
        let interval = try CalendarMath.visibleMonthInterval(containing: date)
        let calendars = eventStore.calendars(for: .event).filter {
            calendarIdentifiers.contains($0.calendarIdentifier)
        }
        let predicate = eventStore.predicateForEvents(
            withStart: interval.start,
            end: interval.end,
            calendars: calendars
        )
        return eventStore.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }
            .map(EventKitMapper.event)
    }

    func loadAllReminders() async throws -> [ReminderItem] {
        try requireFullAccess(for: .reminder)
        let predicate = eventStore.predicateForIncompleteReminders(
            withDueDateStarting: nil,
            ending: nil,
            calendars: nil
        )
        return try await eventStore.reminders(matching: predicate).map(EventKitMapper.reminder)
    }

    func loadScheduledReminders(from startDate: Date, to endDate: Date) async throws -> [ReminderItem] {
        try requireFullAccess(for: .reminder)
        let predicate = eventStore.predicateForIncompleteReminders(
            withDueDateStarting: startDate,
            ending: endDate,
            calendars: nil
        )
        return try await eventStore.reminders(matching: predicate)
            .sorted {
                let left = ReminderSchedule.date(from: $0.dueDateComponents) ?? .distantFuture
                let right = ReminderSchedule.date(from: $1.dueDateComponents) ?? .distantFuture
                return left < right
            }
            .map(EventKitMapper.reminder)
    }

    func completeReminder(identifier: String) async throws {
        try requireFullAccess(for: .reminder)
        let reminder = try reminder(withIdentifier: identifier)
        reminder.isCompleted = true
        try eventStore.save(reminder, commit: true)
    }

    func updateReminder(_ item: ReminderItem) async throws {
        try requireFullAccess(for: .reminder)
        let reminder = try reminder(withIdentifier: item.id)
        reminder.title = item.title
        reminder.priority = item.priority.rawValue
        reminder.dueDateComponents = item.dueDateComponents
        reminder.isCompleted = item.isCompleted
        try eventStore.save(reminder, commit: true)
    }

    func createNewReminder(_ draft: ReminderDraft) async throws {
        try requireFullAccess(for: .reminder)
        guard let calendar = eventStore.defaultCalendarForNewReminders() else {
            throw EventStoreError.missingDefaultCalendar
        }

        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = draft.title
        reminder.priority = draft.priority.rawValue
        if let date = draft.date {
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

    func updateCalendar(_ item: CalendarItem) async throws {
        try requireFullAccess(for: .event)
        guard let calendar = eventStore.calendar(withIdentifier: item.id) else {
            throw EventStoreError.itemNotFound
        }
        calendar.title = item.title
        calendar.cgColor = EventKitMapper.cgColor(item.color)
        try eventStore.saveCalendar(calendar, commit: true)
    }

    func removeCalendar(identifier: String) async throws {
        try requireFullAccess(for: .event)
        guard let calendar = eventStore.calendar(withIdentifier: identifier) else {
            throw EventStoreError.itemNotFound
        }
        try eventStore.removeCalendar(calendar, commit: true)
    }

    func saveEvent(_ draft: EventDraft) async throws {
        try requireFullAccess(for: .event)
        guard let calendar = eventStore.calendar(withIdentifier: draft.calendarIdentifier) else {
            throw EventStoreError.itemNotFound
        }

        let event = EKEvent(eventStore: eventStore)
        EventKitMapper.apply(draft, to: event, calendar: calendar)
        try eventStore.save(event, span: .thisEvent, commit: true)
    }

    func updateEvent(_ item: EventItem) async throws {
        try requireFullAccess(for: .event)
        let event = try event(withIdentifier: item.id)
        guard let calendar = eventStore.calendar(withIdentifier: item.calendar.id) else {
            throw EventStoreError.itemNotFound
        }
        EventKitMapper.apply(item, to: event, calendar: calendar)
        try eventStore.save(event, span: .thisEvent, commit: true)
    }

    func removeEvent(identifier: String) async throws {
        try requireFullAccess(for: .event)
        let event = try event(withIdentifier: identifier)
        try eventStore.remove(event, span: .thisEvent, commit: true)
    }

    func startObservingChanges(_ handler: @escaping @MainActor () -> Void) {
        guard changeObserver == nil else { return }
        changeObserver = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: eventStore,
            queue: .main
        ) { _ in
            Task { @MainActor in handler() }
        }
    }

    func stopObservingChanges() {
        guard let changeObserver else { return }
        NotificationCenter.default.removeObserver(changeObserver)
        self.changeObserver = nil
    }

    private func event(withIdentifier identifier: String) throws -> EKEvent {
        if let event = eventStore.event(withIdentifier: identifier) {
            return event
        }
        if let event = eventStore.calendarItem(withIdentifier: identifier) as? EKEvent {
            return event
        }
        throw EventStoreError.itemNotFound
    }

    private func reminder(withIdentifier identifier: String) throws -> EKReminder {
        guard let reminder = eventStore.calendarItem(withIdentifier: identifier) as? EKReminder else {
            throw EventStoreError.itemNotFound
        }
        return reminder
    }

    private func requireFullAccess(for entityType: EKEntityType) throws {
        let status = EKEventStore.authorizationStatus(for: entityType)
        guard status == .fullAccess else {
            throw status.eventStoreError ?? EventStoreError.denied
        }
    }
}

enum EventKitMapper {
    static func calendar(_ calendar: EKCalendar) -> CalendarItem {
        CalendarItem(
            id: calendar.calendarIdentifier,
            title: calendar.title,
            color: color(calendar.cgColor)
        )
    }

    static func event(_ event: EKEvent) -> EventItem {
        EventItem(
            id: event.eventIdentifier ?? event.calendarItemIdentifier,
            calendar: calendar(event.calendar),
            title: event.title ?? "",
            isAllDay: event.isAllDay,
            startDate: event.startDate ?? Date(),
            endDate: event.endDate ?? event.startDate ?? Date(),
            repeatType: repeatType(event.recurrenceRules?.first?.frequency),
            url: event.url,
            notes: event.notes ?? ""
        )
    }

    static func reminder(_ reminder: EKReminder) -> ReminderItem {
        ReminderItem(
            id: reminder.calendarItemIdentifier,
            title: reminder.title ?? "",
            priority: ReminderPriority(eventKitValue: reminder.priority),
            dueDateComponents: reminder.dueDateComponents,
            isCompleted: reminder.isCompleted,
            color: color(reminder.calendar?.cgColor)
        )
    }

    static func apply(_ draft: EventDraft, to event: EKEvent, calendar: EKCalendar) {
        event.title = draft.title
        event.isAllDay = draft.isAllDay
        event.startDate = draft.startDate
        event.endDate = max(draft.startDate, draft.endDate)
        event.notes = draft.notes
        event.calendar = calendar
        event.url = draft.url
        event.recurrenceRules = RecurrenceRuleFactory.rules(for: draft.repeatType)
    }

    static func apply(_ item: EventItem, to event: EKEvent, calendar: EKCalendar) {
        apply(
            EventDraft(
                title: item.title,
                isAllDay: item.isAllDay,
                startDate: item.startDate,
                endDate: item.endDate,
                repeatType: item.repeatType,
                url: item.url,
                notes: item.notes,
                calendarIdentifier: item.calendar.id
            ),
            to: event,
            calendar: calendar
        )
    }

    private static func repeatType(_ frequency: EKRecurrenceFrequency?) -> RepeatType {
        switch frequency {
        case .daily: .everyDay
        case .weekly: .everyWeek
        case .monthly: .everyMonth
        case .yearly: .everyYear
        default: .oneDay
        }
    }

    static func color(_ cgColor: CGColor?) -> CalendarColor {
        guard let components = cgColor?.components else {
            return .clear
        }
        if components.count >= 4 {
            return CalendarColor(
                red: components[0],
                green: components[1],
                blue: components[2],
                alpha: components[3]
            )
        }
        let white = components.first ?? 0
        return CalendarColor(red: white, green: white, blue: white, alpha: components.last ?? 1)
    }

    static func cgColor(_ color: CalendarColor) -> CGColor {
        CGColor(red: color.red, green: color.green, blue: color.blue, alpha: color.alpha)
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
