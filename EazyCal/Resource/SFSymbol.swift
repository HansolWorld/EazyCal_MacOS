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
    case circle
    case checkCircle
    case circlePlus
    case circleMinus
    case chevronRight
    case chevronBackward
    case chevronForward
    
    var name: String {
        switch self {
        case .poweron:
            return "poweron"
        case .square:
            return "square"
        case .check:
            return "checkmark.square.fill"
        case .circle:
            return "circle"
        case .checkCircle:
            return "circle.inset.filled"
        case .circlePlus:
            return "plus.circle.fill"
        case .circleMinus:
            return "minus.circle.fill"
        case .chevronRight:
            return "chevron.right"
        case .chevronBackward:
            return "chevron.backward.circle.fill"
        case .chevronForward:
            return "chevron.forward.circle.fill"
        }
    }
}
