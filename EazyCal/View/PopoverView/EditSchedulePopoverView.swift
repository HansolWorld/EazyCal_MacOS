//
//  EditSchedulePopoverView.swift
//  EazyCal
//
//  Created by apple on 11/22/23.
//

import SwiftUI
import EventKit

class Todo: ObservableObject {
    @Published var isComplete: Bool
    @Published var title: String
    
    init(isComplete: Bool = false, title: String) {
        self.isComplete = isComplete
        self.title = title
    }
}

struct EditSchedulePopoverView: View {
    let event: EKEvent
    @State var editTitle: String
    @State var editIsAllDay: Bool
    @State var editStartDate: Date
    @State var editDoDate: Date
    @State var editRepeatDate: RepeatType
    @State var editTodo = Todo(title: "")
    @State var editTodos: [Todo]
    @State var editCategory: EKCalendar
    @EnvironmentObject var eventManager: EventStoreManager
    
    var body: some View {
        VStack(alignment: .leading) {
            TextField("일정 수정", text: $editTitle)
                .font(.title3)
                .foregroundStyle(Color.gray400)
                .textFieldStyle(.plain)
            HStack {
                Text("종일")
                    .font(.body)
                    .foregroundStyle(Color.gray400)
                Spacer()
                Toggle("", isOn: $editIsAllDay)
                    .foregroundStyle(Color.gray200)
                    .toggleStyle(BackgroundToggleStyle())
                    .labelsHidden()
            }
            if !editIsAllDay {
                VStack {
                    HStack {
                        Text("시작")
                            .font(.body)
                            .foregroundStyle(Color.gray400)
                        Spacer()
                        DatePicker("", selection: $editStartDate, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                            .foregroundStyle(Color.calendarBlack)
                    }
                    HStack {
                        Text("종료")
                            .font(.body)
                            .foregroundStyle(Color.gray400)
                        Spacer()
                        DatePicker("", selection: $editDoDate, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                            .foregroundStyle(Color.calendarBlack)
                    }
                }
            }
            RepeatSelectedButton(title: "반복", selected: $editRepeatDate)
            CustomPicker(title: "카테고리", categoryList: eventManager.calendars, selected: $editCategory)
            Text("할 일")
                .font(.body)
                .foregroundStyle(Color.gray400)
            
            ForEach(editTodos.indices, id:\.self) { index in
                HStack {
                    Image(systemName: SFSymbol.circle.name)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                        .foregroundStyle(Color.calendarBlue)
                    TextField("", text: $editTodos[index].title)
                        .foregroundStyle(Color.gray400)
                        .textFieldStyle(.plain)
                }
            }
            HStack {
                Image(systemName: SFSymbol.circle.name)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                    .foregroundStyle(Color.calendarBlue)
                TextField("새로운 할일", text: $editTodo.title)
                    .foregroundStyle(Color.gray400)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        editTodos.append(editTodo)
                        editTodo = Todo(title: "")
                    }
            }
        }
        .padding()
        .onDisappear {
            event.title = editTitle
            event.isAllDay = editIsAllDay
            event.startDate = editStartDate
            event.endDate = editDoDate
            switch editRepeatDate {
            case .oneDay:
                event.recurrenceRules = nil
            case .everyDay:
                event.recurrenceRules = [EKRecurrenceRule(recurrenceWith: .daily, interval: 1, end: EKRecurrenceEnd(end: Date().addingTimeInterval(60 * 60 * 24 * 7 * 8)))]
            case .everyWeek:
                event.recurrenceRules = [EKRecurrenceRule(recurrenceWith: .weekly, interval: 1, end: EKRecurrenceEnd(end: Date().addingTimeInterval(60 * 60 * 24 * 7 * 8)))]
            case .everyMonth:
                event.recurrenceRules = [EKRecurrenceRule(recurrenceWith: .monthly, interval: 1, end: EKRecurrenceEnd(end: Date().addingTimeInterval(60 * 60 * 24 * 7 * 8)))]
            case .everyYear:
                event.recurrenceRules = [EKRecurrenceRule(recurrenceWith: .yearly, interval: 1, end: EKRecurrenceEnd(end: Date().addingTimeInterval(60 * 60 * 24 * 7 * 8)))]
            }
            event.notes = todos(editTodos)
            event.calendar = editCategory
            Task {
                try await eventManager.updateEvent(ekEvent: event)
            }
        }
        .background {
            Color.white
                .scaleEffect(1.5)
        }
    }
    
    func todos(_ todos: [Todo]) -> String {
        var notes = event.notes?.split(separator: "\n") ?? []
        notes = notes.filter { !($0.contains("☑︎") || $0.contains("☐")) }
        
        for todo in todos {
            notes.append("\(todo.isComplete ? "☑︎" : "☐")\(todo.title)")
        }
        
        return notes.joined(separator: "\n")
    }
    
    
    func todo(to todo: String) -> String {
         return todo.replacingOccurrences(of: "☑︎", with: "").replacingOccurrences(of: "☐", with: "")
    }
}
