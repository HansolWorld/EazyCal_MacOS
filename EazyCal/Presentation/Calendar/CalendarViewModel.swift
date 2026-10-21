//
//  CalendarViewModel.swift
//  EazyCal
//
//  Created by apple on 10/26/23.
//

import Foundation


class CalendarViewModel: ObservableObject {
    let calendar = Calendar.current
    let dateFormatter = DateFormatter()
    
    @Published var date = Date()
    //    @Published var templates: [Template] = Template.dummyTemplates
    
    func monthYearString() -> String {
        dateFormatter.dateFormat = String(localized: "DATE_FORMAT")
        return dateFormatter.string(from: self.date)
    }
    
    func plusMonth() {
        guard let plusDate = calendar.date(byAdding: .month, value: 1, to: self.date) else { return }
        self.date = plusDate
    }
    
    func minusMonth() {
        guard let minusDate = calendar.date(byAdding: .month, value: -1, to: date) else { return }
        self.date = minusDate
    }
    
    func nextMonth() -> Date {
        guard let minusDate = calendar.date(byAdding: .month, value: 1, to: date) else { return Date() }
        return minusDate
    }
    
    func previousMonth() -> Date {
        guard let plusDate = calendar.date(byAdding: .month, value: -1, to: self.date) else { return Date() }
        return plusDate
    }
    
    func daysInMonth(_ date: Date?) -> Int {
        if let date = date {
            guard let range = calendar.range(of: .day, in: .month, for: date) else { return 0 }
            return range.count
        } else {
            guard let range = calendar.range(of: .day, in: .month, for: self.date) else { return 0 }
            return range.count
        }
    }
    
    func dayOfMonth() -> Int {
        guard let components = calendar.dateComponents([.day], from: date).day else { return 0 }
        return components
    }
    
    func firstOfMonth() -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let firstDate = calendar.date(from: components) else { return Date() }
        return firstDate
    }
    
    func weekDay(_ date: Date) -> Int {
        guard let components = calendar.dateComponents([.weekday], from: date).weekday else { return 0 }
        return components - 1
    }
    
    func year() -> Int {
        return calendar.component(.year, from: date)
    }
    
    func month() -> Int {
        return calendar.component(.month, from: date)
    }
    
    func date(for month: Month) -> Date {
        guard let firstOfCurrentMonth = CalendarMath.date(
            year: year(),
            month: self.month(),
            day: 1,
            calendar: calendar
        ) else { return date }

        let monthOffset: Int
        switch month.monthType {
        case .Previous: monthOffset = -1
        case .Current: monthOffset = 0
        case .Next: monthOffset = 1
        }

        let targetMonth = calendar.date(
            byAdding: .month,
            value: monthOffset,
            to: firstOfCurrentMonth
        ) ?? firstOfCurrentMonth
        var components = calendar.dateComponents([.year, .month], from: targetMonth)
        components.day = month.dayInt
        return calendar.date(from: components) ?? targetMonth
    }
    
    func stringToDate(year: Int, month: Int, day: Int) -> Date {
        CalendarMath.date(year: year, month: month, day: day) ?? date
    }
}
