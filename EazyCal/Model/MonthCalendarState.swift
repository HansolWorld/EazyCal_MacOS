//
//  MonthCalendarState.swift
//  EazyCal
//

import Foundation

enum MonthCalendarFilter: Equatable {
    case all
    case uncategorized(categorizedCalendarIdentifiers: Set<String>)
    case calendars(Set<String>)

    func includes(_ entry: CalendarEntry) -> Bool {
        guard entry.kind == .event else {
            return true
        }

        switch self {
        case .all:
            return true
        case .uncategorized(let categorizedIdentifiers):
            guard let identifier = entry.calendarIdentifier else { return true }
            return !categorizedIdentifiers.contains(identifier)
        case .calendars(let identifiers):
            guard let identifier = entry.calendarIdentifier else { return false }
            return identifiers.contains(identifier)
        }
    }
}

struct LayeredCalendarEntry: Identifiable, Equatable {
    let entry: CalendarEntry
    let layer: Int

    var id: String { entry.id }
}

struct MonthCalendarState: Equatable {
    let entries: [LayeredCalendarEntry]

    init(
        entries: [CalendarEntry],
        filter: MonthCalendarFilter,
        calendar: Calendar = .current
    ) {
        let visibleEntries = entries.filter(filter.includes)
        let intervals = visibleEntries.enumerated().map { index, entry in
            CalendarMath.ScheduleInterval(
                index: index,
                start: entry.startDate,
                end: entry.endDate
            )
        }
        let assignments = CalendarMath.layerAssignments(for: intervals, calendar: calendar)
        self.entries = visibleEntries.enumerated().map {
            LayeredCalendarEntry(entry: $0.element, layer: assignments[$0.offset])
        }
    }

    func entries(on date: Date, calendar: Calendar = .current) -> [LayeredCalendarEntry] {
        let day = calendar.startOfDay(for: date)
        return entries.filter {
            let start = calendar.startOfDay(for: $0.entry.startDate)
            let end = calendar.startOfDay(for: $0.entry.endDate)
            return start <= day && day <= end
        }
    }
}
