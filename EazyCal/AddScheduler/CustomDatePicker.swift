//
//  CustomDatePicker.swift
//  EazyCal
//
//  Created by apple on 10/18/23.
//

import SwiftUI

struct CustomDatePicker: View {
    let title: String
    @Binding var date: Date
    
    var body: some View {
        HStack {
            Text(title)
                .customStyle(.caption)
                .foregroundStyle(Color.black)
            Spacer()
            Text(formatDate(date: date))
                .customStyle(.caption)
                .foregroundStyle(Color.gray300)
                .overlay {
                    DatePicker("", selection: $date, displayedComponents: .date)
                        .tint(Color.clear)
                        .blendMode(.colorDodge)
                }
                .clipped()
            Text(formatTime(date: date))
                .customStyle(.caption)
                .foregroundStyle(Color.gray300)
                .padding(4)
                .overlay {
                    DatePicker("", selection: $date, displayedComponents: .hourAndMinute)
                        .tint(Color.clear)
                        .blendMode(.colorDodge)
                }
                .clipped()
                .background {
                    Color.background
                        .cornerRadius(4)
                }
        }
    }
    
    func formatDate(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy년 MM월 dd일 (EE)"
        return dateFormatter.string(from: date)
    }
    
    func formatTime(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter.string(from: date)
    }
}

#Preview {
    CustomDatePicker(title: "시작", date: .constant(Date()))
}
