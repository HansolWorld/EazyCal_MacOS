import EventKit

enum EventKitAuthorization {
    static func status(for entityType: EKEntityType) -> AuthorizationStatus {
        EKEventStore.authorizationStatus(for: entityType).domainStatus
    }

    static func requireFullAccess(for entityType: EKEntityType) throws {
        let status = EKEventStore.authorizationStatus(for: entityType)
        guard status == .fullAccess else {
            throw status.eventStoreError ?? EventStoreError.denied
        }
    }
}

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
            .denied
        case .restricted:
            .restricted
        case .writeOnly:
            .upgrade
        default:
            nil
        }
    }
}
