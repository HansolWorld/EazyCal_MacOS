//
//  ReminderRepository.swift
//  EazyCal
//

import EventKit

protocol ReminderRepository: AnyObject {
    var reminderAuthorizationStatus: EKAuthorizationStatus { get }

    func requestReminderAccess() async throws -> Bool
    func loadAllReminders() async throws -> [EKReminder]
    func loadScheduledReminders(from startDate: Date, to endDate: Date) async throws -> [EKReminder]
    func completeReminder(reminder: EKReminder) async throws
    func updateReminder(reminder: EKReminder) async throws
    func createNewReminder(title: String, date: Date?, highlight: String) async throws
}
