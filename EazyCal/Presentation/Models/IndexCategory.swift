//
//  IndexCategory.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import Foundation

enum IndexCategory {
    case calendar
    case template
    case readyTodo
    case todo
    case upcoming
    
    var title: String {
        switch self {
        case .calendar:
            return String(localized: "TAB_TITLE_CALENDAR")
        case .template:
            return String(localized: "TAB_TITLE_TEMPLATE")
        case .readyTodo:
            return String(localized: "TAB_TITLE_READY_REMINDER")
        case .todo:
            return String(localized: "TAB_TITLE_REMINDER")
        case .upcoming:
            return String(localized: "TAB_TITLE_UPCOMMING_EVENT")
        }
    }
}
