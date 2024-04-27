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
    case Todo
    case Upcomming
    
    var title: String {
        switch self {
        case .calendar:
            return String(localized: "TAB_TITLE_CALENDAR")
        case .template:
            return String(localized: "TAB_TITLE_TEMPLATE")
        case .readyTodo:
            return String(localized: "TAB_TITLE_READY_REMINDER")
        case .Todo:
            return String(localized: "TAB_TITLE_REMINDER")
        case .Upcomming:
            return String(localized: "TAB_TITLE_UPCOMMING_EVENT")
        }
    }
}
