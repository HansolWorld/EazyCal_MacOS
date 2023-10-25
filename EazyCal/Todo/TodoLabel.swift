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
    
    var body: some View {
        HStack(spacing: 8) {
            Button(action: {
                todo.isCompleted.toggle()
            }) {
                Image(systemName: checkToImageName())
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
            }

            Text(todo.title)
                .customStyle(.body)
                .foregroundStyle(todo.isCompleted ? .gray : .black)
                .strikethrough(todo.isCompleted)
                .background {
                    if let note = todo.notes {
                        if note.contains("강조") {
                            Color.highlight
                                .opacity(0.5)
                        }
                    }
                }
            Spacer()
            Text(caclulatorDay())
                .customStyle(.caption)
                .foregroundStyle(.gray)
        }
        .tint(.black)
    }
    
    func checkToImageName() -> String {
        switch todo.isCompleted {
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
    TodoLabel(todo: EKReminder())
}
