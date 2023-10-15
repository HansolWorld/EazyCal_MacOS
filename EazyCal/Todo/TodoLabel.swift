//
//  TodoLabel.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import SwiftUI

struct TodoLabel: View {
    let task: String
    let date: Date
    let importance: Importance
    @Binding var isCheck: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Button(action: {
                isCheck.toggle()
            }) {
                Image(systemName: checkToImageName())
            }
            Text(task)
                .font(.category)
            Spacer()
            Text(caclulatorDay())
                .font(.dday)
        }
        .tint(.black)
        .padding()
    }
    
    func checkToImageName() -> String {
        switch self.isCheck {
        case true:
            return SFSymbol.checkCircle.name
        case false:
            return SFSymbol.circle.name
        }
    }

    func caclulatorDay() -> String{
        let currentDay = Date()
        
        let dday = Int(Date().timeIntervalSince(date)/86400)
        
        if dday < 0 {
            return "\(dday)일 지남"
        } else if dday == 0 {
            return "오늘"
        } else {
            return "\(dday)일 전"
        }
    }
}

#Preview {
    TodoLabel(task: "중간점검", date: Date(), importance: .high, isCheck: .constant(true))
}
