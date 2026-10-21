//
//  CalendarEntry.swift
//  EazyCal
//

import EventKit
import Foundation

/// A presentation-friendly calendar item that can originate from either EventKit store.
struct CalendarEntry: Identifiable {
    enum Source {
        case event(EKEvent)
        case reminder(EKReminder)
    }

    let id: String
    let source: Source
    let title: String
    let startDate: Date
    let endDate: Date

    init(event: EKEvent) {
        let startDate = event.startDate ?? Date()
        let rawEndDate = event.endDate ?? startDate

        id = "event:\(event.eventIdentifier ?? event.calendarItemIdentifier)"
        source = .event(event)
        title = event.title ?? ""
        self.startDate = startDate
        // EventKit event end dates are exclusive. Using an inclusive display end keeps
        // midnight-ending events out of the following day's calendar cell.
        endDate = rawEndDate > startDate
            ? rawEndDate.addingTimeInterval(-1)
            : startDate
    }

    init?(reminder: EKReminder, calendar: Calendar = .current) {
        guard let dueDate = ReminderSchedule.date(
            from: reminder.dueDateComponents,
            calendar: calendar
        ) else {
            return nil
        }

        id = "reminder:\(reminder.calendarItemIdentifier)"
        source = .reminder(reminder)
        title = reminder.title ?? ""
        startDate = dueDate
        endDate = dueDate
    }
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
