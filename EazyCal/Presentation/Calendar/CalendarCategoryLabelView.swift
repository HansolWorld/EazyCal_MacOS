//
//  CalendarCategoryLabelView.swift
//  EazyCal
//
//  Created by apple on 10/20/23.
//

import SwiftUI

struct CalendarCategoryLabelView: View {
    let schedule: EventItem
    let viewType: CellViewType
    
    @State var isHover = false
    @State var isEdit = false
    @State var requestSchedule: EventItem?
    @State var deleteSchedule = false
    @Binding var selectedEventIdentifier: String?
    @Binding var selectedReminderIdentifier: String?
    @EnvironmentObject var eventManager: EventStoreManager
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: SFSymbol.circleFill.name)
                .resizable()
                .scaledToFit()
                .frame(width: 6, height: 6)
                .fontWeight(.heavy)
                .foregroundStyle(viewType == .Dating || viewType == .DoDate ? Color.clear : Color(calendarColor: schedule.calendar.color))
            Text(viewType == .Dating || viewType == .DoDate ? " " : schedule.title)
                .font(.callout)
                .foregroundStyle(isSelected ? Color.white : Color.black)
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
                        .fill(Color(calendarColor: schedule.calendar.color))
                        .opacity(isSelected ? 1 : 0.1)
                case .StartDate:
                    UnevenRoundedRectangle(topLeadingRadius: 8, bottomLeadingRadius: 8, bottomTrailingRadius: 0, topTrailingRadius: 0, style: .circular)
                        .fill(Color(calendarColor: schedule.calendar.color))
                        .opacity(isSelected ? 1 : 0.1)
                        .padding(.leading, 4)
                case .DoDate:
                    UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 8, topTrailingRadius: 8, style: .circular)
                        .fill(Color(calendarColor: schedule.calendar.color))
                        .opacity(isSelected ? 1 : 0.1)
                        .padding(.trailing, 4)
                case .OneDate:
                    UnevenRoundedRectangle(topLeadingRadius: 8, bottomLeadingRadius: 8, bottomTrailingRadius: 8, topTrailingRadius: 8, style: .circular)
                        .fill(Color(calendarColor: schedule.calendar.color))
                        .opacity(isSelected ? 1 : 0.1)
                        .padding(.horizontal, 4)
                }
            } else {
                if isSelected {
                    UnevenRoundedRectangle(topLeadingRadius: 8, bottomLeadingRadius: 8, bottomTrailingRadius: 8, topTrailingRadius: 8, style: .circular)
                        .fill(Color(calendarColor: schedule.calendar.color))
                        .padding(.horizontal, 4)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2, perform: {
            if isSelected {
                isEdit = true
            } else {
                isEdit = false
            }
        })
        .simultaneousGesture(TapGesture().onEnded {
            withAnimation {
                selectedReminderIdentifier = nil
                selectedEventIdentifier = schedule.id
            }
        })
        .onDrag { () -> NSItemProvider in
            selectedReminderIdentifier = nil
            selectedEventIdentifier = schedule.id
            return NSItemProvider(object: schedule.id as NSString)
        }
        .popover(isPresented: $isEdit) {
            EditSchedulePopoverView(
                event: schedule,
                editTitle: schedule.title,
                editIsAllDay: schedule.isAllDay,
                editStartDate: schedule.startDate,
                editDoDate: schedule.endDate,
                editRepeatDate: schedule.repeatType,
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
                Text(String(localized: "DELETE"))
            }
        }
        .alert(String(localized: "\(requestSchedule?.title ?? "") DELETE_EVENT"), isPresented: $deleteSchedule) {
            Button(String(localized: "CANCEL"), role: .cancel) {
                requestSchedule = nil
            }
            Button(String(localized: "DELETE"), role: .destructive) {
                if let schedule = requestSchedule {
                    Task {
                        try await eventManager.removeEvent(identifier: schedule.id)
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
                    if let selectedEventIdentifier {
                        Task {
                            try await self.eventManager.removeEvent(identifier: selectedEventIdentifier)
                            self.selectedEventIdentifier = nil
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

    private var isSelected: Bool {
        selectedEventIdentifier == schedule.id
    }
    
    func todos() -> [Todo] {
        let todosString = schedule.notes.components(separatedBy: "\n").filter {$0.contains("☐") || $0.contains("☑︎")}
        return todosString.map {
            if $0.contains("☐") {
                return Todo(isComplete: false, title: $0.replacingOccurrences(of: "☐", with: ""))
            } else {
                return Todo(isComplete: true, title: $0.replacingOccurrences(of: "☑︎", with: ""))
            }
        }
    }
}
