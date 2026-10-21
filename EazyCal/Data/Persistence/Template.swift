//
//  Template.swift
//  EazyCal
//
//  Created by apple on 11/13/23.
//

import Foundation
import SwiftData
import EventKit

@Model
class Template {
    @Attribute(.unique) var id: UUID
    var date: Date
    var title: String
    var isAllDay: Bool
    var startTime: Date
    var endTime: Date
    var todos: [String]
    var calendarId: String
    
    init(id: UUID = UUID(), title: String, isAllDay: Bool = false, startTime: Date, endTime: Date, todos: [String], calendarId: String) {
        self.id = id
        self.date = Date()
        self.title = title
        self.isAllDay = isAllDay
        self.startTime = startTime
        self.endTime = endTime
        self.todos = todos
        self.calendarId = calendarId
    }
}
