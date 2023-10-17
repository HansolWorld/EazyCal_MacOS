//
//  Schedule.swift
//  EazyCal
//
//  Created by apple on 10/17/23.
//

import Foundation

struct Schedule {
    enum RepeatType {
        case check
        case everyDay
        case everyWeek
        case everyMonth
        case everyYear
    }
    
    let startDate: Date
    let doDate: Date
    let oneDay: Bool
    let repeatType: RepeatType
    let category: CalendarCategory
}
