//
//  TodoView.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import SwiftUI

struct TodoView: View {
    let mode: IndexCategory
    @StateObject private var todoViewModel = TodoViewModel()

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text(mode.title)
                    .font(.semiTitle)
                Spacer()
                Button(action: {
                    
                }) {
                    Image(systemName: SFSymbol.circlePlus.name)
                }
            }
            .foregroundStyle(.gray)
            ScrollView {
                ForEach(todoViewModel.todos) { todo in
                    TodoLabel(todo: todo)
                }
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    TodoView(mode: IndexCategory.futureTodo)
}
