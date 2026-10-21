//
//  ScheduleTodoCellView.swift
//  EazyCal
//
//  Created by apple on 10/25/23.
//

import SwiftUI

struct ScheduleTodoCellView: View {
    @Binding var schedule: EventItem
    @State private var lastButtonPressTime: Date?
    @EnvironmentObject var eventManager: EventStoreManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: SFSymbol.circleFill.name)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 6, height: 6)
                    .fontWeight(.heavy)
                    .foregroundStyle(Color(calendarColor: schedule.calendar.color))
                Text(schedule.title)
                    .font(.body)
                    .foregroundStyle(.black)
                    .lineLimit(1)
                Spacer()
                Text(schedule.startDate, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.gray300)
            }
            
            let notes = splitTodo(by: schedule.notes)
            ForEach(notes.indices, id: \.self) { index in
                Button(action: {
                    var scheduleTodos = splitTodo(by: schedule.notes)
                    let todo = scheduleTodos[index]
                    switch todo.contains("☑︎") {
                    case true:
                        scheduleTodos[index] = todo.replacingOccurrences(of: "☑︎", with: "☐")
                    case false:
                        scheduleTodos[index] = todo.replacingOccurrences(of: "☐", with: "☑︎")
                    }
                    
                    var newNotes = schedule.notes.components(separatedBy: "\n").filter( {!($0.contains("☑︎") || $0.contains("☐"))} )
                    
                    newNotes += scheduleTodos
                    schedule.notes = newNotes.joined(separator: "\n")
                    
                    lastButtonPressTime = Date()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        if let lastPressTime = lastButtonPressTime, Date().timeIntervalSince(lastPressTime) >= 1.5 {
                            Task {
                                try await eventManager.updateEvent(event: schedule)
                            }
                        }
                    }
                }) {
                    HStack {
                        
                        let isCompletedTodo = notes[index].contains("☑︎")
                        switch isCompletedTodo {
                        case true:
                            Image(systemName: SFSymbol.checkCircle.name)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 12, height: 12)
                                .foregroundStyle(.gray300)
                        case false:
                            Image(systemName: SFSymbol.circle.name)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 12, height: 12)
                                .foregroundStyle(.gray300)
                        }
                        let text = notes[index].replacingOccurrences(of: "☑︎", with: "").replacingOccurrences(of: "☐", with: "")
                        Text(text)
                            .font(.body)
                            .strikethrough(isCompletedTodo)
                            .opacity(isCompletedTodo ? 0.6 : 1)
                    }
                    .foregroundStyle(Color.calendarBlack)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(calendarColor: schedule.calendar.color))
                .opacity(0.1)
        }
    }
    
    func splitTodo(by notes: String) -> [String] {
        return notes.components(separatedBy: "\n")
    }
}

#Preview {
    ScheduleTodoCellView(
        schedule: .constant(
            EventItem(
                id: "preview",
                calendar: CalendarItem(id: "preview", title: "Preview", color: .clear),
                title: "Preview",
                isAllDay: false,
                startDate: Date(),
                endDate: Date(),
                repeatType: .oneDay,
                url: nil,
                notes: ""
            )
        )
    )
}
