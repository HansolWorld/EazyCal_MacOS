import Combine
import Foundation

@MainActor
final class ReminderFeatureStore: ObservableObject {
    @Published var date = Date()
    @Published var reminders: [ReminderItem] = []
    @Published var scheduledReminders: [ReminderItem] = []
    @Published private(set) var lastErrorMessage: String?

    private let repository: any ReminderRepository
    private let useCase: ReminderUseCase

    init(repository: any ReminderRepository) {
        self.repository = repository
        useCase = ReminderUseCase(repository: repository)
    }

    func reloadAll() async {
        do {
            try await reloadSnapshot()
        } catch {
            return
        }
    }

    func refreshScheduledReminders() async {
        do {
            try await loadScheduledReminders()
        } catch {
            return
        }
    }

    func loadReminders() async throws {
        reminders = try await perform {
            try await repository.loadAllReminders()
        }
    }

    func loadScheduledReminders() async throws {
        let interval = try CalendarMath.visibleMonthInterval(containing: date)
        scheduledReminders = try await perform {
            try await repository.loadScheduledReminders(
                from: interval.start,
                to: interval.end
            )
        }
    }

    func reminder(withIdentifier identifier: String) -> ReminderItem? {
        scheduledReminders.first { $0.id == identifier }
            ?? reminders.first { $0.id == identifier }
    }

    func createReminder(title: String, date: Date?, priority: ReminderPriority) async throws {
        let snapshot = try await perform {
            try await useCase.create(
                draft: ReminderDraft(
                    title: title,
                    date: date,
                    priority: priority
                ),
                visibleDate: self.date
            )
        }
        apply(snapshot)
    }

    func completeReminder(identifier: String) async throws {
        let snapshot = try await perform {
            try await useCase.complete(identifier: identifier, visibleDate: date)
        }
        apply(snapshot)
    }

    func updateReminder(_ reminder: ReminderItem) async throws {
        let snapshot = try await perform {
            try await useCase.update(reminder, visibleDate: date)
        }
        apply(snapshot)
    }

    func rescheduleReminder(identifier: String, to targetDate: Date) async throws {
        do {
            guard let reminder = reminder(withIdentifier: identifier) else {
                throw EventStoreError.itemNotFound
            }
            let snapshot = try await useCase.reschedule(
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

    func clear() {
        reminders = []
        scheduledReminders = []
    }

    func clearError() {
        lastErrorMessage = nil
    }

    private func reloadSnapshot() async throws {
        let snapshot = try await perform {
            try await useCase.loadSnapshot(for: date)
        }
        apply(snapshot)
    }

    private func apply(_ snapshot: ReminderSnapshot) {
        reminders = snapshot.reminders
        scheduledReminders = snapshot.scheduledReminders
    }

    private func perform<Value>(_ operation: () async throws -> Value) async throws -> Value {
        do {
            return try await operation()
        } catch {
            record(error)
            throw error
        }
    }

    private func record(_ error: Error) {
        lastErrorMessage = error.localizedDescription
    }
}
