//
//  CalendarEntryMapper.swift
//  EazyCal
//

import Foundation

enum CalendarEntryMapper {
    static func map(_ event: EventItem) -> CalendarEntry {
        let startDate = event.startDate
        let rawEndDate = event.endDate

        return CalendarEntry(
            id: "event:\(event.id)",
            sourceIdentifier: event.id,
            kind: .event,
            calendarIdentifier: event.calendar.id,
            title: event.title,
            startDate: startDate,
            // EventKit end dates are exclusive. The domain interval is inclusive.
            endDate: rawEndDate > startDate
                ? rawEndDate.addingTimeInterval(-1)
                : startDate,
            isAllDay: event.isAllDay
        )
    }

    static func map(
        _ reminder: ReminderItem,
        calendar: Calendar = .current
    ) -> CalendarEntry? {
        guard let dueDate = ReminderSchedule.date(
            from: reminder.dueDateComponents,
            calendar: calendar
        ) else {
            return nil
        }
        return CalendarEntry(
            id: "reminder:\(reminder.id)",
            sourceIdentifier: reminder.id,
            kind: .reminder,
            calendarIdentifier: nil,
            title: reminder.title,
            startDate: dueDate,
            endDate: dueDate,
            isAllDay: reminder.dueDateComponents?.hour == nil
        )
    }
}
