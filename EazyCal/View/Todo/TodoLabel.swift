//
//  TodoLabel.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import SwiftUI
import EventKit

struct TodoLabel: View {
    var todo: EKReminder
    @State var isComplete = false
    @State var editTodo: String
    @FocusState var isFocus: Bool
    @EnvironmentObject var eventManager: EventStoreManager
    
    var body: some View {
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
                    .onChange(of: editTodo, { oldValue, newValue in
                        todo.title = newValue
                        Task {
                            try await eventManager.updateReminder(reminder: todo)
                        }
                    })
                
                Spacer()
                Text(caclulatorDay())
                    .font(.caption)
                    .foregroundStyle(.gray300)
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
        let components = calendar.dateComponents([.day], from: Date(), to: date)
        guard let daysDifference = components.day else { return ""}
        
        if daysDifference < 0 {
            return "\(abs(daysDifference))일 지남"
        } else if daysDifference == 0 {
            return "오늘"
        } else {
            return "\(daysDifference)일 전"
        }
    }
}

#Preview {
    TodoLabel(todo: EKReminder(), editTodo: "")
}
