//
//  CalendarViewModel.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import SwiftUI

class CalendarViewModel: ObservableObject {
    let calendar = Calendar.current
    let dateFormatter = DateFormatter()
    @Published var schedules: [Schedule] = Schedule.dummySchedule
    @Published var date = Date()
    
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
    
    func calculateSchedulesLayers() -> [(Schedule, Int)] {
        var layers: [(Schedule, Int)] = []
        
        for schedule in schedules { // 전체 스케쥴 -> 하나식 확인
            let startDate = schedule.startDate
            let doDate = schedule.doDate
            
            var layer = Array(repeating: 0, count: schedules.count) // 이미 데이터가 있는 층을 확인하기 위한 더미 layer만들고
            
            for (existingSchedule, existingLayer) in layers { // 이미 확인한 스케쥴
                let existingStartDate = existingSchedule.startDate
                let existingDoDate = existingSchedule.doDate
                
                if startDate <= existingDoDate && existingStartDate <= doDate {
                    layer[existingLayer - 1] = 1
                }
            }
            let currentLayer = layer.firstIndex(of: 0) ?? 0
            layers.append((schedule, currentLayer+1)) // 하나의 루프가 끝날때마다 하나의 스케쥴이 layer에 들어가요
        }

        return layers
    }
    
    func schedules(monthStruct: Month, year: Int, month: Int, scheduler: [(Schedule, Int)]) -> [(Schedule, Int)] {
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
            let date3WithoutTime = calendar.startOfDay(for: schedule.doDate)

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
}
