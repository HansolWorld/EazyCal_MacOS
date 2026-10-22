import EventKit

final class EventKitReminderRepository: ReminderRepository {
    private let eventStore: EKEventStore

    var reminderAuthorizationStatus: AuthorizationStatus {
        EventKitAuthorization.status(for: .reminder)
    }

    init(eventStore: EKEventStore) {
        self.eventStore = eventStore
    }

    func requestReminderAccess() async throws -> Bool {
        try await eventStore.requestFullAccessToReminders()
    }

    func loadAllReminders() async throws -> [ReminderItem] {
        try EventKitAuthorization.requireFullAccess(for: .reminder)
        let predicate = eventStore.predicateForIncompleteReminders(
            withDueDateStarting: nil,
            ending: nil,
            calendars: nil
        )
        return try await eventStore.reminders(matching: predicate).map(EventKitMapper.reminder)
    }

    func loadScheduledReminders(from startDate: Date, to endDate: Date) async throws -> [ReminderItem] {
        try EventKitAuthorization.requireFullAccess(for: .reminder)
        let predicate = eventStore.predicateForIncompleteReminders(
            withDueDateStarting: startDate,
            ending: endDate,
            calendars: nil
        )
        return try await eventStore.reminders(matching: predicate)
            .sorted {
                let left = ReminderSchedule.date(from: $0.dueDateComponents) ?? .distantFuture
                let right = ReminderSchedule.date(from: $1.dueDateComponents) ?? .distantFuture
                return left < right
            }
            .map(EventKitMapper.reminder)
    }

    func completeReminder(identifier: String) async throws {
        try EventKitAuthorization.requireFullAccess(for: .reminder)
        let reminder = try reminder(withIdentifier: identifier)
        reminder.isCompleted = true
        try eventStore.save(reminder, commit: true)
    }

    func updateReminder(_ item: ReminderItem) async throws {
        try EventKitAuthorization.requireFullAccess(for: .reminder)
        let reminder = try reminder(withIdentifier: item.id)
        reminder.title = item.title
        reminder.priority = item.priority.rawValue
        reminder.dueDateComponents = item.dueDateComponents
        reminder.isCompleted = item.isCompleted
        try eventStore.save(reminder, commit: true)
    }

    func createNewReminder(_ draft: ReminderDraft) async throws {
        try EventKitAuthorization.requireFullAccess(for: .reminder)
        guard let calendar = eventStore.defaultCalendarForNewReminders() else {
            throw EventStoreError.missingDefaultCalendar
        }

        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = draft.title
        reminder.priority = draft.priority.rawValue
        if let date = draft.date {
            reminder.dueDateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: date
            )
        }
        reminder.calendar = calendar
        try eventStore.save(reminder, commit: true)
    }

    private func reminder(withIdentifier identifier: String) throws -> EKReminder {
        guard let reminder = eventStore.calendarItem(withIdentifier: identifier) as? EKReminder else {
            throw EventStoreError.itemNotFound
        }
        return reminder
    }
}

extension EKEventStore {
    func reminders(matching predicate: NSPredicate) async throws -> [EKReminder] {
        try await withCheckedThrowingContinuation { continuation in
            fetchReminders(matching: predicate) { reminders in
                if let reminders {
                    continuation.resume(returning: reminders)
                } else {
                    continuation.resume(throwing: EventStoreError.unknown)
                }
            }
        }
    }
}
