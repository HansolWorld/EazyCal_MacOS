//
//  TodoView.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import SwiftUI

struct TodoView: View {
    let mode: IndexCategory
    @State var isShow = false
    @State var newTodo = ""
    @State var highlight = false
    @ObservedObject var calendarViewModel: CalendarViewModel
    @EnvironmentObject var eventStore: EventStore

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text(mode.title)
                    .customStyle(.subtitle)
                    .foregroundStyle(.gray)
                Spacer()
                Button(action: {
                    isShow = true
                }) {
                    Image(systemName: SFSymbol.circlePlus.name)
                        .tint(Color.background)
                        .background{
                            Circle()
                                .foregroundStyle(Color.gray300)
                                .scaleEffect(0.8)
                        }
                        .popover(isPresented: $isShow) {
                            AddNewTodoView(title: $newTodo, highlight: $highlight)
                        }
                        .onChange(of: isShow) {
                            if isShow == false, newTodo != "" {
                                Task {
                                    await eventStore.createNewReminder(title: newTodo, date: nil, highlight: highlight)
                                    await calendarViewModel.todos(eventStore: eventStore)
                                    newTodo = ""
                                    highlight = false
                                }
                            }
                        }
                }
            }
            ScrollView {
                ForEach(calendarViewModel.filterSchedule(), id: \.eventIdentifier) { schedule in
                    ScheduleTodoCellView(schedule: schedule, calendarViewModel: calendarViewModel)
                }
                ForEach(calendarViewModel.todo, id:\.calendarItemIdentifier) { todo in
                    TodoLabel(todo: todo)
                }
            }
        }
        .padding(.horizontal)
        .task {
            await calendarViewModel.loadAllSchedule(eventStore: eventStore)
            await calendarViewModel.todos(eventStore: eventStore)
        }
    }
}

#Preview {
    TodoView(mode: IndexCategory.Todo, calendarViewModel: CalendarViewModel())
}
