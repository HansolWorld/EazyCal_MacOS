//
//  SFSymbol.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import Foundation

enum SFSymbol {
    case poweron
    case square
    case check
    case checkmark
    case circle
    case circleFill
    case checkCircle
    case plus
    case minus
    case chevronRight
    case chevronBackward
    case chevronForward
    case layer
    case folder
    case calendar
    
    var name: String {
        switch self {
        case .poweron:
            return "poweron"
        case .square:
            return "square"
        case .checkmark:
            return "checkmark"
        case .check:
            return "checkmark.square.fill"
        case .checkCircle:
            return "checkmark.circle.fill"
        case .circle:
            return "circle"
        case .circleFill:
            return "circle.fill"
        case .plus:
            return "plus"
        case .minus:
            return "minus"
        case .chevronRight:
            return "chevron.right"
        case .chevronBackward:
            return "chevron.backward"
        case .chevronForward:
            return "chevron.forward"
        case .layer:
            return "square.3.layers.3d.down.forward"
        case .folder:
            return "folder"
        case .calendar:
            return "calendar"
        }
    }
}
