//
//  RepeatType.swift
//  EazyCal
//
//  Created by apple on 10/23/23.
//

import Foundation


enum RepeatType: CaseIterable {
    case oneDay
    case everyDay
    case everyWeek
    case everyMonth
    case everyYear
    
    var title: String {
        switch self {
        case .oneDay:
            return String(localized: "REPEAT_NOT")
        case .everyDay:
            return String(localized: "REPEAT_DAILY")
        case .everyWeek:
            return String(localized: "REPEAT_WEAKLY")
        case .everyMonth:
            return String(localized: "REPEAT_MONTHLY")
        case .everyYear:
            return String(localized: "REPEAT_YEARLY")
            
        }
    }
}
