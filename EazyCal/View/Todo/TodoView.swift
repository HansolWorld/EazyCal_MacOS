//
//  TodoView.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import SwiftUI

struct TodoView: View {
    
    let highlights = ["기본", "낮음", "중간", "높음"]
    @State private var selectedId = ""
    @State var newTodo = ""
    @State var highlight = "기본"
    @State var isHighlightShow = false
    @State var date = Date()
    @State var isDate = false
    @State var isDateShow = false
    @EnvironmentObject var eventManager: EventStoreManager
    @EnvironmentObject var calendarViewModel: CalendarViewModel

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 15) {
                HStack {
                    Text(IndexCategory.readyTodo.title)
                        .font(.headline)
                        .foregroundStyle(.gray300)
                    Spacer()
                }
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(eventManager.upcommingEvent, id: \.eventIdentifier) { schedule in
                            if let notes = schedule.notes, notes.contains("☐") {
                                ScheduleTodoCellView(schedule: schedule)
                                    .environmentObject(eventManager)
                            }
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            VStack(spacing: 15) {
                HStack {
                    Text(IndexCategory.Todo.title)
                        .font(.headline)
                        .foregroundStyle(.gray300)
                    Spacer()
                }
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach($eventManager.todo, id:\.calendarItemIdentifier) { $todo in
                            
                            let priority: String = {
                                var newPriority = "기본"
                                if todo.priority >= 6 && todo.priority <= 9  {
                                    newPriority = "낮음"
                                } else if todo.priority == 5 {
                                    newPriority = "중간"
                                } else if todo.priority >= 1 && todo.priority <= 4 {
                                    newPriority = "높음"
                                }
                                
                                return newPriority
                            }()
                            
                            TodoLabel(editTodo: todo.title, newPriority: priority, todo: $todo, selectedId: $selectedId)
                                .environmentObject(eventManager)
                        }
                        
                        VStack {
                            HStack {
                                Image(systemName: SFSymbol.circle.name)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 12, height: 12)
                                    .foregroundStyle(.gray300)
                                
                                TextField("새로운 할일", text: $newTodo)
                                    .font(.body)
                                    .foregroundStyle(Color.gray400)
                                    .textFieldStyle(.plain)
                                    .onSubmit {
                                        if newTodo != "" {
                                            Task {
                                                await eventManager.createNewReminder(title: newTodo, date: isDate ? date : nil, highlight: highlight)
                                                
                                                newTodo = ""
                                                highlight = "기본"
                                                isDate = false
                                            }
                                        }
                                    }
                            }
                            
                            HStack(spacing: 8) {
                                Button(action: {
                                    isDate.toggle()
                                    if isDate == true {
                                        isDateShow = true
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "calendar")
                                        Text(isDate ? "날짜 삭제" : "날짜 추가")
                                    }
                                    .font(.subheadline)
                                    .foregroundStyle(.gray400)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.gray400)
                                            .opacity(0.1)
                                    }
                                }
                                .buttonStyle(.plain)
                                .popover(isPresented: $isDateShow) {
                                    HStack {
                                        Text("날짜")
                                            .foregroundStyle(Color.calendarBlack)
                                            .font(.body)
                                        DatePicker("", selection: $date)
                                            .font(.body)
                                            .labelsHidden()
                                            .foregroundStyle(Color.gray400)
                                    }
                                    .padding(.horizontal, 8)
                                    .background {
                                        Color.white
                                            .scaleEffect(1.5)
                                    }
                                }
                                
                                Button(action: {
                                    isHighlightShow = true
                                }) {
                                    HStack(spacing: 4) {
                                        Text("!")
                                        Text("우선순위")
                                    }
                                    .font(.subheadline)
                                    .foregroundStyle(.gray400)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.gray400)
                                            .opacity(0.1)
                                    }
                                }
                                .buttonStyle(.plain)
                                .popover(isPresented: $isHighlightShow) {
                                    VStack(spacing: 4) {
                                        ForEach(highlights, id: \.self) { text in
                                            Button(action: {
                                                highlight = text
                                            }) {
                                                Text(text)
                                                    .font(.body)
                                                    .foregroundStyle(highlight == text ? .white : .gray400)
                                                    .padding(4)
                                                    .background {
                                                        if highlight == text {
                                                            RoundedRectangle(cornerRadius: 6)
                                                                .fill(Color.primaryBlue)
                                                        } else {
                                                            RoundedRectangle(cornerRadius: 6)
                                                                .fill(Color.clear)
                                                        }
                                                    }
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(4)
                                    .background {
                                        Color.white
                                            .scaleEffect(1.5)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background{
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.background)
                    }
                }
            }
        }
        .padding()
    }
}

#Preview {
    TodoView()
        .environmentObject(EventStoreManager())
        .environmentObject(CalendarViewModel())
}

