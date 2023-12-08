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
            return "캘린더"
        case .template:
            return "간편 일정 추가"
        case .readyTodo:
            return "준비할 일"
        case .Todo:
            return "할 일"
        case .Upcomming:
            return "다가오는 일정"
        }
    }
}
