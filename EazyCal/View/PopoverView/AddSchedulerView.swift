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
    var linkURL: URL? {
        if !url.contains("http") {
            return URL(string: "http://\(url)")
        } else {
            return URL(string: url)
        }
    }
    @EnvironmentObject var eventManager: EventStoreManager
    
    var body: some View {
        VStack(alignment: .leading) {
            TextField(String(localized: "EVENT_NEW"), text: $title)
                .font(.title3)
                .foregroundStyle(Color.gray400)
                .textFieldStyle(.plain)
            HStack {
                Text(String(localized: "ALL_DAY"))
                    .font(.body)
                    .foregroundStyle(Color.gray400)
                Spacer()
                Toggle("", isOn: $isAllDay)
                    .foregroundStyle(Color.gray200)
                    .toggleStyle(BackgroundToggleStyle())
                    .labelsHidden()
            }
            HStack {
                Text(String(localized: "START"))
                    .font(.body)
                    .foregroundStyle(Color.gray400)
                Spacer()
                DatePicker("", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                    .foregroundStyle(Color.calendarBlack)
            }
            HStack {
                Text(String(localized: "END"))
                    .font(.body)
                    .foregroundStyle(Color.gray400)
                Spacer()
                DatePicker("", selection: $doDate, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                    .foregroundStyle(Color.calendarBlack)
            }
            RepeatSelectedButton(title: String(localized: "REPEAT"), selected: $repeatDate)
            CustomPicker(title: String(localized: "CATEGORY"), categoryList: eventManager.calendars, selected: $category)
            
            HStack {
                Text(String(localized: "URL"))
                    .font(.body)
                    .foregroundStyle(Color.gray400)
                TextField(String(localized: "URL_INPUT_PLACEHOLD"), text: $url)
                    .font(.body)
                    .foregroundStyle(Color.gray400)
                    .textFieldStyle(.plain)
                    .multilineTextAlignment(.trailing)
            }
            if !url.isEmpty, let linkURL {
                Link(destination: linkURL) {
                    Text(url)
                        .font(.body)
                }
            }
            
            Text(String(localized: "REMINDER"))
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
                TextField(String(localized: "NEW_REMINDER"), text: $todo)
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
                            url: URL(string: url),
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
