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
            return "없음"
        case .everyDay:
            return "매일"
        case .everyWeek:
            return "매주"
        case .everyMonth:
            return "매달"
        case .everyYear:
            return "매년"
            
        }
    }
}
