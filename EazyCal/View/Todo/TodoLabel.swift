//
//  TodoLabel.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import SwiftUI
import EventKit

struct TodoLabel: View {
    let highlights = ["기본", "낮음", "중간", "높음"]
    
    @State var isComplete = false
    @State var editTodo: String
    @State private var newDate = Date()
    @State var newPriority: String
    @State private var isDateSelectedShow = false
    @State private var isPriorytySelectedShow = false
    @Binding var todo: EKReminder
    @Binding var selectedId: String
    @FocusState var isFocus: Bool
    @EnvironmentObject var eventManager: EventStoreManager
    
    var body: some View {
        VStack {
            HStack(spacing: 8) {
                Button(action: {
                    isComplete = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        Task {
                            try await eventManager.completeReminder(reminder: todo)
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
                    TextField("할일 변경", text: $editTodo)
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
                                    Text("날짜 추가")
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
                                Text("날짜")
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
                                if newPriority == "낮음" {
                                    Text("!")
                                } else if newPriority == "중간" {
                                    Text("!!")
                                } else if newPriority == "높음" {
                                    Text("!!!")
                                } else {
                                    Text("-")
                                }
                                
                                if newPriority != "기본" {
                                    Text(newPriority)
                                } else {
                                    Text("기본")
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
                            case "낮음":
                                todo.priority = 9
                            case "중간":
                                todo.priority = 5
                            case "높음":
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

        let components = calendar.dateComponents([.day, .hour], from: Date(), to: date)
        guard let daysDifference = components.day else { return "" }
        guard let hourDifference = components.hour else { return "" }
        
        if daysDifference < 0 {
            return "\(abs(daysDifference))일 지남"
        } else if daysDifference == 0 {
            if hourDifference > 0 {
                return "\(hourDifference)시간 전"
            } else {
                return "\(abs(hourDifference))시간 지남"
            }
        } else {
            return "\(daysDifference)일 전"
        }
    }
}

#Preview {
    TodoLabel(editTodo: "", newPriority: "기본", todo: .constant(EKReminder()), selectedId: .constant(""))
}
