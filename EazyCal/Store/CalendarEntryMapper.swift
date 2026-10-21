//
//  CalendarEntryMapper.swift
//  EazyCal
//

import EventKit

enum CalendarEntryMapper {
    static func map(_ event: EKEvent) -> CalendarEntry {
        let startDate = event.startDate ?? Date()
        let rawEndDate = event.endDate ?? startDate
        let identifier = event.eventIdentifier ?? event.calendarItemIdentifier

        return CalendarEntry(
            id: "event:\(identifier)",
            sourceIdentifier: identifier,
            kind: .event,
            calendarIdentifier: event.calendar?.calendarIdentifier,
            title: event.title ?? "",
            startDate: startDate,
            // EventKit end dates are exclusive. The domain interval is inclusive.
            endDate: rawEndDate > startDate
                ? rawEndDate.addingTimeInterval(-1)
                : startDate,
            isAllDay: event.isAllDay
        )
    }

    static func map(
        _ reminder: EKReminder,
        calendar: Calendar = .current
    ) -> CalendarEntry? {
        guard let dueDate = ReminderSchedule.date(
            from: reminder.dueDateComponents,
            calendar: calendar
        ) else {
            return nil
        }
        let identifier = reminder.calendarItemIdentifier

        return CalendarEntry(
            id: "reminder:\(identifier)",
            sourceIdentifier: identifier,
            kind: .reminder,
            calendarIdentifier: nil,
            title: reminder.title ?? "",
            startDate: dueDate,
            endDate: dueDate,
            isAllDay: reminder.dueDateComponents?.hour == nil
        )
    }
}
