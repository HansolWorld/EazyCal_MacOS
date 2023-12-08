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
    @State var scheduleTodos: [String]
    @EnvironmentObject var eventManager: EventStoreManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: SFSymbol.circleFill.name)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 6, height: 6)
                    .fontWeight(.heavy)
                    .foregroundStyle(Color(cgColor: schedule.calendar.cgColor ?? CGColor.clear))
                Text(schedule.title)
                    .font(.body)
                    .foregroundStyle(.black)
                    .lineLimit(1)
                Spacer()
                Text(schedule.startDate, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.gray300)
            }
            
            
            ForEach(scheduleTodos.indices, id: \.self) { index in
                Button(action: {
                    let todo = scheduleTodos[index]
                    switch todo.contains("☑︎") {
                    case true:
                        scheduleTodos[index] = todo.replacingOccurrences(of: "☑︎", with: "☐")
                    case false:
                        scheduleTodos[index] = todo.replacingOccurrences(of: "☐", with: "☑︎")
                    }
                    
                    var newNotes = schedule.notes?.components(separatedBy: "\n").filter( {!($0.contains("☑︎") || $0.contains("☐"))} ) ?? []
                    
                    newNotes += scheduleTodos
                    schedule.notes = newNotes.joined(separator: "\n")

                    Task {
                        try await eventManager.updateEvent(ekEvent:schedule)
                    }
                }) {
                    HStack {
                        
                        let isCompletedTodo = scheduleTodos[index].contains("☑︎")
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
                        let text = scheduleTodos[index].replacingOccurrences(of: "☑︎", with: "").replacingOccurrences(of: "☐", with: "")
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
                .fill(Color(cgColor: schedule.calendar.cgColor!))
                .opacity(0.1)
        }
    }
}

#Preview {
    ScheduleTodoCellView(schedule: EKEvent(), scheduleTodos: ["할일1", "할일2"])
}
