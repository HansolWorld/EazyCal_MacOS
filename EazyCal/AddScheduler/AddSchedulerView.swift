//
//  AddSchedulerView.swift
//  EazyCal
//
//  Created by apple on 10/16/23.
//

import SwiftUI
import EventKit    

struct AddSchedulerView: View {
    @State var title = ""
    @State var isAllDay = false
    @State var startDate: Date
    @State var doDate: Date
    @State var repeatDate = RepeatType.oneDay
    @State var todos:[String] = []
    @State var categories: [EKCalendar]
    @State var category: EKCalendar
    @ObservedObject var calendarViewModel = CalendarViewModel()
    @EnvironmentObject var eventStore: EventStore
    
    var body: some View {
        VStack(alignment: .leading) {
            TextField("새로운 일정", text: $title)
//                .customStyle(.body2)
                .font(CustomTextStyle.body2.font)
                .foregroundStyle(Color.gray300)
            Divider()
                .frame(height: 0.5)
                .frame(maxWidth: .infinity)
                .background {
                    Color.gray200
                }
            CustomToggle(title: "종일", isOn: $isAllDay)
            CustomDatePicker(title: "시작", date: $startDate)
            CustomDatePicker(title: "종료", date: $doDate)
            RepeatSelectedButton(title: "반복", selected: $repeatDate)
            CustomTextField(title: "할 일", todos: $todos)
            CustomPicker(title: "카테고리", categoryList: categories, selected: $category)
        }
        .padding()
        .onDisappear {
            Task {
                if title != "" {
                    await eventStore.saveEvent(
                        title: title,
                        isAllDay: isAllDay,
                        startDate: startDate,
                        endDate: doDate,
                        repeatDate: repeatDate,
                        notes: todos,
                        calendar: category
                    )
                    await calendarViewModel.loadSchedule(eventStore: eventStore)
                    await calendarViewModel.loadAllSchedule(eventStore: eventStore)
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.white
            .scaleEffect(1.5)
        AddSchedulerView(startDate: Date(), doDate: Date(), categories: [], category: EKCalendar())
            .previewLayout(.sizeThatFits)
    }
}
