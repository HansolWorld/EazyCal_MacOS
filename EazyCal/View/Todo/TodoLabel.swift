//
//  TodoLabel.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import SwiftUI
import EventKit

struct TodoLabel: View {
    let highlights = [String(localized: "IMPORTANCE_DEFAULT"), String(localized: "LOW"), String(localized: "MID"), String(localized: "HIGH")]
    
    @State var isComplete = false
    @State var editTodo: String
    @State private var newDate = Date()
    @State var newPriority: String
    @State private var isDateSelectedShow = false
    @State private var isPriorytySelectedShow = false
    @State private var lastButtonPressTime: Date?
    @Binding var todo: EKReminder
    @Binding var selectedId: String
    @FocusState var isFocus: Bool
    @EnvironmentObject var eventManager: EventStoreManager
    
    var body: some View {
        VStack {
            HStack(spacing: 8) {
                Button(action: {
                    withAnimation {
                        isComplete.toggle()
                        lastButtonPressTime = Date()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            if isComplete, let lastPressTime = lastButtonPressTime, Date().timeIntervalSince(lastPressTime) >= 1.5 {
                                Task {
                                    try await eventManager.completeReminder(reminder: todo)
                                }
                            }
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: checkToImageName())
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                            .foregroundStyle(.gray300)
                    }
                    .contentShape(Rectangle())
                    
                }
                .buttonStyle(.plain)
                
                HStack(spacing: 4) {
                    if todo.priority >= 6 && todo.priority <= 9  {
                        Text("!")
                            .font(.body)
                            .foregroundStyle(.red)
                    } else if todo.priority == 5 {
                        Text("!!")
                            .font(.body)
                            .foregroundStyle(.red)
                    } else if todo.priority >= 1 && todo.priority <= 4 {
                        Text("!!!")
                            .font(.body)
                            .foregroundStyle(.red)
                    }
                    TextField(String(localized: "REMINDER_EDIT"), text: $editTodo)
                        .font(.body)
                        .foregroundStyle(.black)
                        .strikethrough(todo.isCompleted)
                        .textFieldStyle(.plain)
                        .focused($isFocus)
                        .onChange(of: editTodo) { oldValue, newValue in
                            todo.title = newValue
                            Task {
                                try await eventManager.updateReminder(reminder: todo)
                            }
                        }
                        .onChange(of: isFocus) { oldValue, newValue in
                            withAnimation {
                                if newValue {
                                    selectedId = todo.calendarItemIdentifier
                                }
                            }
                        }
                    
                    Spacer()
                    Text(caclulatorDay())
                        .font(.caption)
                        .foregroundStyle(.gray300)
                }
            }
            .onAppear {
                if let date = todo.dueDateComponents?.date {
                    newDate = date
                }
            }
            
            
            if selectedId == todo.calendarItemIdentifier {
                HStack {
                    HStack(spacing: 8) {
                        Button(action: {
                            isDateSelectedShow = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                if todo.dueDateComponents?.date != nil {
                                    Text(newDate, style: .date)
                                } else {
                                    Text(String(localized: "DATE_ADD"))
                                }
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
                        .popover(isPresented: $isDateSelectedShow) {
                            HStack {
                                Text(String(localized: "DATE"))
                                    .foregroundStyle(Color.calendarBlack)
                                    .font(.body)
                                DatePicker("", selection: $newDate)
                                    .font(.body)
                                    .labelsHidden()
                                    .foregroundStyle(Color.gray400)
                                    .onChange(of: newDate) { _, newValue in
                                        todo.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: newDate)
                                        
                                        Task {
                                            try await eventManager.updateReminder(reminder: todo)
                                        }
                                    }
                            }
                            .padding(.horizontal, 8)
                            .background {
                                Color.white
                                    .scaleEffect(1.5)
                            }
                        }
                        
                        Button(action: {
                            isPriorytySelectedShow = true
                        }) {
                            HStack(spacing: 4) {
                                if newPriority == String(localized: "LOW") {
                                    Text("!")
                                } else if newPriority == String(localized: "MID") {
                                    Text("!!")
                                } else if newPriority == String(localized: "HIGH") {
                                    Text("!!!")
                                } else {
                                    Text("-")
                                }
                                
                                if newPriority != String(localized: "IMPORTANCE_DEFAULT") {
                                    Text(newPriority)
                                } else {
                                    Text(String(localized: "IMPORTANCE_DEFAULT"))
                                }
                                
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
                        .popover(isPresented: $isPriorytySelectedShow) {
                            VStack(spacing: 4) {
                                ForEach(highlights, id: \.self) { text in
                                    Button(action: {
                                        newPriority = text
                                        isPriorytySelectedShow = false
                                    }) {
                                        Text(text)
                                            .font(.body)
                                            .foregroundStyle(newPriority == text ? .white : .gray400)
                                            .padding(4)
                                            .background {
                                                if newPriority == text {
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
                        .onChange(of: newPriority) { _, newValue in
                            switch newValue {
                            case String(localized: "LOW"):
                                todo.priority = 9
                            case String(localized: "MID"):
                                todo.priority = 5
                            case String(localized: "HIGH"):
                                todo.priority = 1
                            default:
                                todo.priority = 0
                            }
                            
                            Task {
                                try await eventManager.updateReminder(reminder: todo)
                            }

                        }
                    }
                }
            }
        }
    }
    
    func checkToImageName() -> String {
        switch isComplete {
        case true:
            return SFSymbol.checkCircle.name
        case false:
            return SFSymbol.circle.name
        }
    }

    func caclulatorDay() -> String{
        guard let date = todo.dueDateComponents?.date else { return " " }
        
        let calendar = Calendar.current
        
        let todayComponents = calendar.dateComponents([.calendar, .era, .year, .month, .day, .hour], from: Date())
        let components = calendar.dateComponents([.day, .hour], from: todayComponents.date!, to: date)
        
        guard let daysDifference = components.day else { return "" }
        guard let hourDifference = components.hour else { return "" }
        
        if daysDifference < 0 {
            return String(localized: "\(abs(daysDifference)) PAST_DATE")
        } else if daysDifference == 0 {
            if hourDifference > 0 {
                return String(localized: "\(hourDifference) BEFORE_TIME")
            } else {
                return String(localized: "\(abs(hourDifference)) PAST_TIME")
            }
        } else {
            return String(localized: "\(daysDifference) BEFORE_DATE")
        }
    }
}

#Preview {
    TodoLabel(editTodo: "", newPriority: "기본", todo: .constant(EKReminder()), selectedId: .constant(""))
}
