//
//  AddSchedulerView.swift
//  EazyCal
//
//  Created by apple on 10/16/23.
//

import SwiftUI

enum RepeatType: CaseIterable {
    case everyDay
    case everyWeek
    case everyMonth
    case everyYear
    case check
    
    var title: String {
        switch self {
        case .check:
            return "지정"
        case .everyDay:
            return "매일"
        case .everyWeek:
            return "매주"
        case .everyMonth:
            return "매달"
        case .everyYear:
            return "매년"
            
        }
    }
}
    

struct AddSchedulerView: View {
//    let schedule: Schedule
    @State var isOn = false
    @State var startDate: Date
    @State var doDate: Date
    @State var repeatDate = RepeatType.everyDay
    @State var todos:[String] = []
    @State var category = CalendarCategory.dummyCategories[0]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("새로운 일정")
                .customStyle(.body2)
                .foregroundStyle(Color.gray300)
            Divider()
                .frame(height: 0.5)
                .frame(maxWidth: .infinity)
                .background {
                    Color.gray200
                }
            CustomToggle(title: "종일", isOn: $isOn)
            CustomDatePicker(title: "시작", date: $startDate)
            CustomDatePicker(title: "종료", date: $doDate)
            RepeatSelectedButton(title: "반복", selected: $repeatDate)
            CustomTextField(title: "할 일", todos: $todos)
            CustomPicker(title: "카테고리", categoryList: CalendarCategory.dummyCategories, selected: $category)
        }
        .padding()
    }
}

#Preview {
    ZStack {
        Color.white
            .scaleEffect(1.5)
        AddSchedulerView(startDate: Date(), doDate: Date())
            .previewLayout(.sizeThatFits)
    }
}
