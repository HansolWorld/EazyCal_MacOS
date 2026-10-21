//
//  CalendarRepository.swift
//  EazyCal
//

import Foundation

protocol CalendarRepository: AnyObject {
    var calendarAuthorizationStatus: AuthorizationStatus { get }

    func requestCalendarAccess() async throws -> Bool
    func loadCalendars() async throws -> [CalendarItem]
    func loadUpcomingEvents() async throws -> [EventItem]
    func loadEvents(forDate date: Date, calendarIdentifiers: Set<String>) async throws -> [EventItem]
    func createNewCalendar() async throws
    func updateCalendar(_ calendar: CalendarItem) async throws
    func removeCalendar(identifier: String) async throws
    func saveEvent(_ draft: EventDraft) async throws
    func updateEvent(_ event: EventItem) async throws
    func removeEvent(identifier: String) async throws
}
