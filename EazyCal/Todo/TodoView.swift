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
                    .customStyle(.subtitle)
                    .foregroundStyle(.gray)
                Spacer()
                Button(action: {
                    
                }) {
                    Image(systemName: SFSymbol.circlePlus.name)
                        .tint(Color.background)
                        .background{
                            Circle()
                                .foregroundStyle(Color.gray300)
                                .scaleEffect(0.8)
                        }
                }
            }
            ScrollView {
                ForEach(todoViewModel.schedules.filter { $0.todos.count != 0 }, id: \.self) { schedule in
                    VStack {
                        HStack {
                            CalendarCategoryLabelView(title: schedule.title, color: schedule.category.color)
                                .foregroundStyle(Color(schedule.category.color))
                            Spacer()
                            Text(schedule.startDate, style: .date)
                                .customStyle(.caption)
                                .foregroundStyle(.gray300)
                        }
                        ForEach(schedule.todos, id: \.self) { todo in
                            TodoLabel(todo: todo)
                        }
                    }
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(schedule.category.color))
                            .opacity(0.1)
                    }
                }
                ForEach(todoViewModel.todos, id: \.self) { todo in
                        TodoLabel(todo: todo)
                }
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    TodoView(mode: IndexCategory.Todo)
}
