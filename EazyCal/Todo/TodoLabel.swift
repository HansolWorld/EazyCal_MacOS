//
//  TodoLabel.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import SwiftUI

struct TodoLabel: View {
    @ObservedObject var todo: Todo
    
    var body: some View {
        HStack(spacing: 8) {
            Button(action: {
                todo.isCheck.toggle()
            }) {
                Image(systemName: checkToImageName())
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
            }
            Text(todo.name)
                .customStyle(.body)
                .foregroundStyle(todo.isCheck ? .gray : .black)
                .strikethrough(todo.isCheck)
                .background {
                    switch todo.importance {
                    case .nomal:
                        Color.clear
                    case .middle:
                        Color.yellow
                            .opacity(0.2)
                    case .high:
                        Color.highlight
                            .opacity(0.5)
                    }
                }
            Spacer()
            Text(todo.date, style: .offset)
                .customStyle(.caption)
                .foregroundStyle(.gray)
        }
        .tint(.black)
    }
    
    func checkToImageName() -> String {
        switch todo.isCheck {
        case true:
            return SFSymbol.checkCircle.name
        case false:
            return SFSymbol.circle.name
        }
    }

//    func caclulatorDay() -> String{
//        let calendar = Calendar.current
//        let components = calendar.dateComponents([.day], from: Date(), to: todo.date)
//        guard let daysDifference = components.day else { return ""}
//        
//        if daysDifference < 0 {
//            return "\(abs(daysDifference))일 지남"
//        } else if daysDifference == 0 {
//            return "오늘"
//        } else {
//            return "\(daysDifference)일 전"
//        }
//    }
}

#Preview {
    TodoLabel(
        todo: Todo.dummyTodo
    )
}
