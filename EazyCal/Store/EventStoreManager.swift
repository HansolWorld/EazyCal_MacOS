//
//  EventStoreManager.swift
//  EazyCal
//

import SwiftUI
import EventKit

@MainActor
final class EventStoreManager: ObservableObject {
    private let eventStore: any EventStoreProviding
    private let userDefaults: UserDefaults
    private let checkedCalendarsKey = "checkedCategory"
    private var eventStoreObserver: NSObjectProtocol?

    var date = Date()

    @Published var calendars: [EKCalendar] = []
    @Published var events: [EKEvent] = []
    @Published var upcomingEvents: [EKEvent] = []
    @Published var reminders: [EKReminder] = []
    @Published private(set) var calendarAuthorizationStatus: EKAuthorizationStatus
    @Published private(set) var reminderAuthorizationStatus: EKAuthorizationStatus
    @Published var lastErrorMessage: String?

    var hasCalendarAccess: Bool { calendarAuthorizationStatus == .fullAccess }
    var hasReminderAccess: Bool { reminderAuthorizationStatus == .fullAccess }

    init(
        eventStore: any EventStoreProviding = EventStore(),
        userDefaults: UserDefaults = .standard
    ) {
        self.eventStore = eventStore
        self.userDefaults = userDefaults
        calendarAuthorizationStatus = eventStore.calendarAuthorizationStatus
        reminderAuthorizationStatus = eventStore.reminderAuthorizationStatus
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
                _ = try await eventStore.requestCalendarAccess()
            }
            calendarAuthorizationStatus = eventStore.calendarAuthorizationStatus
        } catch {
            record(error)
        }

        do {
            if reminderAuthorizationStatus == .notDetermined {
                _ = try await eventStore.requestReminderAccess()
            }
            reminderAuthorizationStatus = eventStore.reminderAuthorizationStatus
        } catch {
            record(error)
        }
    }

    func reloadAll() async {
        calendarAuthorizationStatus = eventStore.calendarAuthorizationStatus
        reminderAuthorizationStatus = eventStore.reminderAuthorizationStatus

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
                try await loadReminders()
            } catch {
                record(error)
            }
        } else {
            reminders = []
        }
    }

    func loadCalendars() async throws {
        calendars = try await eventStore.loadCalendars()
        initializeCheckedCalendarsIfNeeded()
    }

    func loadReminders() async throws {
        reminders = try await eventStore.loadAllReminders()
    }

    func loadEvents() async throws {
        let checkedIdentifiers = userDefaults.stringArray(forKey: checkedCalendarsKey) ?? []
        let checkedCalendars = calendars.filter { checkedIdentifiers.contains($0.calendarIdentifier) }
        events = try await eventStore.loadEvents(forDate: date, calendars: checkedCalendars)
    }

    func loadUpcomingEvents() async throws {
        upcomingEvents = try await eventStore.loadUpcomingEvents()
    }

    func createNewReminder(title: String, date: Date?, highlight: String) async throws {
        do {
            try await eventStore.createNewReminder(title: title, date: date, highlight: highlight)
            try await loadReminders()
        } catch {
            record(error)
            throw error
        }
    }

    func completeReminder(reminder: EKReminder) async throws {
        do {
            try await eventStore.completeReminder(reminder: reminder)
            try await loadReminders()
        } catch {
            record(error)
            throw error
        }
    }

    func updateReminder(reminder: EKReminder) async throws {
        do {
            try await eventStore.updateReminder(reminder: reminder)
            try await loadReminders()
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
            try await eventStore.saveEvent(
                title: title,
                isAllDay: isAllDay,
                startDate: startDate,
                endDate: endDate,
                repeatDate: repeatDate,
                url: url,
                notes: notes,
                calendar: calendar
            )
            try await reloadEvents()
        } catch {
            record(error)
            throw error
        }
    }

    func updateEvent(event: EKEvent) async throws {
        do {
            try await eventStore.updateEvent(event: event)
            try await reloadEvents()
        } catch {
            record(error)
            throw error
        }
    }

    func removeEvent(event: EKEvent) async throws {
        do {
            try await eventStore.removeEvent(event: event)
            try await reloadEvents()
        } catch {
            record(error)
            throw error
        }
    }

    func createNewCalendar() async throws {
        do {
            try await eventStore.createNewCalendar()
            try await loadCalendars()
            try await loadEvents()
        } catch {
            record(error)
            throw error
        }
    }

    func updateCalendar(calendar: EKCalendar) async throws {
        do {
            try await eventStore.updateCalendar(calendar: calendar)
            try await loadCalendars()
            try await reloadEvents()
        } catch {
            record(error)
            throw error
        }
    }

    func removeCalendar(calendar: EKCalendar) async throws {
        do {
            try await eventStore.removeCalendar(calendar: calendar)
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
        try await loadEvents()
        try await loadUpcomingEvents()
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
