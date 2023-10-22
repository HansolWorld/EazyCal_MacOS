//
//  Schedule.swift
//  EazyCal
//
//  Created by apple on 10/17/23.
//

import Foundation

struct Schedule: Hashable {
    let title: String
    let startDate: Date
    let doDate: Date
    let oneDay: Bool
    let repeatType: RepeatType
    let category: CalendarCategory
    let todos: [Todo]
}


extension Schedule {
    static let dummySchedule = [
        Schedule(title: "집가기", startDate: toDate("2023-10-01"), doDate: toDate("2023-10-01"), oneDay: true, repeatType: .everyDay, category: CalendarCategory.dummyCategory(to: 2), todos: []),
        Schedule(title: "산 휴가", startDate: toDate("2023-10-09"), doDate: toDate("2023-10-10"), oneDay: true, repeatType: .everyYear, category: CalendarCategory.dummyCategory(to: 3), todos: Todo.dummyTodos),
        Schedule(title: "신디 휴가", startDate: toDate("2023-10-10"), doDate: toDate("2023-10-12"), oneDay: true, repeatType: .everyYear, category: CalendarCategory.dummyCategory(to: 3), todos: Todo.dummyTodos),
        Schedule(title: "신디 휴가", startDate: toDate("2023-10-10"), doDate: toDate("2023-10-13"), oneDay: true, repeatType: .everyYear, category: CalendarCategory.dummyCategory(to: 3), todos: Todo.dummyTodos),
        Schedule(title: "팀회의", startDate: toDate("2023-10-12"), doDate: toDate("2023-10-15"), oneDay: false, repeatType: .everyMonth, category: CalendarCategory.dummyCategory(to: 1), todos: []),
        Schedule(title: "테스트회의", startDate: toDate("2023-10-12"), doDate: toDate("2023-10-15"), oneDay: false, repeatType: .everyMonth, category: CalendarCategory.dummyCategory(to: 1), todos: []),
        Schedule(title: "책읽기", startDate: toDate("2023-10-15"), doDate: toDate("2023-10-16"), oneDay: true, repeatType: .everyDay, category: CalendarCategory.dummyCategory(to: 0), todos: []),
        Schedule(title: "내부 쇼케이스", startDate: Date(), doDate: Date(), oneDay: false, repeatType: .everyDay, category: CalendarCategory.dummyCategory(to: 0), todos: Todo.dummyTodos),
        Schedule(title: "팀회식", startDate: Date(), doDate: Date(), oneDay: true, repeatType: .everyWeek, category: CalendarCategory.dummyCategory(to: 2), todos: []),
        Schedule(title: "내부쇼케이스", startDate: Date(), doDate: Date(), oneDay: false, repeatType: .everyMonth, category: CalendarCategory.dummyCategory(to: 3), todos: [])
    ]
    
    static func toDate(_ textDate: String) -> Date { //"yyyy-MM-dd HH:mm:ss"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        if let date = dateFormatter.date(from: textDate) {
            return date
        } else {
            return Date()
        }
    }
}
