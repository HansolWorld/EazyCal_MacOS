//
//  EventStoreManager.swift
//  EazyCal
//

import SwiftUI

@MainActor
final class EventStoreManager: ObservableObject {
    private let calendarRepository: any CalendarRepository
    private let reminderRepository: any ReminderRepository
    private let changeObserver: (any EventStoreChangeObserving)?
    private let calendarEventUseCase: CalendarEventUseCase
    private let reminderUseCase: ReminderUseCase
    private let userDefaults: UserDefaults
    private let checkedCalendarsKey = "checkedCategory"

    var date = Date()

    @Published var calendars: [CalendarItem] = []
    @Published var events: [EventItem] = []
    @Published var upcomingEvents: [EventItem] = []
    @Published var reminders: [ReminderItem] = []
    @Published var scheduledReminders: [ReminderItem] = []
    @Published private(set) var calendarAuthorizationStatus: AuthorizationStatus
    @Published private(set) var reminderAuthorizationStatus: AuthorizationStatus
    @Published var lastErrorMessage: String?

    var hasCalendarAccess: Bool { calendarAuthorizationStatus == .fullAccess }
    var hasReminderAccess: Bool { reminderAuthorizationStatus == .fullAccess }

    init(
        calendarRepository: any CalendarRepository,
        reminderRepository: any ReminderRepository,
        changeObserver: (any EventStoreChangeObserving)? = nil,
        userDefaults: UserDefaults = .standard
    ) {
        self.calendarRepository = calendarRepository
        self.reminderRepository = reminderRepository
        self.changeObserver = changeObserver
        calendarEventUseCase = CalendarEventUseCase(repository: calendarRepository)
        reminderUseCase = ReminderUseCase(repository: reminderRepository)
        self.userDefaults = userDefaults
        calendarAuthorizationStatus = calendarRepository.calendarAuthorizationStatus
        reminderAuthorizationStatus = reminderRepository.reminderAuthorizationStatus
    }

    convenience init(userDefaults: UserDefaults = .standard) {
        let eventStore = EventStore()
        self.init(
            calendarRepository: eventStore,
            reminderRepository: eventStore,
            changeObserver: eventStore,
            userDefaults: userDefaults
        )
    }

    func prepare() async {
        await requestAccess()
        await reloadAll()
    }

    func startObservingChanges() {
        changeObserver?.startObservingChanges { [weak self] in
            Task { @MainActor [weak self] in
                await self?.reloadAll()
            }
        }
    }

    func stopObservingChanges() {
        changeObserver?.stopObservingChanges()
    }

    func requestAccess() async {
        do {
            if calendarAuthorizationStatus == .notDetermined {
                _ = try await calendarRepository.requestCalendarAccess()
            }
            calendarAuthorizationStatus = calendarRepository.calendarAuthorizationStatus
        } catch {
            record(error)
        }

        do {
            if reminderAuthorizationStatus == .notDetermined {
                _ = try await reminderRepository.requestReminderAccess()
            }
            reminderAuthorizationStatus = reminderRepository.reminderAuthorizationStatus
        } catch {
            record(error)
        }
    }

    func reloadAll() async {
        calendarAuthorizationStatus = calendarRepository.calendarAuthorizationStatus
        reminderAuthorizationStatus = reminderRepository.reminderAuthorizationStatus

        if hasCalendarAccess {
            do {
                try await loadCalendars()
                try await loadEvents()
                try await loadUpcomingEvents()
            } catch {
                record(error)
            }
        } else {
            calendars = []
            events = []
            upcomingEvents = []
        }

        if hasReminderAccess {
            do {
                try await reloadReminderData()
            } catch {
                record(error)
            }
        } else {
            reminders = []
            scheduledReminders = []
        }
    }

    func loadCalendars() async throws {
        calendars = try await calendarRepository.loadCalendars()
        initializeCheckedCalendarsIfNeeded()
    }

    func loadReminders() async throws {
        reminders = try await reminderRepository.loadAllReminders()
    }

    func loadScheduledReminders() async throws {
        let interval = try CalendarMath.visibleMonthInterval(containing: date)
        scheduledReminders = try await reminderRepository.loadScheduledReminders(
            from: interval.start,
            to: interval.end
        )
    }

    func refreshCalendarEntries() async {
        if hasCalendarAccess {
            do {
                try await loadEvents()
            } catch {
                record(error)
            }
        }
        if hasReminderAccess {
            do {
                try await loadScheduledReminders()
            } catch {
                record(error)
            }
        }
    }

    func loadEvents() async throws {
        events = try await calendarRepository.loadEvents(
            forDate: date,
            calendarIdentifiers: checkedCalendarIdentifiers
        )
    }

    func loadUpcomingEvents() async throws {
        upcomingEvents = try await calendarRepository.loadUpcomingEvents()
    }

