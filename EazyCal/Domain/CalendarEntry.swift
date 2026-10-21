//
//  CalendarEntry.swift
//  EazyCal
//

import Foundation

enum CalendarEntryKind: Equatable {
    case event
    case reminder
}

/// Framework-independent value used by the calendar domain and presentation layers.
struct CalendarEntry: Identifiable, Equatable {
    let id: String
    let sourceIdentifier: String
    let kind: CalendarEntryKind
    let calendarIdentifier: String?
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
}

enum ReminderSchedule {
    static func date(
        from components: DateComponents?,
        calendar fallbackCalendar: Calendar = .current
    ) -> Date? {
        guard let components else { return nil }

        var calendar = components.calendar ?? fallbackCalendar
        if let timeZone = components.timeZone {
            calendar.timeZone = timeZone
        }
        return calendar.date(from: components)
    }

    static func moving(
        _ components: DateComponents?,
        toDay targetDate: Date,
        calendar: Calendar = .current
    ) -> DateComponents {
        var moved = calendar.dateComponents([.year, .month, .day], from: targetDate)
        moved.calendar = components?.calendar
        moved.timeZone = components?.timeZone

        if let components, components.hour != nil {
            moved.hour = components.hour
            moved.minute = components.minute
            moved.second = components.second
        }

        return moved
    }
}

enum EventSchedule {
    static func moving(
        _ event: EventItem,
        toDay targetDate: Date,
        calendar: Calendar = .current
    ) -> EventItem? {
        guard let movedStartDate = CalendarMath.moving(
            event.startDate,
            toDay: targetDate,
            calendar: calendar
        ) else {
            return nil
        }

        var movedEvent = event
        let duration = event.endDate.timeIntervalSince(event.startDate)
        movedEvent.startDate = movedStartDate
        movedEvent.endDate = movedStartDate.addingTimeInterval(duration)
        return movedEvent
    }
}
