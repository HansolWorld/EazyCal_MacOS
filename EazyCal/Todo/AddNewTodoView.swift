//
//  AddNewTodoView.swift
//  EazyCal
//
//  Created by apple on 10/24/23.
//

import SwiftUI

struct AddNewTodoView: View {
    @Binding var title: String
    @Binding var highlight: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            TextField("새로운 할 일", text: $title)
                .font(CustomTextStyle.caption.font)
                .foregroundStyle(.gray300)
            Divider()
            Toggle(isOn: $highlight) {
                Text("중요표시")
                    .font(CustomTextStyle.caption.font)
                    .foregroundStyle(.gray400)
            }
        }
        .padding()
        .background {
            Color.white
                .scaleEffect(1.5)
        }
    }
}

#Preview {
    AddNewTodoView(title: .constant("test"), highlight: .constant(true))
}
