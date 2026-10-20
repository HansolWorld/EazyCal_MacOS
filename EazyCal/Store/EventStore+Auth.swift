//
//  EventStore+Auth.swift
//  EazyCal
//

import EventKit

extension EKAuthorizationStatus {
    var eventStoreError: EventStoreError? {
        switch self {
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .writeOnly:
            return .upgrade
        default:
            return nil
        }
    }
}

extension EventStore {
    var calendarAuthorizationStatus: EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .event)
    }

    var reminderAuthorizationStatus: EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .reminder)
    }

    func requestCalendarAccess() async throws -> Bool {
        try await eventStore.requestFullAccessToEvents()
    }

    func requestReminderAccess() async throws -> Bool {
        try await eventStore.requestFullAccessToReminders()
    }
}
