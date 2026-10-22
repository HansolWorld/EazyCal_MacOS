import Combine
import Foundation

@MainActor
final class EventStorePermissionStore: ObservableObject {
    @Published private(set) var calendarAuthorizationStatus: AuthorizationStatus
    @Published private(set) var reminderAuthorizationStatus: AuthorizationStatus
    @Published private(set) var lastErrorMessage: String?

    private let calendarRepository: any CalendarRepository
    private let reminderRepository: any ReminderRepository

    var hasCalendarAccess: Bool { calendarAuthorizationStatus == .fullAccess }
    var hasReminderAccess: Bool { reminderAuthorizationStatus == .fullAccess }

    init(
        calendarRepository: any CalendarRepository,
        reminderRepository: any ReminderRepository
    ) {
        self.calendarRepository = calendarRepository
        self.reminderRepository = reminderRepository
        calendarAuthorizationStatus = calendarRepository.calendarAuthorizationStatus
        reminderAuthorizationStatus = reminderRepository.reminderAuthorizationStatus
    }

    func requestAccess() async {
        if calendarAuthorizationStatus == .notDetermined {
            do {
                _ = try await calendarRepository.requestCalendarAccess()
            } catch {
                record(error)
            }
        }
        calendarAuthorizationStatus = calendarRepository.calendarAuthorizationStatus

        if reminderAuthorizationStatus == .notDetermined {
            do {
                _ = try await reminderRepository.requestReminderAccess()
            } catch {
                record(error)
            }
        }
        reminderAuthorizationStatus = reminderRepository.reminderAuthorizationStatus
    }

    func refreshStatuses() {
        calendarAuthorizationStatus = calendarRepository.calendarAuthorizationStatus
        reminderAuthorizationStatus = reminderRepository.reminderAuthorizationStatus
    }

    func clearError() {
        lastErrorMessage = nil
    }

    private func record(_ error: Error) {
        lastErrorMessage = error.localizedDescription
    }
}
