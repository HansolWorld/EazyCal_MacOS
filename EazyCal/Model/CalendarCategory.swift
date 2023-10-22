//
//  CalendarCategory.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import Foundation

class CalendarCategory: ObservableObject {
    let id: UUID
    @Published var name: String
    @Published var color: String
    @Published var isCheck: Bool
    
    init(name: String, color: String, isCheck: Bool) {
        self.id = UUID()
        self.name = name
        self.color = color
        self.isCheck = isCheck
    }
}


extension CalendarCategory: Identifiable, Hashable {
    public func hash(into hasher: inout Hasher) {
        return hasher.combine(id)
    }
    
    public static func == (lhs: CalendarCategory, rhs: CalendarCategory) -> Bool {
        return lhs.id == rhs.id
    }
}

extension CalendarCategory {
    static func dummyCategory(to index: Int) -> CalendarCategory {
        return dummyCategories[index]
    }
    
    static let dummyCategories = [
        CalendarCategory(name: "기본 캘린더", color: "Blue", isCheck: true),
        CalendarCategory(name: "사이드 프로젝트", color: "Puple", isCheck: true),
        CalendarCategory(name: "개인 공부", color: "Orange", isCheck: true),
        CalendarCategory(name: "집안일", color: "Pink", isCheck: false)
    ]
}
