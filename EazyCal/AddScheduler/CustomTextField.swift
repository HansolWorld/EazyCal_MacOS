//
//  CustomTextField.swift
//  EazyCal
//
//  Created by apple on 10/18/23.
//

import SwiftUI

struct CustomTextField: View {
    let title: String
    @State var todo: String = ""
    @Binding var todos: [String]
    
    var body: some View {
        VStack(alignment: .trailing) {
            HStack {
                Text(title)
                    .customStyle(.caption)
                    .foregroundStyle(Color.calendarBlack)
                Spacer()
                TextField("할 일을 입력하세요.", text: $todo)
                    .font(CustomTextStyle.caption.font)
                    .foregroundStyle(Color.calendarBlack)
                    .multilineTextAlignment(.trailing)
            }
            withAnimation() {
                HStack {
                    Button(action: {
                        if todo != "" {
                            todos.append(todo)
                            todo = ""
                        }
                    }) {
                        Image(systemName: SFSymbol.circlePlus.name)
                            .tint(Color.background)
                            .background{
                                Circle()
                                    .foregroundStyle(Color.gray300)
                                    .scaleEffect(0.8)
                            }
                    }
                    if todos.count != 0 {
                        Button(action: {
                            let _ = todos.popLast()
                        }) {
                            Image(systemName: SFSymbol.circleMinus.name)
                                .tint(Color.background)
                                .background{
                                    Circle()
                                        .foregroundStyle(Color.gray300)
                                        .scaleEffect(0.8)
                                }
                        }
                    }
                }
            }
            
            ForEach(todos, id: \.self) { todo in
                Text(todo)
                    .customStyle(.caption)
                    .foregroundStyle(Color.calendarBlack)
            }
        }
    }
}

#Preview {
    CustomTextField(title: "할일", todos: .constant([]))
}
