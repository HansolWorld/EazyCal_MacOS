//
//  Template.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import EventKit

class Template: ObservableObject {
    let id: UUID
    @Published var name: String
    @Published var icon: String
    @Published var category: EKCalendar
    
    init(name: String, icon: String, category: EKCalendar) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.category = category
    }
}


extension Template: Identifiable, Hashable {
    public func hash(into hasher: inout Hasher) {
        return hasher.combine(id)
    }
    
    public static func == (lhs: Template, rhs: Template) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Template {
    static let eventStore = EKEventStore()
    static let dummyTemplates: [Template] = []
}
