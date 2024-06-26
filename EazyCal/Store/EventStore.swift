//
//  EventStore.swift
//  EazyCal
//
//  Created by apple on 10/23/23.
//

import EventKit

class EventStore: ObservableObject {
    let eventStore = EKEventStore()
    
    func loadCalendars() async throws -> [EKCalendar]{
        var result: [EKCalendar] = []
        guard try await eventStore.requestFullAccessToEvents() else { return []}
        
        let calendars = self.eventStore.calendars(for: .event)
        let notTitle = calendars.filter { $0.title == "무제" || $0.title == "Untitled" }
        let existTitle = calendars.filter { $0.title != "무제" && $0.title != "Untitled" }
        
        result += existTitle.sorted(by: {
                $0.title < $1.title
        })
        result += notTitle
        
        return result
    }

    func loadUpcommingEvents() async throws -> [EKEvent] {
        if try await eventStore.requestFullAccessToEvents() {
            let calendars = self.eventStore.calendars(for: .event)
            
            let startOfDay = Calendar.current.startOfDay(for: Date())
            let sevenDaysLater = startOfDay.addingTimeInterval(30 * 24 * 60 * 60)
            
            let predicate = self.eventStore.predicateForEvents(withStart: startOfDay, end: sevenDaysLater, calendars: calendars)
            let events = self.eventStore.events(matching: predicate)
            
            return events
        }
        
        return []
    }
    
    func loadAllEvents() async throws -> [EKEvent] {
        if try await eventStore.requestFullAccessToEvents() {
            let calendars = self.eventStore.calendars(for: .event)
            let predicate = self.eventStore.predicateForEvents(withStart: Date.distantPast, end: Date.distantFuture, calendars: calendars)
            let events = self.eventStore.events(matching: predicate)
            return events
        }

        return []
    }
    
    func loadEvents(forDate date: Date, calendars: [EKCalendar]) async throws -> [EKEvent] {
        var schedules:[EKEvent] = []
        
        let calendar = Calendar.current
        let startDateComponents = calendar.dateComponents([.year, .month], from: date)
        let dateComponent = calendar.date(from: startDateComponents)!
        let startDate = calendar.date(byAdding: DateComponents(month: -1, day: 1), to: dateComponent)!
        let endDate = calendar.date(byAdding: DateComponents(month: 2, day: 0), to: dateComponent)!

        guard try await self.eventStore.requestFullAccessToEvents() else { return [] }
        
        let predicate = self.eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        let events = self.eventStore.events(matching: predicate)
        schedules = events.sorted(by: {$0.startDate < $1.startDate})
    
        return schedules
    }
    
    func loadAllReminders() async throws -> [EKReminder] {
        var reminders: [EKReminder] = []

        guard try await eventStore.requestFullAccessToReminders() else { return [] }
        let predicate = eventStore.predicateForReminders(in: nil)
        reminders = try await eventStore.reminders(matching: predicate)
    
        reminders = reminders.filter { $0.isCompleted == false }
        return reminders
    }
    
    func completeReminder(reminder: EKReminder) async throws {
        reminder.isCompleted = true
        
        try eventStore.save(reminder, commit: true)
    }
    
    func updateReminder(reminder: EKReminder) async throws {
        try eventStore.save(reminder, commit: true)
    }
    
    func createNewReminder(title: String, date: Date?, highlight: String) async throws {
        if try await eventStore.requestFullAccessToReminders() {
            let newReminder = EKReminder(eventStore: self.eventStore)
            newReminder.title = title
            
            switch highlight {
            case String(localized: "LOW"):
                newReminder.priority = 9
            case String(localized: "MID"):
                newReminder.priority = 5
            case String(localized: "HIGH"):
                newReminder.priority = 1
            default:
                newReminder.priority = 0
            }
            
            if let date = date {
                newReminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            }
            newReminder.calendar = self.eventStore.defaultCalendarForNewReminders()
            try eventStore.save(newReminder, commit: true)
        }
    }
    
    func createNewCalendar() async throws {
        let newCalendar = EKCalendar(for: .event, eventStore: self.eventStore)
        newCalendar.title = String(localized: "DEFAULT_CALENDAR_TITLE")
        newCalendar.cgColor = CGColor(red: Double.random(in: 0...1), green: Double.random(in: 0...1), blue: Double.random(in: 0...1), alpha: Double.random(in: 0...1))
        newCalendar.source = self.eventStore.defaultCalendarForNewEvents?.source
        
        try self.eventStore.saveCalendar(newCalendar, commit: true)
    }
    
    func updateCalendar(calendar: EKCalendar) async throws {
        try self.eventStore.saveCalendar(calendar, commit: true)
    }
    
    func removeCalendar(calendar: EKCalendar) async throws {
        try self.eventStore.removeCalendar(calendar, commit: true)
    }
    
    
    func saveEvent(title: String, isAllDay: Bool, startDate: Date?, endDate: Date?, repeatDate: RepeatType, url: URL?, notes: [String], calendar: EKCalendar) async throws {
        let event = EKEvent(eventStore: self.eventStore)
        event.title = title
        event.isAllDay = isAllDay
        event.startDate = startDate
        
        if let startDate, let endDate, startDate > endDate {
            event.endDate = startDate
        } else {
            event.endDate = endDate
        }
        event.notes = notes.map { "☐" + $0 }.joined(separator: "\n")
        event.calendar = calendar
        event.url = url
        
        switch repeatDate {
        case .oneDay:
            event.recurrenceRules = nil
        case .everyDay:
            event.recurrenceRules = [EKRecurrenceRule(recurrenceWith: .daily, interval: 1, end: EKRecurrenceEnd(end: Date().addingTimeInterval(60 * 60 * 24 * 7 * 8)))]
        case .everyWeek:
            event.recurrenceRules = [EKRecurrenceRule(recurrenceWith: .weekly, interval: 1, end: EKRecurrenceEnd(end: Date().addingTimeInterval(60 * 60 * 24 * 7 * 8)))]
        case .everyMonth:
            event.recurrenceRules = [EKRecurrenceRule(recurrenceWith: .monthly, interval: 1, end: EKRecurrenceEnd(end: Date().addingTimeInterval(60 * 60 * 24 * 7 * 8)))]
        case .everyYear:
            event.recurrenceRules = [EKRecurrenceRule(recurrenceWith: .yearly, interval: 1, end: EKRecurrenceEnd(end: Date().addingTimeInterval(60 * 60 * 24 * 7 * 8)))]
        }
        
        try self.eventStore.save(event, span: .thisEvent)
    }
    
    func updateEvent(ekevent: EKEvent) async throws {
        try self.eventStore.save(ekevent, span: .thisEvent, commit: true)
    }
    
    func removeEvent(ekevent: EKEvent) async throws {
        try self.eventStore.remove(ekevent, span: .futureEvents, commit: true)
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
