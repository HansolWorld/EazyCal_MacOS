//
//  CalendarColor+SwiftUI.swift
//  EazyCal
//

import SwiftUI

extension Color {
    init(calendarColor: CalendarColor) {
        self.init(
            red: calendarColor.red,
            green: calendarColor.green,
            blue: calendarColor.blue,
            opacity: calendarColor.alpha
        )
    }
}

extension CalendarColor {
    init(_ color: CGColor) {
        let components = color.components ?? []
        if components.count >= 4 {
            self.init(
                red: components[0],
                green: components[1],
                blue: components[2],
                alpha: components[3]
            )
        } else {
            let white = components.first ?? 0
            self.init(red: white, green: white, blue: white, alpha: components.last ?? 1)
        }
    }

    var cgColor: CGColor {
        CGColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}
