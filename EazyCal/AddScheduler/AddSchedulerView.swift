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
    @State var startDate = Date()
    @State var doDate = Date()
    @State var repeatDate = RepeatType.everyDay
    @State var todo = ""
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("새로운 일정")
                .customStyle(.body2)
            Divider()
            Toggle("종일", isOn: $isOn)
            HStack {
                Text("시작")
                    .customStyle(.caption)
                DatePicker("시작", selection: $startDate)
                    .labelsHidden()
                    .colorMultiply(.gray300)
            }
            DatePicker("종료", selection: $doDate)
                .colorMultiply(.gray300)
            HStack {
                Text("반복")
                Spacer()
                Picker("반복", selection: $repeatDate) {
                    ForEach(RepeatType.allCases, id:\.self) { repeatType in
                        Text(repeatType.title)
                    }
                }
                .colorMultiply(.gray300)
                .pickerStyle(.segmented)
            }
            HStack {
                Text("할 일")
                Spacer()
                TextField("할 일을 입력하세요", text: $todo)
                    .colorMultiply(.gray300)
            }
            Text("카테고리")
        }
        .padding()
    }
}

#Preview {
    AddSchedulerView()
}
