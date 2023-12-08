//
//  EventStore.swift
//  EazyCal
//
//  Created by apple on 10/23/23.
//

import EventKit

class EventStore: ObservableObject {
    let eventStore = EKEventStore()
    
    init() {
        guard isFullAccessAuthorized else { return }
    }
    
    func loadCalendars() async -> [EKCalendar]{
        var result: [EKCalendar] = []
        do {
            guard try await eventStore.requestFullAccessToEvents() else { return []}
            
            let calendars = self.eventStore.calendars(for: .event)
            result = calendars
        } catch {
            return []
        }
        
        return result
    }

    func loadUpcommingEvents() async -> [EKEvent] {
        do {
            if try await eventStore.requestFullAccessToEvents() {
                let calendars = self.eventStore.calendars(for: .event)
                
                let startOfDay = Calendar.current.startOfDay(for: Date())
                let sevenDaysLater = startOfDay.addingTimeInterval(30 * 24 * 60 * 60)
                
                let predicate = self.eventStore.predicateForEvents(withStart: startOfDay, end: sevenDaysLater, calendars: calendars)
                let events = self.eventStore.events(matching: predicate)
                
                return events
            }
        } catch {
            return []
        }
        
        return []
    }
    
    func loadAllEvents() async -> [EKEvent] {
        do {
            if try await eventStore.requestFullAccessToEvents() {
                let calendars = self.eventStore.calendars(for: .event)
                let predicate = self.eventStore.predicateForEvents(withStart: Date.distantPast, end: Date.distantFuture, calendars: calendars)
                let events = self.eventStore.events(matching: predicate)
                return events
            }
        } catch {
            return []
        }
        
        return []
    }
    
    func loadEvents(forDate date: Date, calendars: [EKCalendar]) async -> [EKEvent] {
        var schedules:[EKEvent] = []
        
        let calendar = Calendar.current
        let startDateComponents = calendar.dateComponents([.year, .month], from: date)
        let dateComponent = calendar.date(from: startDateComponents)!
        let startDate = calendar.date(byAdding: DateComponents(month: -1, day: 1), to: dateComponent)!
        let endDate = calendar.date(byAdding: DateComponents(month: 2, day: 0), to: dateComponent)!

        do {
            guard try await self.eventStore.requestFullAccessToEvents() else { return [] }
            
            let predicate = self.eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
            let events = self.eventStore.events(matching: predicate)
            schedules = events.sorted(by: {$0.startDate < $1.startDate})
        } catch {
            return []
        }
        return schedules
    }
    
    func loadAllReminders() async -> [EKReminder] {
        var reminders: [EKReminder] = []
        do {
            guard try await eventStore.requestFullAccessToReminders() else { return [] }
            let predicate = eventStore.predicateForReminders(in: nil)
            reminders = try await eventStore.reminders(matching: predicate)
        } catch {
        }
        
        reminders = reminders.filter { $0.isCompleted == false }
        return reminders
    }
    
    func completeReminder(reminder: EKReminder) async throws{
        reminder.isCompleted = true
        
        try eventStore.save(reminder, commit: true)
    }
    
    func updateReminder(reminder: EKReminder) async throws {
        try eventStore.save(reminder, commit: true)
    }
    
    func createNewReminder(title: String, date: Date?, highlight: String) async {
        do {
            if try await eventStore.requestFullAccessToReminders() {
                let newReminder = EKReminder(eventStore: self.eventStore)
                newReminder.title = title
                
                switch highlight {
                case "낮음":
                    newReminder.priority = 9
                case "중간":
                    newReminder.priority = 5
                case "높음":
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
        } catch {
            print(error)
        }
    }
    
    func createNewCalendar() async throws {
        let newCalendar = EKCalendar(for: .event, eventStore: self.eventStore)
        newCalendar.title = "무제"
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
    
    
    func saveEvent(title: String, isAllDay: Bool, startDate: Date?, endDate: Date?, repeatDate: RepeatType, notes: [String], calendar: EKCalendar) async throws {
        let event = EKEvent(eventStore: self.eventStore)
        event.title = title
        event.isAllDay = isAllDay
        event.startDate = startDate
        event.endDate = endDate
        event.notes = notes.map { "☐" + $0 }.joined(separator: "\n")
        event.calendar = calendar
        
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
