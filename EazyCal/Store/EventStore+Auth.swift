//
//  EventStore+Auth.swift
//  EazyCal
//
//  Created by apple on 10/23/23.
//

import EventKit

extension EventStore {
    var isFullAccessAuthorized: Bool {
        if #available(iOS 17.0, *) {
            EKEventStore.authorizationStatus(for: .event) == .fullAccess
        } else {
            // Fall back on earlier versions.
            EKEventStore.authorizationStatus(for: .event) == .authorized
        }
    }
    
    func isAccessPermission(store: EKEventStore) async throws -> Bool {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .notDetermined:
            return try await requestFullAccess()
        case .restricted:
            throw EventStoreError.restricted
        case .denied:
            throw EventStoreError.denied
        case .fullAccess:
            return true
        case .writeOnly:
            return true
        default:
            throw EventStoreError.unknown
        }
    }
    
    private func requestFullAccess() async throws -> Bool {
        if #available(iOS 17.0, *) {
            return try await eventStore.requestFullAccessToEvents()
        } else {
            // Fall back on earlier versions.
            return try await eventStore.requestAccess(to: .event)
        }
    }
}
