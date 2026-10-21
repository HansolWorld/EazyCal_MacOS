//
//  EventModels.swift
//  EazyCal
//

import Foundation

enum AuthorizationStatus: Equatable {
    case notDetermined
    case restricted
    case denied
    case writeOnly
    case fullAccess
    case unknown
}

struct CalendarColor: Equatable, Hashable {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double

    static let clear = CalendarColor(red: 0, green: 0, blue: 0, alpha: 0)
}

struct CalendarItem: Identifiable, Equatable, Hashable {
    let id: String
    var title: String
    var color: CalendarColor
}

struct EventItem: Identifiable, Equatable {
    let id: String
    var calendar: CalendarItem
    var title: String
    var isAllDay: Bool
    var startDate: Date
    var endDate: Date
    var repeatType: RepeatType
    var url: URL?
    var notes: String
}

struct EventDraft: Equatable {
    let title: String
    let isAllDay: Bool
    let startDate: Date
    let endDate: Date
    let repeatType: RepeatType
    let url: URL?
    let notes: String
    let calendarIdentifier: String
}

struct ReminderItem: Identifiable, Equatable {
    let id: String
    var title: String
    var priority: Int
    var dueDateComponents: DateComponents?
    var isCompleted: Bool
    var color: CalendarColor
}

struct ReminderDraft: Equatable {
    let title: String
    let date: Date?
    let priority: Int
}
