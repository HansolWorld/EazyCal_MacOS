//
//  CalendarCell.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import SwiftUI
import EventKit

struct CalendarCell: View {
    let schedules: [(CalendarEntry, Int)]
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
    @Binding var selectedEvent: EKEvent?
    @Binding var selectedReminder: EKReminder?
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
                    if let scheduleTuple = schedules.first(where: { $0.1 == index+1 }) {
                        entryLabel(
                            scheduleTuple.0,
                            viewType: cellViewType(scheduleTuple.0)
                        )
                    } else {
                        Text(" ")
                            .font(.body)
                            .padding(2)
                    }
                }
                
                let notViewTask = schedules.filter({ $0.1 > (taskViewCount - 1) })
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
                                ForEach(schedules, id: \.0.id) { schedule in
                                    entryLabel(schedule.0, viewType: .OneDate)
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
                            selectedEvent = nil
                            selectedReminder = nil
                        })
                }
            }
            .popover(isPresented: $isShow) {
                ZStack {
                    Color.white
                        .scaleEffect(1.5)
                    
                    AddSchedulerView(
                        startDate: calculateDate(forMonthType: month.monthType),
                        doDate: calculateDate(forMonthType: month.monthType),
                        category: eventManager.calendars.first ?? EKCalendar()
                    )
                    .environmentObject(eventManager)
                }
            }
            .onDrop(of: [.text], isTargeted: $isHover) { providers in
                if let currentDragTemplate, let ekCalendar = eventManager.calendars.first(where: {$0.calendarIdentifier == currentDragTemplate.calendarId}) {
                    
                    let calendar = Calendar.current
                    let startTime =  calendar.dateComponents([.hour, .minute], from: currentDragTemplate.startTime)
                    let endTime =  calendar.dateComponents([.hour, .minute], from: currentDragTemplate.endTime)
                    
                    var addMonth = 0
                    if month.monthType == .Previous {
                        addMonth = -1
                    } else if month.monthType == .Next {
                        addMonth = 1
                    }
                    var startComponents = DateComponents()
                    startComponents.year = calendarViewModel.year()
                    startComponents.month = calendarViewModel.month() + addMonth
                    startComponents.day = month.dayInt
                    startComponents.hour = startTime.hour
                    startComponents.minute = startTime.minute
                    
                    var endComponents = DateComponents()
                    endComponents.year = calendarViewModel.year()
                    endComponents.month = calendarViewModel.month() + addMonth
                    endComponents.day = month.dayInt
                    endComponents.hour = endTime.hour
                    endComponents.minute = endTime.minute
                    
                    guard let startDate = calendar.date(from: startComponents),
                          let endDate = calendar.date(from: endComponents) else {
                        self.currentDragTemplate = nil
                        return false
                    }
                    
                    Task {
                        try await eventManager.saveEvent(
                            title: currentDragTemplate.title,
                            isAllDay: currentDragTemplate.isAllDay,
                            startDate: startDate,
                            endDate: endDate,
                            repeatDate: .oneDay, 
                            url: nil,
                            notes: currentDragTemplate.todos,
                            calendar: ekCalendar
                        )
                    }
                    
                    self.currentDragTemplate = nil
                } else if let selectedReminder {
                    let targetDate = calculateDate(forMonthType: month.monthType)

                    Task {
                        try await eventManager.rescheduleReminder(
                            selectedReminder,
                            to: targetDate
                        )
                    }

                    self.selectedReminder = nil
                } else if let selectedEvent {
                    var addMonth = 0
                    if month.monthType == .Previous {
                        addMonth = -1
                    } else if month.monthType == .Next {
                        addMonth = 1
                    }
                    
                    let currentDateComponents = DateComponents(
                        year: calendarViewModel.year(),
                        month: calendarViewModel.month() + addMonth,
                        day: month.dayInt
                    )
                    guard let currentDate = Calendar.current.date(from: currentDateComponents),
                          let movedStartDate = CalendarMath.moving(selectedEvent.startDate, toDay: currentDate),
                          let originalEndDate = selectedEvent.endDate else {
                        self.selectedEvent = nil
                        return false
                    }

                    let movedEndDate = originalEndDate.addingTimeInterval(
                        movedStartDate.timeIntervalSince(selectedEvent.startDate)
                    )
                    selectedEvent.startDate = movedStartDate
                    selectedEvent.endDate = movedEndDate
                    
                    Task {
                        try await eventManager.updateEvent(event: selectedEvent)
                    }
                    
                    self.selectedEvent = nil
                } else {
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
                    selectedEvent: $selectedEvent,
                    selectedReminder: $selectedReminder
                )
                .environmentObject(eventManager)
            }
        case .reminder:
            if let reminder = eventManager.reminder(withIdentifier: entry.sourceIdentifier) {
                ScheduledReminderLabelView(
                    reminder: reminder,
                    selectedEvent: $selectedEvent,
                    selectedReminder: $selectedReminder
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
        let currentDate = calendar.startOfDay(for: calculateDate(forMonthType: month.monthType))
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
    
    func calculateDate(forMonthType monthType: MonthType) -> Date {
        let date = calendarViewModel.stringToDate(
            year: calendarViewModel.year(),
            month: calendarViewModel.month(),
            day: month.dayInt
        )
        
        switch monthType {
        case .Previous:
            return Calendar.current.date(byAdding: .month, value: -1, to: date) ?? date
        case .Current:
            return date
        case .Next:
            return Calendar.current.date(byAdding: .month, value: 1, to: date) ?? date
        }
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
        selectedEvent: .constant(nil),
        selectedReminder: .constant(nil)
    )
    .environmentObject(EventStoreManager())
}
