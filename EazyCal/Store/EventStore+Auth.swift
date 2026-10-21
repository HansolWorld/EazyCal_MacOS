//
//  EventStore+Auth.swift
//  EazyCal
//

import EventKit

extension EKAuthorizationStatus {
    var domainStatus: AuthorizationStatus {
        switch self {
        case .notDetermined: .notDetermined
        case .restricted: .restricted
        case .denied: .denied
        case .writeOnly: .writeOnly
        case .fullAccess: .fullAccess
        @unknown default: .unknown
        }
    }

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
    var calendarAuthorizationStatus: AuthorizationStatus {
        EKEventStore.authorizationStatus(for: .event).domainStatus
    }

    var reminderAuthorizationStatus: AuthorizationStatus {
        EKEventStore.authorizationStatus(for: .reminder).domainStatus
    }

    func requestCalendarAccess() async throws -> Bool {
        try await eventStore.requestFullAccessToEvents()
    }

    func requestReminderAccess() async throws -> Bool {
        try await eventStore.requestFullAccessToReminders()
    }
}
