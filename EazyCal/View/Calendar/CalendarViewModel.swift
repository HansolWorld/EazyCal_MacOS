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
    
    func calculateSchedulesLayers(schedules: [EKEvent]) -> [(EKEvent, Int)] {
        let calendarCurrent = Calendar.current
        var layers: [(EKEvent, Int)] = []
        
        for schedule in schedules {
            let componentSet: Set<Calendar.Component> = [.month, .day]
            
            let startDate = schedule.startDate ?? Date()
            let startDateComponent = calendarCurrent.dateComponents(componentSet, from: startDate)
            let (startMonth, startDay) = (startDateComponent.month, startDateComponent.day)
            
            let endDate = schedule.endDate ?? Date()
            let endDateComponent = calendarCurrent.dateComponents(componentSet, from: endDate)
            let (endMonth, endDay) = (endDateComponent.month, endDateComponent.day)
            
            var layer = Array(repeating: 0, count: schedules.count)
            for (existingSchedule, existingLayer) in layers {
                let existingStartDate = existingSchedule.startDate ?? Date()
                let existingStartDateComponent = calendarCurrent.dateComponents(componentSet, from: existingStartDate)
                let (existingStartMonth, existingStartDay) = (existingStartDateComponent.month, existingStartDateComponent.day)
                
                let existingEndDate = existingSchedule.endDate ?? Date()
                let existingEndDateComponent = calendarCurrent.dateComponents(componentSet, from: existingEndDate)
                let (existingEndMonth, existingEndDay) = (existingEndDateComponent.month, existingEndDateComponent.day)
                
                if 
                    (startMonth == existingStartMonth && startDay == existingStartDay && startDate >= existingStartDate)
                    || (endMonth == existingEndMonth && endDay == existingEndDay && endDate >= existingEndDate)
                    || (startMonth == existingEndMonth && startDay == existingEndDay)
                {
                    layer[existingLayer - 1] = 1
                }
            }
            
            let currentLayer = layer.firstIndex(of: 0) ?? 0
            layers.append((schedule, currentLayer+1))
        }

        return layers
    }
    
    func schedules(monthStruct: Month, year: Int, month: Int, scheduler: [(EKEvent, Int)]) -> [(EKEvent, Int)] {
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
            let endDate = schedule.endDate ?? startDate
            
            
            if startDate <= currentDate && currentDate <= endDate {
                return true
            } else {
                return false
            }
        })
        
        return schedules
    }
    
    func stringToDate(year: Int, month: Int, day: Int) -> Date {
        let dateString = "\(year)-\(month)-\(day)"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        if let date = dateFormatter.date(from: dateString) {
            return date
        } else {
            return Date()
        }
    }
}
