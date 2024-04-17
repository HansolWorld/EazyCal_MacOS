//
//  CalendarCategoryLabelView.swift
//  EazyCal
//
//  Created by apple on 10/20/23.
//

import SwiftUI
import EventKit

struct CalendarCategoryLabelView: View {
    let schedule: EKEvent
    let viewType: CellViewType
    
    @State var isSelected = false
    @State var isHover = false
    @State var isEdit = false
    @State var requestSchedule: EKEvent?
    @State var deleteSchedule = false
    @Binding var selectedEvent: EKEvent?
    @EnvironmentObject var eventManager: EventStoreManager
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: SFSymbol.circleFill.name)
                .resizable()
                .scaledToFit()
                .frame(width: 6, height: 6)
                .fontWeight(.heavy)
                .foregroundStyle(viewType == .Dating || viewType == .DoDate ? Color.clear : Color(cgColor: schedule.calendar.cgColor))
            Text(viewType == .Dating || viewType == .DoDate ? " " : schedule.title)
                .font(.callout)
                .foregroundStyle(selectedEvent == schedule ? Color.white : Color.black)
                .lineLimit(1)
        }
        .font(.body)
        .padding(.vertical, 2)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            if schedule.isAllDay || Calendar.current.dateComponents([.day], from: schedule.startDate, to: schedule.endDate).day ?? 0 >= 1 {
                switch viewType {
                case .Dating:
                    Rectangle()
                        .fill(Color(cgColor: schedule.calendar.cgColor))
                        .opacity(selectedEvent == schedule ? 1 : 0.1)
                case .StartDate:
                    UnevenRoundedRectangle(topLeadingRadius: 8, bottomLeadingRadius: 8, bottomTrailingRadius: 0, topTrailingRadius: 0, style: .circular)
                        .fill(Color(cgColor: schedule.calendar.cgColor))
                        .opacity(selectedEvent == schedule ? 1 : 0.1)
                        .padding(.leading, 4)
                case .DoDate:
                    UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 8, topTrailingRadius: 8, style: .circular)
                        .fill(Color(cgColor: schedule.calendar.cgColor))
                        .opacity(selectedEvent == schedule ? 1 : 0.1)
                        .padding(.trailing, 4)
                case .OneDate:
                    UnevenRoundedRectangle(topLeadingRadius: 8, bottomLeadingRadius: 8, bottomTrailingRadius: 8, topTrailingRadius: 8, style: .circular)
                        .fill(Color(cgColor: schedule.calendar.cgColor))
                        .opacity(selectedEvent == schedule ? 1 : 0.1)
                        .padding(.horizontal, 4)
                }
            } else {
                if selectedEvent == schedule {
                    UnevenRoundedRectangle(topLeadingRadius: 8, bottomLeadingRadius: 8, bottomTrailingRadius: 8, topTrailingRadius: 8, style: .circular)
                        .fill(Color(cgColor: schedule.calendar.cgColor))
                        .padding(.horizontal, 4)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2, perform: {
            if selectedEvent == schedule {
                isEdit = true
            } else {
                isEdit = false
            }
        })
        .simultaneousGesture(TapGesture().onEnded {
            withAnimation {
                selectedEvent = schedule
            }
        })
        .onDrag { () -> NSItemProvider in
            selectedEvent = schedule
            return NSItemProvider(object: schedule.eventIdentifier as NSString)
        }
        .onChange(of: selectedEvent, { oldValue, newValue in
            if selectedEvent == schedule {
                isSelected = true
            } else {
                isSelected = false
            }
        })
        .popover(isPresented: $isEdit) {
            EditSchedulePopoverView(
                event: schedule,
                editTitle: schedule.title,
                editIsAllDay: schedule.isAllDay,
                editStartDate: schedule.startDate,
                editDoDate: schedule.endDate,
                editRepeatDate: RepeatType.oneDay,
                editURL: schedule.url?.absoluteString ?? "",
                editTodos: todos(),
                editCategory: schedule.calendar
            )
            .environmentObject(eventManager)
        }
        .contextMenu {
            Button(action: {
                requestSchedule = schedule
                deleteSchedule = true
            }) {
                Text("삭제")
            }
        }
        .alert("\(requestSchedule?.title ?? "") 스케줄 삭제", isPresented: $deleteSchedule) {
            Button("취소", role: .cancel) {
                requestSchedule = nil
            }
            Button("삭제", role: .destructive) {
                if let schedule = requestSchedule {
                    Task {
                        try await eventManager.removeEvent(event: schedule)
                        requestSchedule = nil
                    }
                }
            }
        }
        .focusable()
        .focusEffectDisabled()
        .onKeyPress { key in
            if !isEdit {
                if key.key == KeyEquivalent("\u{7F}"), !isEdit {
                    if let selectedEvent {
                        Task {
                            try await self.eventManager.removeEvent(event: selectedEvent)
                            self.selectedEvent = nil
                        }
                    }
                } else if key.key == .return {
                    isEdit = true
                }
                
                return .handled
            }
            
            return .ignored
        }
    }
    
    func repeatType(_ frequency: EKRecurrenceFrequency?) -> RepeatType {
        if let frequency = frequency {
            switch frequency {
            case .daily:
                return .everyDay
            case .weekly:
                return .everyWeek
            case .monthly:
                return .everyMonth
            case .yearly:
                return .everyYear
            default:
                return .oneDay
            }
        } else {
            return .oneDay
        }
    }
    
    func todos() -> [Todo] {
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
