//
//  CalendarCategory.swift
//  EazyCal
//
//  Created by apple on 11/13/23.
//

import Foundation
import SwiftData

@Model
class CalendarCategory {
    @Attribute(.unique) var id: UUID
    var date: Date
    var icon: String
    var title: String
    var isSelected: Bool?
    var calendars: [String]
    
    init(id: UUID = UUID(), icon: String, title: String, isSelected: Bool? = false, calendars: [String] = []) {
        self.id = id
        self.date = Date()
        self.icon = icon
        self.title = title
        self.isSelected = isSelected
        self.calendars = calendars
    }
}
