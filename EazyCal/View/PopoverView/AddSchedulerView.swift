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
    @State var todo: String = ""
    @State var todos:[String] = []
    @State var category: EKCalendar
    @State var url: String = ""
    @State var linkURL: URL?
    @EnvironmentObject var eventManager: EventStoreManager
    
    var body: some View {
        VStack(alignment: .leading) {
            TextField("새로운 일정", text: $title)
                .font(.title3)
                .foregroundStyle(Color.gray400)
                .textFieldStyle(.plain)
            HStack {
                Text("종일")
                    .font(.body)
                    .foregroundStyle(Color.gray400)
                Spacer()
                Toggle("", isOn: $isAllDay)
                    .foregroundStyle(Color.gray200)
                    .toggleStyle(BackgroundToggleStyle())
                    .labelsHidden()
            }
            HStack {
                Text("시작")
                    .font(.body)
                    .foregroundStyle(Color.gray400)
                Spacer()
                DatePicker("", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                    .foregroundStyle(Color.calendarBlack)
            }
            HStack {
                Text("종료")
                    .font(.body)
                    .foregroundStyle(Color.gray400)
                Spacer()
                DatePicker("", selection: $doDate, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                    .foregroundStyle(Color.calendarBlack)
            }
            RepeatSelectedButton(title: "반복", selected: $repeatDate)
            CustomPicker(title: "카테고리", categoryList: eventManager.calendars, selected: $category)
            
            HStack {
                Text("URL")
                    .font(.body)
                    .foregroundStyle(Color.gray400)
                TextField("입력 후 엔터를 눌러주세요", text: $url)
                    .font(.body)
                    .foregroundStyle(Color.gray400)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        linkURL = URL(string: url)
                        url = ""
                    }
            }
            if let linkURL {
                Link(destination: linkURL) {
                    Text(url)
                        .font(.body)
                }
            }
            
            Text("할 일")
                .font(.body)
                .foregroundStyle(Color.gray400)
            ForEach(todos.indices, id:\.self) { index in
                HStack {
                    Image(systemName: SFSymbol.circle.name)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                        .foregroundStyle(Color.calendarBlue)
                    TextField("", text: $todos[index])
                        .foregroundStyle(Color.gray400)
                        .textFieldStyle(.plain)
                }
            }
            HStack {
                Image(systemName: SFSymbol.circle.name)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                    .foregroundStyle(Color.calendarBlue)
                TextField("새로운 할일", text: $todo)
                    .font(.body)
                    .foregroundStyle(Color.gray400)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        todos.append(todo)
                        todo = ""
                    }
            }            
        }
        .padding()
        .onDisappear {
            Task {
                if title != "" {
                    do {
                        try await eventManager.saveEvent(
                            title: title,
                            isAllDay: isAllDay,
                            startDate: startDate,
                            endDate: doDate,
                            repeatDate: repeatDate,
                            url: linkURL,
                            notes: todos,
                            calendar: category
                        )
                    } catch {
                    }
                }
            }
        }
    }
}

#Preview {
    AddSchedulerView(startDate: Date(), doDate: Date(), category: EKCalendar(), url: "")
        .previewLayout(.sizeThatFits)
        .environmentObject(EventStoreManager())
        .background {
            Color.white
                .scaleEffect(1.5)
        }
}
