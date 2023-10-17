//
//  Todo.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import Foundation

class Todo: ObservableObject {
    let id: UUID
    @Published var name: String
    @Published var date: Date
    @Published var isCheck: Bool
    @Published var importance: Importance
    
    init(name: String, date: Date, isCheck: Bool, importance: Importance) {
        self.id = UUID()
        self.name = name
        self.date = date
        self.isCheck = isCheck
        self.importance = importance
    }
}


extension Todo: Identifiable, Hashable {
    public func hash(into hasher: inout Hasher) {
        return hasher.combine(id)
    }
    
    public static func == (lhs: Todo, rhs: Todo) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Todo {
    static let dummyTodo = Todo(name: "Test Flight 업로드", date: toDate(textDate: "2023-10-14"), isCheck: false, importance: .high)
    static let dummyTodos = [
        Todo(name: "Test Flight 업로드", date: toDate(textDate: "2023-10-14"), isCheck: false, importance: .high),
        Todo(name: "중간점검", date: toDate(textDate: "2023-10-19"), isCheck: false, importance: .nomal),
        Todo(name: "딸기 밀크 쉐이크", date: toDate(textDate: "2023-10-21"), isCheck: false, importance: .middle),
        Todo(name: "베이컨 토마토 디럭스", date: toDate(textDate: "2023-10-24"), isCheck: false, importance: .nomal),
        Todo(name: "상하이 치킨 스낵랩", date: toDate(textDate: "2023-10-15"), isCheck: true, importance: .nomal)
    ]
    
    static func toDate(textDate: String) -> Date { //"yyyy-MM-dd HH:mm:ss"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        if let date = dateFormatter.date(from: textDate) {
            return date
        } else {
            return Date()
        }
    }
}



