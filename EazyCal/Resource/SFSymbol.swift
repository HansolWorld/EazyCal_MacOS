//
//  SFSymbol.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import Foundation

enum SFSymbol {
    case square
    case check
    case circle
    case checkCircle
    
    var name: String {
        switch self {
        case .square:
            return "square"
        case .check:
            return "checkmark.square.fill"
        case .circle:
            return "circle"
        case .checkCircle:
            return "circle.inset.filled"
        }
    }
}
