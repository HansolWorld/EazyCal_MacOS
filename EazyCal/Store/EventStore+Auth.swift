//
//  EventStore+Auth.swift
//  EazyCal
//
//  Created by apple on 10/23/23.
//

import EventKit

extension EventStore {
    var isFullAccessAuthorized: Bool {
        EKEventStore.authorizationStatus(for: .event) == .fullAccess
    }
    
//    func isAccessPermission() async throws {
//        switch EKEventStore.authorizationStatus(for: .event) {
//        case .notDetermined:
//            try await requestFullAccess()
//        case .restricted:
//            try await requestFullAccess()
//        case .denied:
//            try await requestFullAccess()
//        case .fullAccess:
//            print()
//        default:
//            try await requestFullAccess()
//        }
//    }
//    
//    private func requestFullAccess() async throws {
//        if #available(iOS 17.0, *) {
//            try await self.eventStore.requestFullAccessToEvents()
//        } else {
//            // Fall back on earlier versions.
//            try await self.eventStore.requestAccess(to: .event)
//        }
//    }
}
