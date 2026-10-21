//
//  CalendarViewModel.swift
//  EazyCal
//
//  Created by apple on 10/26/23.
//

import EventKit


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
    
    func calculateSchedulesLayers(schedules: [CalendarEntry]) -> [(CalendarEntry, Int)] {
        let intervals = schedules.enumerated().map { index, schedule in
            CalendarMath.ScheduleInterval(
                index: index,
                start: schedule.startDate,
                end: schedule.endDate
            )
        }
        let assignments = CalendarMath.layerAssignments(for: intervals)
        return schedules.enumerated().map { ($0.element, assignments[$0.offset]) }
    }
    
    func schedules(
        monthStruct: Month,
        year: Int,
        month: Int,
        scheduler: [(CalendarEntry, Int)]
    ) -> [(CalendarEntry, Int)] {
        var currentDate = stringToDate(year: year, month: month, day: 20)
        
        if monthStruct.monthType == .Previous {
            currentDate = Calendar.current.date(byAdding: .month, value: -1, to: currentDate) ?? currentDate
        } else if monthStruct.monthType == .Current {

        } else {
            currentDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
        }
        
        var dateComponents = DateComponents()
        dateComponents.year = calendar.component(.year, from: currentDate)
        dateComponents.month = calendar.component(.month, from: currentDate)
        dateComponents.day = monthStruct.dayInt
        
        if let newDate = calendar.date(from: dateComponents) {
            currentDate = newDate
        }
        
        
        let schedules = scheduler.filter({ schedule, index in
            let startDate = calendar.startOfDay(for: schedule.startDate)
            let currentDate = calendar.startOfDay(for: currentDate)
            let endDate = schedule.endDate
            
            
            if startDate <= currentDate && currentDate <= endDate {
                return true
            } else {
                return false
            }
        })
        
        return schedules
    }
    
    func stringToDate(year: Int, month: Int, day: Int) -> Date {
        CalendarMath.date(year: year, month: month, day: day) ?? date
    }
}
