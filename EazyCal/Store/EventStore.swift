//
//  EventStore.swift
//  EazyCal
//
//  Created by apple on 10/23/23.
//

import EventKit

class EventStore: ObservableObject {
    var calendaries: [EKCalendar] = []
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
            print(error)
        }
        
        calendaries = result
        return result
    }

    func createNewCalendar(title: String, color: CGColor) async {
        do {
            if try await eventStore.requestFullAccessToEvents() {
                let newCalendar = EKCalendar(for: .event, eventStore: self.eventStore)
                newCalendar.title = title
                newCalendar.cgColor = color
                newCalendar.source = self.eventStore.defaultCalendarForNewEvents?.source
                
                do {
                    try self.eventStore.saveCalendar(newCalendar, commit: true)
                } catch {
                    print(error)
                }
            }
        } catch {
            print(error)
        }
    }

    func saveEvent(title: String, isAllDay: Bool, startDate: Date, endDate: Date, repeatDate: RepeatType, notes: [String], calendar: EKCalendar) async {
        do {
            if try await eventStore.requestFullAccessToEvents() {
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
                
                do {
                    try self.eventStore.save(event, span: .thisEvent)
                } catch {
                }
            }
        } catch {
        }
    }
    
    func loadAllEvents() async -> [EKEvent] {
        var schedules:[EKEvent] = []
        
        do {
            if try await eventStore.requestFullAccessToEvents() {
                let calendars = self.eventStore.calendars(for: .event)
                let predicate = self.eventStore.predicateForEvents(withStart: Date.distantPast, end: Date.distantFuture, calendars: calendars)
                let events = self.eventStore.events(matching: predicate)
                schedules = events
            }
        } catch {
            print(error)
        }
        
        return schedules
    }
    
    func loadEvents(forDate date: Date, calendars: [EKCalendar]) async -> [EKEvent] {
        var schedules:[EKEvent] = []
        
        let calendar = Calendar.current
        let startDateComponents = calendar.dateComponents([.year, .month], from: date)
        let startDate = calendar.date(from: startDateComponents)!
        let endDate = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startDate)!
        
        do {
            guard try await self.eventStore.requestFullAccessToEvents() else { return [] }
            
            let predicate = self.eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
            let events = self.eventStore.events(matching: predicate)
            for event in events {
                schedules.append(event)
            }
        } catch {
            print(error)
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
            print(error)
        }
        
        reminders = reminders.filter { $0.isCompleted == false }
        return reminders
    }
    
    func createNewReminder(title: String, date: Date?, highlight: Bool) async {
        do {
            if try await eventStore.requestFullAccessToReminders() {
                let newReminder = EKReminder(eventStore: self.eventStore)
                newReminder.title = title
                newReminder.notes = highlight ? "강조" : ""
                newReminder.completionDate = date
                newReminder.calendar = self.eventStore.defaultCalendarForNewReminders()
                
                do {
                    try self.eventStore.save(newReminder, commit: true)
                } catch {
                    print(error)
                }
            }
        } catch {
            print(error)
        }
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
