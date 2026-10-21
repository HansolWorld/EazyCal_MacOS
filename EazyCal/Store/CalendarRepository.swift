//
//  CalendarRepository.swift
//  EazyCal
//

import EventKit

protocol CalendarRepository: AnyObject {
    var calendarAuthorizationStatus: EKAuthorizationStatus { get }

    func requestCalendarAccess() async throws -> Bool
    func loadCalendars() async throws -> [EKCalendar]
    func loadUpcomingEvents() async throws -> [EKEvent]
    func loadEvents(forDate date: Date, calendars: [EKCalendar]) async throws -> [EKEvent]
    func createNewCalendar() async throws
    func updateCalendar(calendar: EKCalendar) async throws
    func removeCalendar(calendar: EKCalendar) async throws
    func saveEvent(
        title: String,
        isAllDay: Bool,
        startDate: Date,
        endDate: Date,
        repeatDate: RepeatType,
        url: URL?,
        notes: [String],
        calendar: EKCalendar
    ) async throws
    func updateEvent(event: EKEvent) async throws
    func removeEvent(event: EKEvent) async throws
}
