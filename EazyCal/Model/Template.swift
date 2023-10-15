//
//  Template.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import Foundation

class Template: ObservableObject {
    let id: UUID
    @Published var name: String
    @Published var icon: String
    @Published var category: CalendarCategory
    
    init(name: String, icon: String, category: CalendarCategory) {
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
    static let dummyTemplates = [
        Template(
            name: "회의",
            icon: "💼",
            category: CalendarCategory(name: "사이드 프로젝트", color: "Puple", isCheck: true)),
        Template(
            name: "스터디",
            icon: "📝",
            category: CalendarCategory(name: "기본 캘린더", color: "Blue", isCheck: true)),
        Template(
            name: "운동",
            icon: "💪",
            category: CalendarCategory(name: "기본 캘린더", color: "Blue", isCheck: true)),
        Template(
            name: "청소",
            icon: "🏡",
            category: CalendarCategory(name: "집안일", color: "Pink", isCheck: false)),
        Template(
            name: "설거지",
            icon: "🧼",
            category: CalendarCategory(name: "집안일", color: "Pink", isCheck: false)),
        Template(
            name: "디자인시스템",
            icon: "⛏️",
            category: CalendarCategory(name: "개인 공부", color: "Orange", isCheck: true)),
    ]
}
