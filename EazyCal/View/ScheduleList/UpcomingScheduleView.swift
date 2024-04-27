//
//  UpcomingScheduleView.swift
//  EazyCal
//
//  Created by apple on 4/12/24.
//

import SwiftUI
import EventKit

struct UpcomingScheduleView: View {
    let schedule: EKEvent
    let dateString: String
    @State private var isEdit = false
    
    var body: some View {
        if let calendar = schedule.calendar {
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: SFSymbol.circleFill.name)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 6, height: 6)
                        .fontWeight(.heavy)
                        .foregroundStyle(Color(cgColor: calendar.cgColor))
                    Text(schedule.title)
                        .font(.body)
                        .foregroundStyle(Color.gray400)
                        .lineLimit(1)
                }
                HStack {
                    if schedule.isAllDay || (Calendar.current.dateComponents([.day], from: schedule.startDate, to: schedule.endDate).day ?? 0 >= 1 && dateToString(schedule.endDate) != dateString ) {
                        Text(String(localized: "ALL_DAY"))
                        Spacer()
                    } else {
                        Text(schedule.startDate, style: .time)
                        Text("-")
                        Text(schedule.endDate, style: .time)
                        Spacer()
                    }
                }
                .font(.subheadline)
                .foregroundStyle(Color.gray300)
                .padding(.leading, 16)
            }
            .padding(12)
            .background {
                Color.background
                    .cornerRadius(12)
            }
            .onTapGesture {
                isEdit = true
            }
            .popover(isPresented: $isEdit, arrowEdge: .trailing) {
                EditSchedulePopoverView(
                    event: schedule,
                    editTitle: schedule.title,
                    editIsAllDay: schedule.isAllDay,
                    editStartDate: schedule.startDate,
                    editDoDate: schedule.endDate,
                    editRepeatDate: RepeatType.oneDay,
                    editURL: schedule.url?.absoluteString ?? "",
                    editTodos: todos(schedule),
                    editCategory: schedule.calendar
                )
            }
        }
    }
    
    private func dateToString(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = String(localized: "DATE_FORMAT_EVENT")
        
        return dateFormatter.string(from: date)
    }
    
    private func todos(_ schedule: EKEvent) -> [Todo] {
        let todosString = schedule.notes?.components(separatedBy: "\n").filter {$0.contains("☐") || $0.contains("☑︎")} ?? []
        return todosString.map {
            if $0.contains("☐") {
                return Todo(isComplete: false, title: $0.replacingOccurrences(of: "☐", with: ""))
            } else {
                return Todo(isComplete: true, title: $0.replacingOccurrences(of: "☑︎", with: ""))
            }
        }
    }
}

#Preview {
    UpcomingScheduleView(schedule: EKEvent(), dateString: "")
}
