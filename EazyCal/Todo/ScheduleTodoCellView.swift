//
//  ScheduleTodoCellView.swift
//  EazyCal
//
//  Created by apple on 10/25/23.
//

import SwiftUI
import EventKit

struct ScheduleTodoCellView: View {
    var schedule: EKEvent
    @ObservedObject var calendarViewModel: CalendarViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                CalendarCategoryLabelView(
                    title: schedule.title,
                    color: schedule.calendar.cgColor
                )
                .foregroundStyle(Color(cgColor: schedule.calendar.cgColor!))
                Spacer()
                Text(schedule.startDate, style: .date)
                    .customStyle(.caption)
                    .foregroundStyle(.gray300)
            }
            
            ForEach(calendarViewModel.todosInSchedule(schedule: schedule), id: \.self) { todo in
                Button(action: {
                    //                                switch todo.contains("☑︎") {
                    //                                case true:
                    //                                    todo = todo.replacingOccurrences(of: "☑︎", with: "☐")
                    //                                case false:
                    //                                    todo = todo.replacingOccurrences(of: "☐", with: "☑︎")
                    //                                }
                }) {
                    HStack {
                        switch todo.contains("☑︎") {
                        case true:
                            Image(systemName: SFSymbol.checkCircle.name)
                                .font(CustomTextStyle.body.font)
                        case false:
                            Image(systemName: SFSymbol.circle.name)
                                .font(CustomTextStyle.body.font)
                        }
                        let text = todo.replacingOccurrences(of: "☑︎", with: "").replacingOccurrences(of: "☐", with: "")
                        Text(text)
                            .customStyle(.body)
                    }
                    .foregroundStyle(Color.calendarBlack)
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(cgColor: schedule.calendar.cgColor!))
                .opacity(0.1)
        }
    }
}

#Preview {
    ScheduleTodoCellView(schedule: EKEvent(), calendarViewModel: CalendarViewModel())
}
