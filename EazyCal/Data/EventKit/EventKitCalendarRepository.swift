import EventKit

final class EventKitCalendarRepository: CalendarRepository {
    private let eventStore: EKEventStore

    var calendarAuthorizationStatus: AuthorizationStatus {
        EventKitAuthorization.status(for: .event)
    }

    init(eventStore: EKEventStore) {
        self.eventStore = eventStore
    }

    func requestCalendarAccess() async throws -> Bool {
        try await eventStore.requestFullAccessToEvents()
    }

    func loadCalendars() async throws -> [CalendarItem] {
        try EventKitAuthorization.requireFullAccess(for: .event)

        let calendars = eventStore.calendars(for: .event)
        let untitled = calendars.filter { $0.title == "무제" || $0.title == "Untitled" }
        let titled = calendars.filter { $0.title != "무제" && $0.title != "Untitled" }
        return (titled.sorted {
            $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        } + untitled).map(EventKitMapper.calendar)
    }

    func loadUpcomingEvents() async throws -> [EventItem] {
        try EventKitAuthorization.requireFullAccess(for: .event)

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
        try EventKitAuthorization.requireFullAccess(for: .event)
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

    func createNewCalendar() async throws {
        try EventKitAuthorization.requireFullAccess(for: .event)
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
        try EventKitAuthorization.requireFullAccess(for: .event)
        guard let calendar = eventStore.calendar(withIdentifier: item.id) else {
            throw EventStoreError.itemNotFound
        }
        calendar.title = item.title
        calendar.cgColor = EventKitMapper.cgColor(item.color)
        try eventStore.saveCalendar(calendar, commit: true)
    }

    func removeCalendar(identifier: String) async throws {
        try EventKitAuthorization.requireFullAccess(for: .event)
        guard let calendar = eventStore.calendar(withIdentifier: identifier) else {
            throw EventStoreError.itemNotFound
        }
        try eventStore.removeCalendar(calendar, commit: true)
    }

    func saveEvent(_ draft: EventDraft) async throws {
        try EventKitAuthorization.requireFullAccess(for: .event)
        guard let calendar = eventStore.calendar(withIdentifier: draft.calendarIdentifier) else {
            throw EventStoreError.itemNotFound
        }

        let event = EKEvent(eventStore: eventStore)
        EventKitMapper.apply(draft, to: event, calendar: calendar)
        try eventStore.save(event, span: .thisEvent, commit: true)
    }

    func updateEvent(_ item: EventItem) async throws {
        try EventKitAuthorization.requireFullAccess(for: .event)
        let event = try event(withIdentifier: item.id)
        guard let calendar = eventStore.calendar(withIdentifier: item.calendar.id) else {
            throw EventStoreError.itemNotFound
        }
        EventKitMapper.apply(item, to: event, calendar: calendar)
        try eventStore.save(event, span: .thisEvent, commit: true)
    }

    func removeEvent(identifier: String) async throws {
        try EventKitAuthorization.requireFullAccess(for: .event)
        let event = try event(withIdentifier: identifier)
        try eventStore.remove(event, span: .thisEvent, commit: true)
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
}
