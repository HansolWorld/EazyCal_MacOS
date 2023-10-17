//
//  TodoViewModel.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import Foundation

class TodoViewModel: ObservableObject {
    @Published var todos: [Todo] = Todo.dummyTodos
}
