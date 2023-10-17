//
//  Month.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import Foundation

struct Month {
    var monthType: MonthType
    var dayInt : Int
}

enum MonthType {
    case Previous
    case Current
    case Next
}
