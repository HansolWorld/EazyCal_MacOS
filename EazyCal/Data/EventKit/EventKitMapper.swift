import EventKit

enum EventKitMapper {
    static func calendar(_ calendar: EKCalendar) -> CalendarItem {
        CalendarItem(
            id: calendar.calendarIdentifier,
            title: calendar.title,
            color: color(calendar.cgColor)
        )
    }

    static func event(_ event: EKEvent) -> EventItem {
        EventItem(
            id: event.eventIdentifier ?? event.calendarItemIdentifier,
            calendar: calendar(event.calendar),
            title: event.title ?? "",
            isAllDay: event.isAllDay,
            startDate: event.startDate ?? Date(),
            endDate: event.endDate ?? event.startDate ?? Date(),
            repeatType: repeatType(event.recurrenceRules?.first?.frequency),
            url: event.url,
            notes: event.notes ?? ""
        )
    }

    static func reminder(_ reminder: EKReminder) -> ReminderItem {
        ReminderItem(
            id: reminder.calendarItemIdentifier,
            title: reminder.title ?? "",
            priority: ReminderPriority(eventKitValue: reminder.priority),
            dueDateComponents: reminder.dueDateComponents,
            isCompleted: reminder.isCompleted,
            color: color(reminder.calendar?.cgColor)
        )
    }

    static func apply(_ draft: EventDraft, to event: EKEvent, calendar: EKCalendar) {
        event.title = draft.title
        event.isAllDay = draft.isAllDay
        event.startDate = draft.startDate
        event.endDate = max(draft.startDate, draft.endDate)
        event.notes = draft.notes
        event.calendar = calendar
        event.url = draft.url
        event.recurrenceRules = RecurrenceRuleFactory.rules(for: draft.repeatType)
    }

    static func apply(_ item: EventItem, to event: EKEvent, calendar: EKCalendar) {
        apply(
            EventDraft(
                title: item.title,
                isAllDay: item.isAllDay,
                startDate: item.startDate,
                endDate: item.endDate,
                repeatType: item.repeatType,
                url: item.url,
                notes: item.notes,
                calendarIdentifier: item.calendar.id
            ),
            to: event,
            calendar: calendar
        )
    }

    private static func repeatType(_ frequency: EKRecurrenceFrequency?) -> RepeatType {
        switch frequency {
        case .daily: .everyDay
        case .weekly: .everyWeek
        case .monthly: .everyMonth
        case .yearly: .everyYear
        default: .oneDay
        }
    }

    static func color(_ cgColor: CGColor?) -> CalendarColor {
        guard let components = cgColor?.components else {
            return .clear
        }
        if components.count >= 4 {
            return CalendarColor(
                red: components[0],
                green: components[1],
                blue: components[2],
                alpha: components[3]
            )
        }
        let white = components.first ?? 0
        return CalendarColor(red: white, green: white, blue: white, alpha: components.last ?? 1)
    }

    static func cgColor(_ color: CalendarColor) -> CGColor {
        CGColor(red: color.red, green: color.green, blue: color.blue, alpha: color.alpha)
    }
}

enum RecurrenceRuleFactory {
    static func rules(for repeatType: RepeatType) -> [EKRecurrenceRule]? {
        let frequency: EKRecurrenceFrequency
        switch repeatType {
        case .oneDay:
            return nil
        case .everyDay:
            frequency = .daily
        case .everyWeek:
            frequency = .weekly
        case .everyMonth:
            frequency = .monthly
        case .everyYear:
            frequency = .yearly
        }
        return [EKRecurrenceRule(recurrenceWith: frequency, interval: 1, end: nil)]
    }
}
