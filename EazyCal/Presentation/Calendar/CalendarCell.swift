//
//  CalendarCell.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import SwiftUI

struct CalendarCell: View {
    let schedules: [LayeredCalendarEntry]
    let month: Month
    let isToday: Bool
    let count : Int
    let start : Int
    let daysInMonth : Int
    let daysInPrevMonth : Int
    @State private var isHover = false
    @State private var isMoreEventPopover = false
    @ObservedObject var calendarViewModel: CalendarViewModel
    @Binding var currentDragTemplate: Template?
    @Binding var selectedEventIdentifier: String?
    @Binding var selectedReminderIdentifier: String?
    @EnvironmentObject var eventManager: EventStoreManager
    
    @State var isShow = false
    
    
    var body: some View {
        
        GeometryReader { proxy in
            let taskViewCount: Int = Int((proxy.size.height-29) / 24)
            
            VStack(alignment: .leading, spacing: 4) {
                ZStack {
                    Text("\(month.dayInt)")
                        .font(.callout)
                        .foregroundColor(textColor(type: month.monthType, count: count))
                        .padding(3)
                        .background {
                            Circle()
                                .fill(isToday ? Color.calendarBlue : Color.clear)
                        }
                        .padding([.top, .leading], 4)
                }
                
                ForEach(0...max(taskViewCount-2, 0), id: \.self) { index in
                    if let schedule = schedules.first(where: { $0.layer == index + 1 }) {
                        entryLabel(
                            schedule.entry,
                            viewType: cellViewType(schedule.entry)
                        )
                    } else {
                        Text(" ")
                            .font(.body)
                            .padding(2)
                    }
                }
                
                let notViewTask = schedules.filter { $0.layer > (taskViewCount - 1) }
                if notViewTask.count != 0 {
                    Text(String(localized: "+\(notViewTask.count) EVENT_COUNT"))
                        .font(.body)
                        .foregroundStyle(Color.gray300)
                        .padding(.horizontal, 6)
                        .padding(.bottom, 4)
                        .onTapGesture {
                            isMoreEventPopover = true
                        }
                        .popover(isPresented: $isMoreEventPopover, arrowEdge: .trailing) {
                            VStack(alignment: .leading) {
                                ForEach(schedules) { schedule in
                                    entryLabel(schedule.entry, viewType: .OneDate)
                                }
                            }
                            .padding(4)
                            .background {
                                Color.white
                                    .scaleEffect(1.5)
                            }
                        }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background {
                if isHover {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .onTapGesture(count: 2) {
                            isShow.toggle()
                        }
                        .shadow(radius: 2)
                } 
                else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .onTapGesture(count: 2) {
                            isShow.toggle()
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            selectedEventIdentifier = nil
                            selectedReminderIdentifier = nil
                        })
                }
            }
            .popover(isPresented: $isShow) {
                ZStack {
                    Color.white
                        .scaleEffect(1.5)
                    
                    if let calendar = eventManager.calendars.first {
                        AddSchedulerView(
                            startDate: cellDate,
                            doDate: cellDate,
                            category: calendar
                        )
                        .environmentObject(eventManager)
                    }
                }
            }
            .onDrop(of: [.text], isTargeted: $isHover) { _ in
                let item: CalendarDropItem
                if let currentDragTemplate {
                    item = .template(currentDragTemplate)
                } else if let selectedReminderIdentifier {
                    item = .reminder(identifier: selectedReminderIdentifier)
                } else if let selectedEventIdentifier {
                    item = .event(identifier: selectedEventIdentifier)
                } else {
                    return false
                }

                currentDragTemplate = nil
                selectedReminderIdentifier = nil
                selectedEventIdentifier = nil
                Task {
                    await CalendarDropCoordinator(eventHandler: eventManager)
                        .perform(item, on: cellDate)
                }
                return true
            }
        }
        .frame(minWidth: 80, minHeight: 80)
    }

    @ViewBuilder
    private func entryLabel(_ entry: CalendarEntry, viewType: CellViewType) -> some View {
        switch entry.kind {
        case .event:
            if let event = eventManager.event(withIdentifier: entry.sourceIdentifier) {
                CalendarCategoryLabelView(
                    schedule: event,
                    viewType: viewType,
                    selectedEventIdentifier: $selectedEventIdentifier,
                    selectedReminderIdentifier: $selectedReminderIdentifier
                )
                .environmentObject(eventManager)
            }
        case .reminder:
            if let reminder = eventManager.reminder(withIdentifier: entry.sourceIdentifier) {
                ScheduledReminderLabelView(
                    reminder: reminder,
                    selectedEventIdentifier: $selectedEventIdentifier,
                    selectedReminderIdentifier: $selectedReminderIdentifier
                )
                .environmentObject(eventManager)
            }
        }
    }
    
    func textColor(type: MonthType, count: Int) -> Color {
        if type == MonthType.Current {
            if self.isToday {
                return Color.white
            } else if count % 7 == 1 {
                return Color.calendarRed
            } else {
                return Color.calendarBlack
            }
        } else if count % 7 == 1 {
            return Color.calendarRed
        } else {
            return Color.gray
        }
    }
    
    func cellViewType(_ entry: CalendarEntry) -> CellViewType {
        guard entry.kind == .event else {
            return .OneDate
        }

        let calendar = Calendar.current
        let currentDate = calendar.startOfDay(for: cellDate)
        let startDate = calendar.startOfDay(for: entry.startDate)
        let endDate = calendar.startOfDay(for: entry.endDate)

        if startDate == currentDate && endDate == currentDate {
            return .OneDate
        } else if startDate == currentDate {
            return .StartDate
        } else if endDate == currentDate {
            return .DoDate
        } else {
            return .Dating
        }
    }
    
    private var cellDate: Date {
        calendarViewModel.date(for: month)
    }
}

#Preview {
    CalendarCell(
        schedules: [],
        month: Month(monthType: .Current, dayInt: 1),
        isToday: true,
        count: 1,
        start: 1,
        daysInMonth: 1,
        daysInPrevMonth: 1,
        calendarViewModel: CalendarViewModel(),
        currentDragTemplate: .constant(nil),
        selectedEventIdentifier: .constant(nil),
        selectedReminderIdentifier: .constant(nil)
    )
    .environmentObject(EventStoreManager())
}
