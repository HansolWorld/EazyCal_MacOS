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
    case futureTodo
    case Todo
    
    var title: String {
        switch self {
        case .calendar:
            return "캘린더"
        case .template:
            return "템플릿"
        case .futureTodo:
            return "예정된 일"
        case .Todo:
            return "할 일"
        }
    }
}
