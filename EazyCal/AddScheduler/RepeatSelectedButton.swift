//
//  RepeatSelectedButton.swift
//  EazyCal
//
//  Created by apple on 10/18/23.
//

import SwiftUI


struct RepeatSelectedButton: View {
    let title: String
    @Binding var selected: RepeatType
    
    var body: some View {
        HStack {
            Text(title)
                .customStyle(.caption)
                .foregroundStyle(Color.black)
            Spacer()
            HStack {
                ForEach(RepeatType.allCases, id: \.self) { buttonCase in
                    Button(action: {
                        self.selected = buttonCase
                    }) {
                        Text(buttonCase.title)
                            .customStyle(.caption)
                            .fontWeight(self.selected == buttonCase ? .bold : .regular)
                            .foregroundStyle(self.selected == buttonCase ? .gray400 : .gray300)
                    }
                    if buttonCase != RepeatType.allCases.last {
                        Divider()
                            .background(Color.gray200)
                            .frame(height: 10)
                    }
                }
            }
            .padding(4)
            .background {
                Color.background
                    .cornerRadius(4)
            }
        }
    }
}

#Preview {
    RepeatSelectedButton(title: "반복", selected: .constant(RepeatType.check))
}
