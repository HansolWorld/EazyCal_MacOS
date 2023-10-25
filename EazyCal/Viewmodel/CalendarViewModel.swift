//
//  CalendarViewModel.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import SwiftUI
import EventKit

class CalendarViewModel: ObservableObject {
    let calendar = Calendar.current
    let dateFormatter = DateFormatter()
    
    @Published var categories: [EKCalendar] = []
    @Published var allSchedules: [EKEvent] = []
    @Published var schedules: [EKEvent] = []
    @Published var todo: [EKReminder] = []
    @Published var date = Date()
    @Published var templates: [Template] = Template.dummyTemplates
    
    func monthYearString() -> String {
        dateFormatter.dateFormat = "yyyy년 MM월"
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
    
    func previousMonth() -> Date {
        guard let plusDate = calendar.date(byAdding: .month, value: 1, to: self.date) else { return Date() }
        return plusDate
    }
    
    func nextMonth() -> Date {
        guard let minusDate = calendar.date(byAdding: .month, value: -1, to: date) else { return Date() }
        return minusDate
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
    
    func calculateSchedulesLayers() -> [(EKEvent, Int)] {
        var layers: [(EKEvent, Int)] = []
        
        for schedule in schedules {
            let startDate = schedule.startDate ?? Date()
            let doDate = schedule.endDate ?? Date()
            
            var layer = Array(repeating: 0, count: schedules.count)
            
            for (existingSchedule, existingLayer) in layers {
                let existingStartDate = existingSchedule.startDate ?? Date()
                let existingDoDate = existingSchedule.endDate ?? Date()
                
                if startDate <= existingDoDate && existingStartDate <= doDate {
                    layer[existingLayer - 1] = 1
                }
            }
            let currentLayer = layer.firstIndex(of: 0) ?? 0
            layers.append((schedule, currentLayer+1))
        }

        return layers
    }
    
    func schedules(monthStruct: Month, year: Int, month: Int, scheduler: [(EKEvent, Int)]) -> [(EKEvent, Int)] {
        let currentDate: Date
        
        if monthStruct.monthType == .Previous {
            currentDate = stringToDate(year: year, month: month-1, day: monthStruct.dayInt)
        } else if monthStruct.monthType == .Current {
            currentDate = stringToDate(year: year, month: month, day: monthStruct.dayInt)
        } else {
            currentDate = stringToDate(year: year, month: month+1, day: monthStruct.dayInt)
        }
        
        let schedules = scheduler.filter({ schedule, index in
            let date1WithoutTime = calendar.startOfDay(for: schedule.startDate)
            let date2WithoutTime = calendar.startOfDay(for: currentDate)
            let date3WithoutTime = calendar.startOfDay(for: schedule.endDate)

            if date1WithoutTime <= date2WithoutTime && date2WithoutTime <= date3WithoutTime {
                return true
            } else {
                return false
            }
        })
        
        return schedules
    }
    
    func stringToDate(year: Int, month: Int, day: Int) -> Date {
        let dateString = "\(year)-\(month)-\(day)" // 예시 문자열

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd" // 입력 문자열의 날짜 형식을 지정

        if let date = dateFormatter.date(from: dateString) {
            return date
        } else {
            return Date()
        }
    }
    
    @MainActor
    func loadAllSchedule(eventStore: EventStore) async {
        self.allSchedules = await eventStore.loadEvents(forDate: Date(), calendars: categories.filter {Locale.checkList.contains($0.calendarIdentifier)})
    }
    
    @MainActor
    func loadSchedule(eventStore: EventStore) async {
        self.schedules = await eventStore.loadEvents(forDate: date, calendars: categories.filter {Locale.checkList.contains($0.calendarIdentifier)})
    }
    
    func filterSchedule() -> [EKEvent] {
        let todoInSchedule = self.allSchedules.filter {
            guard let notes = $0.notes else { return false }
            return notes.split(separator: "☐").count > 1
        }
        
        return todoInSchedule
    }
    
    func todosInSchedule(schedule: EKEvent) -> [String] {
        return schedule.notes!.components(separatedBy: "\n")
    }
    
    @MainActor
    func todos(eventStore: EventStore) async {
        self.todo = await eventStore.loadAllReminders()
    }
}
