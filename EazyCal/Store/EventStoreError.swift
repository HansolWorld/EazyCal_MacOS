//
//  EventStoreError.swift
//  EazyCal
//
//  Created by apple on 10/23/23.
//

import Foundation

enum EventStoreError: Error {
    case denied
    case restricted
    case unknown
    case upgrade
    case invalidDate
    case missingDefaultCalendar
}

extension EventStoreError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .denied:
            return NSLocalizedString("The app doesn't have permission to Calendar in Settings.", comment: "Access denied")
         case .restricted:
            return NSLocalizedString("This device doesn't allow access to Calendar.", comment: "Access restricted")
        case .unknown:
            return NSLocalizedString("An unknown error occured.", comment: "Unknown error")
        case .upgrade:
            let access = "The app has write-only access to Calendar in Settings."
            let update = "Please grant it full access so the app can fetch and delete your events."
            return NSLocalizedString("\(access) \(update)", comment: "Upgrade to full access")
        case .invalidDate:
            return NSLocalizedString("The requested date could not be created.", comment: "Invalid date")
        case .missingDefaultCalendar:
            return NSLocalizedString("A writable default calendar is not available.", comment: "Missing default calendar")
        }
    }
}
