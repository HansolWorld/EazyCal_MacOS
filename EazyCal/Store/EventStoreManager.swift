//
//  EventStoreManager.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import SwiftUI
import SwiftData
import EventKit

@MainActor
class EventStoreManager: ObservableObject {
    let eventStore = EventStore()
    var date = Date()
    
    @Published var calendars: [EKCalendar] = []
    @Published var allEvents: [EKEvent] = []
    @Published var events: [EKEvent] = []
    @Published var upcommingEvent: [EKEvent] = []
    @Published var todo: [EKReminder] = []
    
    init() {
        Task {
            do {
                try await self.loadCalendar()
                try await self.loadUpcommingEvents()
                try await self.loadReminder()
            } catch {
                print(error)
            }
        }
    }
    
    func loadCalendar() async throws {
        self.calendars = try await eventStore.loadCalendars()
    }
    
    
    func loadReminder() async throws {
        self.todo = try await eventStore.loadAllReminders()
    }
    
    func createNewReminder(title: String, date: Date?, highlight: String) async throws {
        try await eventStore.createNewReminder(title: title, date: date, highlight: highlight)
    }
    
    func completeReminder(reminder: EKReminder) async throws {
        try await eventStore.completeReminder(reminder: reminder)
    }
    
    func updateReminder(reminder: EKReminder) async throws {
        try await eventStore.updateReminder(reminder: reminder)
    }
    
//    func loadAllEvents() async {
//        let checkedCategory = UserDefaults.standard.array(forKey: "checkedCategory") as? [String] ?? []
//        let checkedCalendars = calendars.filter { checkedCategory.contains($0.calendarIdentifier) }
//        self.allEvents = await eventStore.loadEvents(forDate: Date(), calendars: checkedCalendars)
//    }
    
    func loadEvents() async throws {
        let checkedCalendar = UserDefaults.standard.array(forKey: "checkedCategory") as? [String] ?? []
        let checkedCalendars = calendars.filter { checkedCalendar.contains($0.calendarIdentifier) }
        
        self.events = try await eventStore.loadEvents(forDate: date, calendars: checkedCalendars)
    }
    
    func loadUpcommingEvents() async throws {
        self.upcommingEvent = try await eventStore.loadUpcommingEvents()
    }
    
    
    func filterEvents(events: [EKEvent]) -> [EKEvent] {
        let todoInSchedule = events.filter {
            guard let notes = $0.notes else { return false }
            return notes.contains("☐")
        }
        
        return todoInSchedule
    }
    
    func saveEvent(title: String, isAllDay: Bool, startDate: Date?, endDate: Date?, repeatDate: RepeatType, url: URL?, notes: [String], calendar: EKCalendar) async throws {
        try await eventStore.saveEvent(title: title, isAllDay: isAllDay, startDate: startDate, endDate: endDate, repeatDate: repeatDate, url: url, notes: notes, calendar: calendar)
    }
    
    func updateEvent(ekEvent: EKEvent) async throws {
        try await eventStore.updateEvent(ekevent: ekEvent)
    }
    
    func createNewCalendar() async throws {
        try await eventStore.createNewCalendar()
    }
    
    func updateCalendar(calendar: EKCalendar) async throws {
        try await eventStore.updateCalendar(calendar: calendar)
    }
    
    func removeCalendar(calendar: EKCalendar) async throws {
        try await eventStore.removeCalendar(calendar: calendar)
    }
    
    func removeEvent(event: EKEvent) async throws {
        try await eventStore.removeEvent(ekevent: event)
    }
}
