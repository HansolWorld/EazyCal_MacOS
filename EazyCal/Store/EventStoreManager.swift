//
//  EventStoreManager.swift
//  EazyCal
//

import SwiftUI
import EventKit

@MainActor
final class EventStoreManager: ObservableObject {
    private let calendarRepository: any CalendarRepository
    private let reminderRepository: any ReminderRepository
    private let calendarEventUseCase: CalendarEventUseCase
    private let reminderUseCase: ReminderUseCase
    private let userDefaults: UserDefaults
    private let checkedCalendarsKey = "checkedCategory"
    private var eventStoreObserver: NSObjectProtocol?

    var date = Date()

    @Published var calendars: [EKCalendar] = []
    @Published var events: [EKEvent] = []
    @Published var upcomingEvents: [EKEvent] = []
    @Published var reminders: [EKReminder] = []
    @Published var scheduledReminders: [EKReminder] = []
    @Published private(set) var calendarAuthorizationStatus: EKAuthorizationStatus
    @Published private(set) var reminderAuthorizationStatus: EKAuthorizationStatus
    @Published var lastErrorMessage: String?

    var hasCalendarAccess: Bool { calendarAuthorizationStatus == .fullAccess }
    var hasReminderAccess: Bool { reminderAuthorizationStatus == .fullAccess }

    init(
        calendarRepository: any CalendarRepository,
        reminderRepository: any ReminderRepository,
        userDefaults: UserDefaults = .standard
    ) {
        self.calendarRepository = calendarRepository
        self.reminderRepository = reminderRepository
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
            userDefaults: userDefaults
        )
    }

    func prepare() async {
        await requestAccess()
        await reloadAll()
    }

    func startObservingChanges() {
        guard eventStoreObserver == nil else { return }
        eventStoreObserver = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.reloadAll()
            }
        }
    }

    func stopObservingChanges() {
        guard let eventStoreObserver else { return }
        NotificationCenter.default.removeObserver(eventStoreObserver)
        self.eventStoreObserver = nil
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
        let checkedIdentifiers = userDefaults.stringArray(forKey: checkedCalendarsKey) ?? []
        let checkedCalendars = calendars.filter { checkedIdentifiers.contains($0.calendarIdentifier) }
        events = try await calendarRepository.loadEvents(forDate: date, calendars: checkedCalendars)
    }

    func loadUpcomingEvents() async throws {
        upcomingEvents = try await calendarRepository.loadUpcomingEvents()
    }

    func event(withIdentifier identifier: String) -> EKEvent? {
        events.first {
            ($0.eventIdentifier ?? $0.calendarItemIdentifier) == identifier
        }
    }

    func reminder(withIdentifier identifier: String) -> EKReminder? {
        scheduledReminders.first { $0.calendarItemIdentifier == identifier }
            ?? reminders.first { $0.calendarItemIdentifier == identifier }
    }

    func createNewReminder(title: String, date: Date?, highlight: String) async throws {
        do {
            let snapshot = try await reminderUseCase.create(
                title: title,
                date: date,
                highlight: highlight,
                visibleDate: self.date
            )
            apply(snapshot)
        } catch {
            record(error)
            throw error
        }
    }

    func completeReminder(reminder: EKReminder) async throws {
        do {
            let snapshot = try await reminderUseCase.complete(reminder, visibleDate: date)
            apply(snapshot)
        } catch {
            record(error)
            throw error
        }
    }

    func updateReminder(reminder: EKReminder) async throws {
        do {
            let snapshot = try await reminderUseCase.update(reminder, visibleDate: date)
            apply(snapshot)
        } catch {
            record(error)
            throw error
        }
    }

    func rescheduleReminder(_ reminder: EKReminder, to targetDate: Date) async throws {
        do {
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
        calendar: EKCalendar
    ) async throws {
        do {
            let snapshot = try await calendarEventUseCase.saveEvent(
                title: title,
                isAllDay: isAllDay,
                startDate: startDate,
                endDate: endDate,
                repeatDate: repeatDate,
                url: url,
                notes: notes,
                calendar: calendar,
                visibleDate: date,
                visibleCalendars: checkedCalendars
            )
            apply(snapshot)
        } catch {
            record(error)
            throw error
        }
    }

    func updateEvent(event: EKEvent) async throws {
        do {
            let snapshot = try await calendarEventUseCase.update(
                event,
                visibleDate: date,
                visibleCalendars: checkedCalendars
            )
            apply(snapshot)
        } catch {
            record(error)
            throw error
        }
    }

    func removeEvent(event: EKEvent) async throws {
        do {
            let snapshot = try await calendarEventUseCase.remove(
                event,
                visibleDate: date,
                visibleCalendars: checkedCalendars
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

    func updateCalendar(calendar: EKCalendar) async throws {
        do {
            try await calendarRepository.updateCalendar(calendar: calendar)
            try await loadCalendars()
            try await reloadEvents()
        } catch {
            record(error)
            throw error
        }
    }

    func removeCalendar(calendar: EKCalendar) async throws {
        do {
            try await calendarRepository.removeCalendar(calendar: calendar)
            removeCheckedCalendar(identifier: calendar.calendarIdentifier)
            try await loadCalendars()
            try await reloadEvents()
        } catch {
            record(error)
            throw error
        }
    }

    func setCalendar(_ calendar: EKCalendar, isChecked: Bool) async {
        var identifiers = userDefaults.stringArray(forKey: checkedCalendarsKey) ?? []
        identifiers.removeAll { $0 == calendar.calendarIdentifier }
        if isChecked {
            identifiers.append(calendar.calendarIdentifier)
        }
        userDefaults.set(identifiers, forKey: checkedCalendarsKey)

        do {
            try await loadEvents()
        } catch {
            record(error)
        }
    }

    func isCalendarChecked(_ calendar: EKCalendar) -> Bool {
        userDefaults.stringArray(forKey: checkedCalendarsKey)?.contains(calendar.calendarIdentifier) == true
    }

    private func reloadEvents() async throws {
        apply(try await calendarEventUseCase.loadSnapshot(for: date, calendars: checkedCalendars))
    }

    private func reloadReminderData() async throws {
        apply(try await reminderUseCase.loadSnapshot(for: date))
    }

    private var checkedCalendars: [EKCalendar] {
        let checkedIdentifiers = userDefaults.stringArray(forKey: checkedCalendarsKey) ?? []
        return calendars.filter { checkedIdentifiers.contains($0.calendarIdentifier) }
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
        let validIdentifiers = Set(calendars.map(\.calendarIdentifier))
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