    func event(withIdentifier identifier: String) -> EventItem? {
        events.first { $0.id == identifier }
            ?? upcomingEvents.first { $0.id == identifier }
    }

    func reminder(withIdentifier identifier: String) -> ReminderItem? {
        scheduledReminders.first { $0.id == identifier }
            ?? reminders.first { $0.id == identifier }
    }

    func createNewReminder(title: String, date: Date?, highlight: String) async throws {
        do {
            let snapshot = try await reminderUseCase.create(
                draft: ReminderDraft(
                    title: title,
                    date: date,
                    priority: ReminderPriority.priority(for: highlight)
                ),
                visibleDate: self.date
            )
            apply(snapshot)
        } catch {
            record(error)
            throw error
        }
    }

    func completeReminder(identifier: String) async throws {
        do {
            let snapshot = try await reminderUseCase.complete(
                identifier: identifier,
                visibleDate: date
            )
            apply(snapshot)
        } catch {
            record(error)
            throw error
        }
    }

    func updateReminder(reminder: ReminderItem) async throws {
        do {
            let snapshot = try await reminderUseCase.update(reminder, visibleDate: date)
            apply(snapshot)
        } catch {
            record(error)
            throw error
        }
    }

    func rescheduleReminder(identifier: String, to targetDate: Date) async throws {
        do {
            guard let reminder = reminder(withIdentifier: identifier) else {
                throw EventStoreError.itemNotFound
            }
            let snapshot = try await reminderUseCase.reschedule(
                reminder,
                to: targetDate,
                visibleDate: date
            )
            apply(snapshot)
        } catch {
            record(error)
            throw error
        }
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
        do {
            let snapshot = try await calendarEventUseCase.saveEvent(
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
            apply(snapshot)
        } catch {
            record(error)
            throw error
        }
    }

    func updateEvent(event: EventItem) async throws {
        do {
            let snapshot = try await calendarEventUseCase.update(
                event,
                visibleDate: date,
                visibleCalendarIdentifiers: checkedCalendarIdentifiers
            )
            apply(snapshot)
        } catch {
            record(error)
            throw error
        }
    }

    func moveEvent(identifier: String, to targetDate: Date) async throws {
        do {
            guard let event = event(withIdentifier: identifier),
                  let movedEvent = EventSchedule.moving(event, toDay: targetDate) else {
                throw EventStoreError.itemNotFound
            }
            try await updateEvent(event: movedEvent)
        } catch {
            record(error)
            throw error
        }
    }

    func removeEvent(identifier: String) async throws {
        do {
            let snapshot = try await calendarEventUseCase.remove(
                identifier: identifier,
                visibleDate: date,
                visibleCalendarIdentifiers: checkedCalendarIdentifiers
            )
            apply(snapshot)
        } catch {
            record(error)
            throw error
        }
    }

    func createNewCalendar() async throws {
        do {
            try await calendarRepository.createNewCalendar()
            try await loadCalendars()
            try await loadEvents()
        } catch {
            record(error)
            throw error
        }
    }

    func updateCalendar(calendar: CalendarItem) async throws {
        do {
            try await calendarRepository.updateCalendar(calendar)
            try await loadCalendars()
            try await reloadEvents()
        } catch {
            record(error)
            throw error
        }
    }

    func removeCalendar(identifier: String) async throws {
        do {
            try await calendarRepository.removeCalendar(identifier: identifier)
            removeCheckedCalendar(identifier: identifier)
            try await loadCalendars()
            try await reloadEvents()
        } catch {
            record(error)
            throw error
        }
    }

    func setCalendar(identifier: String, isChecked: Bool) async {
        var identifiers = userDefaults.stringArray(forKey: checkedCalendarsKey) ?? []
        identifiers.removeAll { $0 == identifier }
        if isChecked {
            identifiers.append(identifier)
        }
        userDefaults.set(identifiers, forKey: checkedCalendarsKey)

        do {
            try await loadEvents()
        } catch {
            record(error)
        }
    }

    func isCalendarChecked(identifier: String) -> Bool {
        checkedCalendarIdentifiers.contains(identifier)
    }

    private func reloadEvents() async throws {
        apply(try await calendarEventUseCase.loadSnapshot(
            for: date,
            calendarIdentifiers: checkedCalendarIdentifiers
        ))
    }

    private func reloadReminderData() async throws {
        apply(try await reminderUseCase.loadSnapshot(for: date))
    }

    private var checkedCalendarIdentifiers: Set<String> {
        Set(userDefaults.stringArray(forKey: checkedCalendarsKey) ?? [])
    }

    private func apply(_ snapshot: CalendarEventSnapshot) {
        events = snapshot.events
        upcomingEvents = snapshot.upcomingEvents
    }

    private func apply(_ snapshot: ReminderSnapshot) {
        reminders = snapshot.reminders
        scheduledReminders = snapshot.scheduledReminders
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

    private func record(_ error: Error) {
        lastErrorMessage = error.localizedDescription
    }
}
