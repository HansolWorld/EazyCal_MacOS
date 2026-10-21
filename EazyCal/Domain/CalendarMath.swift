//
//  CalendarMath.swift
//  EazyCal
//

import Foundation

enum CalendarMath {
    struct ScheduleInterval: Equatable {
        let index: Int
        let start: Date
        let end: Date
    }

    static func visibleMonthInterval(
        containing date: Date,
        calendar: Calendar = .current
    ) throws -> DateInterval {
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let firstOfMonth = calendar.date(from: components),
              let start = calendar.date(byAdding: .month, value: -1, to: firstOfMonth),
              let end = calendar.date(byAdding: .month, value: 2, to: firstOfMonth) else {
            throw EventStoreError.invalidDate
        }
        return DateInterval(start: start, end: end)
    }

    static func date(
        year: Int,
        month: Int,
        day: Int,
        calendar: Calendar = .current
    ) -> Date? {
        calendar.date(from: DateComponents(year: year, month: month, day: day))
    }

    static func date(
        year: Int,
        month: Int,
        day: Int,
        hour: Int?,
        minute: Int?,
        calendar: Calendar = .current
    ) -> Date? {
        calendar.date(
            from: DateComponents(
                year: year,
                month: month,
                day: day,
                hour: hour,
                minute: minute
            )
        )
    }

    static func moving(_ date: Date, toDay targetDay: Date, calendar: Calendar = .current) -> Date? {
        let time = calendar.dateComponents([.hour, .minute, .second], from: date)
        var target = calendar.dateComponents([.year, .month, .day], from: targetDay)
        target.hour = time.hour
        target.minute = time.minute
        target.second = time.second
        return calendar.date(from: target)
    }

    static func layerAssignments(
        for intervals: [ScheduleInterval],
        calendar: Calendar = .current
    ) -> [Int] {
        var assignments = Array(repeating: 1, count: intervals.count)
        var occupied: [[DateInterval]] = []

        for interval in intervals {
            let normalized = normalizedDayInterval(
                start: interval.start,
                end: interval.end,
                calendar: calendar
            )
            let layer = occupied.firstIndex { layerIntervals in
                layerIntervals.allSatisfy { !$0.intersects(normalized) }
            } ?? occupied.count

            if layer == occupied.count {
                occupied.append([normalized])
            } else {
                occupied[layer].append(normalized)
            }
            assignments[interval.index] = layer + 1
        }
        return assignments
    }

    private static func normalizedDayInterval(
        start: Date,
        end: Date,
        calendar: Calendar
    ) -> DateInterval {
        let startOfDay = calendar.startOfDay(for: start)
        let adjustedEnd = end > start ? end.addingTimeInterval(-1) : end
        let endOfDay = calendar.date(
            byAdding: .day,
            value: 1,
            to: calendar.startOfDay(for: adjustedEnd)
        ) ?? adjustedEnd
        return DateInterval(start: startOfDay, end: endOfDay)
    }
}
