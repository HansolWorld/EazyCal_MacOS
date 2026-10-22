import Combine
import Foundation

@MainActor
final class CalendarFeatureStore: ObservableObject {
    @Published var date = Date()
    @Published var calendars: [CalendarItem] = []
    @Published var events: [EventItem] = []
    @Published var upcomingEvents: [EventItem] = []
    @Published private(set) var lastErrorMessage: String?

    private let repository: any CalendarRepository
    private let useCase: CalendarEventUseCase
    private let userDefaults: UserDefaults
    private let checkedCalendarsKey = "checkedCategory"

    init(
        repository: any CalendarRepository,
        userDefaults: UserDefaults = .standard
    ) {
        self.repository = repository
        useCase = CalendarEventUseCase(repository: repository)
        self.userDefaults = userDefaults
    }

    func reloadAll() async {
        do {
            try await loadCalendars()
            try await loadEvents()
            try await loadUpcomingEvents()
        } catch {
            return
        }
    }

    func refreshEvents() async {
        do {
            try await loadEvents()
        } catch {
            return
        }
    }

    func loadCalendars() async throws {
        calendars = try await perform {
            try await repository.loadCalendars()
        }
        initializeCheckedCalendarsIfNeeded()
    }

    func loadEvents() async throws {
        events = try await perform {
            try await repository.loadEvents(
                forDate: date,
                calendarIdentifiers: checkedCalendarIdentifiers
            )
        }
    }

    func loadUpcomingEvents() async throws {
        upcomingEvents = try await perform {
            try await repository.loadUpcomingEvents()
        }
    }

    func event(withIdentifier identifier: String) -> EventItem? {
        events.first { $0.id == identifier }
            ?? upcomingEvents.first { $0.id == identifier }
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
        let snapshot = try await perform {
            try await useCase.saveEvent(
                draft: EventDraft(
                    title: title,
                    isAllDay: isAllDay,
                    startDate: startDate,
                    endDate: endDate,
                    repeatType: repeatDate,
                    url: url,
                    notes: notes.map { "☐" + $0 }.joined(separator: "\n"),
                    calendarIdentifier: calendarIdentifier
                ),
                visibleDate: date,
                visibleCalendarIdentifiers: checkedCalendarIdentifiers
            )
        }
        apply(snapshot)
    }

    func updateEvent(_ event: EventItem) async throws {
        let snapshot = try await perform {
            try await useCase.update(
                event,
                visibleDate: date,
                visibleCalendarIdentifiers: checkedCalendarIdentifiers
            )
        }
        apply(snapshot)
    }

    func moveEvent(identifier: String, to targetDate: Date) async throws {
        do {
            guard let event = event(withIdentifier: identifier),
                  let movedEvent = EventSchedule.moving(event, toDay: targetDate) else {
                throw EventStoreError.itemNotFound
            }
            try await updateEvent(movedEvent)
        } catch {
            record(error)
            throw error
        }
    }

    func removeEvent(identifier: String) async throws {
        let snapshot = try await perform {
            try await useCase.remove(
                identifier: identifier,
                visibleDate: date,
                visibleCalendarIdentifiers: checkedCalendarIdentifiers
            )
        }
        apply(snapshot)
    }

    func createCalendar() async throws {
        try await perform {
            try await repository.createNewCalendar()
        }
        try await loadCalendars()
        try await loadEvents()
    }

    func updateCalendar(_ calendar: CalendarItem) async throws {
        try await perform {
            try await repository.updateCalendar(calendar)
        }
        try await loadCalendars()
        try await reloadEventSnapshot()
    }

    func removeCalendar(identifier: String) async throws {
        try await perform {
            try await repository.removeCalendar(identifier: identifier)
        }
        removeCheckedCalendar(identifier: identifier)
        try await loadCalendars()
        try await reloadEventSnapshot()
    }

    func setCalendar(identifier: String, isChecked: Bool) async {
        var identifiers = userDefaults.stringArray(forKey: checkedCalendarsKey) ?? []
        identifiers.removeAll { $0 == identifier }
        if isChecked {
            identifiers.append(identifier)
        }
        userDefaults.set(identifiers, forKey: checkedCalendarsKey)
        await refreshEvents()
    }

    func isCalendarChecked(identifier: String) -> Bool {
        checkedCalendarIdentifiers.contains(identifier)
    }

    func clear() {
        calendars = []
        events = []
        upcomingEvents = []
    }

    func clearError() {
        lastErrorMessage = nil
    }

    private var checkedCalendarIdentifiers: Set<String> {
        Set(userDefaults.stringArray(forKey: checkedCalendarsKey) ?? [])
    }

    private func reloadEventSnapshot() async throws {
        let snapshot = try await perform {
            try await useCase.loadSnapshot(
                for: date,
                calendarIdentifiers: checkedCalendarIdentifiers
            )
        }
        apply(snapshot)
    }

    private func apply(_ snapshot: CalendarEventSnapshot) {
        events = snapshot.events
        upcomingEvents = snapshot.upcomingEvents
    }

    private func initializeCheckedCalendarsIfNeeded() {
        let validIdentifiers = Set(calendars.map(\.id))
        if userDefaults.object(forKey: checkedCalendarsKey) == nil {
            userDefaults.set(Array(validIdentifiers), forKey: checkedCalendarsKey)
            return
        }

        let identifiers = userDefaults.stringArray(forKey: checkedCalendarsKey) ?? []
        let validSavedIdentifiers = identifiers.filter(validIdentifiers.contains)
        if identifiers != validSavedIdentifiers {
            userDefaults.set(validSavedIdentifiers, forKey: checkedCalendarsKey)
        }
    }

    private func removeCheckedCalendar(identifier: String) {
        var identifiers = userDefaults.stringArray(forKey: checkedCalendarsKey) ?? []
        identifiers.removeAll { $0 == identifier }
        userDefaults.set(identifiers, forKey: checkedCalendarsKey)
    }

    private func perform<Value>(_ operation: () async throws -> Value) async throws -> Value {
        do {
            return try await operation()
        } catch {
            record(error)
            throw error
        }
    }

    private func record(_ error: Error) {
        lastErrorMessage = error.localizedDescription
    }
}
