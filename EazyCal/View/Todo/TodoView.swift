//
//  TodoView.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import SwiftUI

struct TodoView: View {
    
    let highlights = [String(localized: "IMPORTANCE_DEFAULT"), String(localized: "LOW"), String(localized: "MID"), String(localized: "HIGH")]
    @State private var selectedId = ""
    @State var newTodo = ""
    @State var highlight = String(localized: "IMPORTANCE_DEFAULT")
    @State var isHighlightShow = false
    @State var date = Date()
    @State var isDate = false
    @State var isDateShow = false
    @FocusState private var isFocusedNewTodo: Bool
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
                        ForEach($eventManager.upcommingEvent, id: \.eventIdentifier) { $schedule in
                            if let notes = schedule.notes, notes.contains("☐") {
                                ScheduleTodoCellView(schedule: $schedule)
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
                                var newPriority = String(localized: "IMPORTANCE_DEFAULT")
                                if todo.priority >= 6 && todo.priority <= 9  {
                                    newPriority = String(localized: "LOW")
                                } else if todo.priority == 5 {
                                    newPriority = String(localized: "MID")
                                } else if todo.priority >= 1 && todo.priority <= 4 {
                                    newPriority = String(localized: "HIGH")
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
                                
                                TextField(String(localized: "NEW_REMINDER"), text: $newTodo)
                                    .font(.body)
                                    .foregroundStyle(Color.gray400)
                                    .textFieldStyle(.plain)
                                    .onSubmit {
                                        if newTodo != "" {
                                            Task {
                                                do {
                                                    try await eventManager.createNewReminder(title: newTodo, date: isDate ? date : nil, highlight: highlight)
                                                } catch {
                                                    print(error)
                                                }
                                                
                                                newTodo = ""
                                                highlight = String(localized: "IMPORTANCE_DEFAULT")
                                                isDate = false
                                            }
                                        }
                                    }
                                    .focused($isFocusedNewTodo)
                                    .onChange(of: isFocusedNewTodo) { _, newValue in
                                        withAnimation {
                                            if newValue {
                                                selectedId = ""
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
                                        Text(isDate ? String(localized: "DATE_DELETE") : String(localized: "DATE_ADD"))
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
                                        Text(String(localized: "DATE"))
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
                                        Text(String(localized: "RANKING"))
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

