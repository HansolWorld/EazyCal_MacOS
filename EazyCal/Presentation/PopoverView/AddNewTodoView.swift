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
            TextField(String(localized: "NEW_REMINDER"), text: $title)
                .font(.caption)
                .foregroundStyle(Color.gray400)
                .textFieldStyle(.plain)
            Divider()
            Toggle(isOn: $highlight) {
                Text(String(localized: "IMPORTANCE"))
                    .font(.caption)
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
