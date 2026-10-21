//
//  CalendarGridView.swift
//  EazyCal
//

import EventKit
import SwiftData
import SwiftUI

struct CalendarWeekdayHeaderView: View {
    private let weekdays = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(weekdays.enumerated()), id: \.offset) { index, weekday in
                Text(String(localized: String.LocalizationValue(weekday)))
                    .foregroundStyle(index == 0 ? Color.red : Color.black)
                    .padding(.leading, 6)
                Spacer()
            }
        }
    }
}

struct CalendarGridView: View {
    @ObservedObject var calendarViewModel: CalendarViewModel
    @Binding var currentDragTemplate: Template?
    @Binding var selectedEvent: EKEvent?
    @Binding var selectedReminder: EKReminder?
    @EnvironmentObject private var eventManager: EventStoreManager
    @Query(sort: \CalendarCategory.date, animation: .snappy) private var categories: [CalendarCategory]

    var body: some View {
        let daysInMonth = calendarViewModel.daysInMonth(nil)
        let firstWeekday = calendarViewModel.weekDay(calendarViewModel.firstOfMonth())
        let start = firstWeekday == 0 ? firstWeekday + 7 : firstWeekday
        let daysInPreviousMonth = calendarViewModel.daysInMonth(calendarViewModel.previousMonth())
        let calendarEntries = eventManager.events.map(CalendarEntryMapper.map)
            + eventManager.scheduledReminders.compactMap { CalendarEntryMapper.map($0) }
        let calendarState = MonthCalendarState(
            entries: calendarEntries,
            filter: selectedCalendarFilter
        )

        VStack(spacing: 0) {
            ForEach(0..<6) { row in
                HStack(spacing: 0) {
                    ForEach(1..<8) { column in
                        let count = column + (row * 7)
                        let month = monthValue(
                            count: count,
                            start: start,
                            daysInMonth: daysInMonth,
                            daysInPreviousMonth: daysInPreviousMonth
                        )
                        let cellDate = calendarViewModel.date(for: month)

                        CalendarCell(
                            schedules: calendarState.entries(on: cellDate),
                            month: month,
                            isToday: Calendar.current.isDateInToday(cellDate),
                            count: count,
                            start: start,
                            daysInMonth: daysInMonth,
                            daysInPrevMonth: daysInPreviousMonth,
                            calendarViewModel: calendarViewModel,
                            currentDragTemplate: $currentDragTemplate,
                            selectedEvent: $selectedEvent,
                            selectedReminder: $selectedReminder
                        )

                        if column != 7 {
                            Divider()
                                .frame(width: 1)
                                .overlay(Color.calendarLine)
                        }
                    }
                }

                if row != 5 {
                    Divider()
                        .frame(height: 1)
                        .overlay(Color.calendarLine)
                }
            }
        }
    }

    private var selectedCalendarFilter: MonthCalendarFilter {
        guard let category = categories.first(where: { $0.isSelected == true }) else {
            return .calendars([])
        }

        if category.title == String(localized: "TOTAL") {
            return .all
        }
        if category.title == String(localized: "NOT_CATEGORY") {
            let categorizedIdentifiers = Set(categories.dropFirst(2).flatMap(\.calendars))
            return .uncategorized(categorizedCalendarIdentifiers: categorizedIdentifiers)
        }
        return .calendars(Set(category.calendars))
    }

    private func monthValue(
        count: Int,
        start: Int,
        daysInMonth: Int,
        daysInPreviousMonth: Int
    ) -> Month {
        if count <= start {
            return Month(
                monthType: .Previous,
                dayInt: daysInPreviousMonth + count - start
            )
        }
        if count - start > daysInMonth {
            return Month(
                monthType: .Next,
                dayInt: count - start - daysInMonth
            )
        }
        return Month(monthType: .Current, dayInt: count - start)
    }
}
