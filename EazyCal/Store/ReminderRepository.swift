//
//  ReminderRepository.swift
//  EazyCal
//

import Foundation

protocol ReminderRepository: AnyObject {
    var reminderAuthorizationStatus: AuthorizationStatus { get }

    func requestReminderAccess() async throws -> Bool
    func loadAllReminders() async throws -> [ReminderItem]
    func loadScheduledReminders(from startDate: Date, to endDate: Date) async throws -> [ReminderItem]
    func completeReminder(identifier: String) async throws
    func updateReminder(_ reminder: ReminderItem) async throws
    func createNewReminder(_ draft: ReminderDraft) async throws
}

protocol EventStoreChangeObserving: AnyObject {
    func startObservingChanges(_ handler: @escaping @MainActor () -> Void)
    func stopObservingChanges()
}
