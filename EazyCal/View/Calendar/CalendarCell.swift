//
//  CalendarCell.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import SwiftUI
import EventKit

struct CalendarCell: View {
    let schedules: [(EKEvent, Int)]
    let month: Month
    let isToday: Bool
    let count : Int
    let start : Int
    let daysInMonth : Int
    let daysInPrevMonth : Int
    @State private var isHover = false
    @ObservedObject var calendarViewModel: CalendarViewModel
    @Binding var currentDragTemplate: Template?
    @Binding var selectedEvent: EKEvent?
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
                        .padding(8)
                        .background {
                            Circle()
                                .fill(isToday ? Color.calendarBlue : Color.clear)
                        }
                        .padding([.top, .leading], 4)
                }
                
                ForEach(0...max(taskViewCount-2, 0), id: \.self) { index in
                    if let scheduleTuple = schedules.first(where: { $0.1 == index+1 }) {
                        CalendarCategoryLabelView(
                            schedule: scheduleTuple.0,
                            viewType: cellViewType(scheduleTuple.0, month),
                            selectedEvent: $selectedEvent
                        )
                        .environmentObject(eventManager)
                    } else {
                        Text(" ")
                            .font(.body)
                            .padding(2)
                    }
                }
                
                let notViewTask = schedules.filter({ $0.1 > (taskViewCount - 1) })
                if notViewTask.count != 0 {
                    Text("+\(notViewTask.count)개의 일정")
                        .font(.body)
                        .foregroundStyle(Color.gray300)
                        .padding(.horizontal, 6)
                        .padding(.bottom, 4)
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
            .onDrop(of: [.text], isTargeted: $isHover, perform: { providers in
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
                    
                    let startDate = calendar.date(from: startComponents)
                    let endDate = calendar.date(from: endComponents)
                    
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
                    let currentDate = Calendar.current.date(from: currentDateComponents)!
                    let offsetComps = Calendar.current.dateComponents([.day], from: selectedEvent.startDate, to: currentDate)
                    
                    selectedEvent.startDate = Calendar.current.date(byAdding: .day, value:  offsetComps.day!, to: selectedEvent.startDate)
                    selectedEvent.endDate = Calendar.current.date(byAdding: .day, value:  offsetComps.day!, to: selectedEvent.endDate)
                    
                    Task {
                        try await eventManager.updateEvent(ekEvent: selectedEvent)
                    }
                    
                    self.selectedEvent = nil
                } else {
                }
                return true
            })
        }
        .frame(minWidth: 80, minHeight: 80)
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
    
    func day(date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: date)
        return components.day ?? -1
    }
    
    func cellViewType(_ schedule: EKEvent, _ month: Month) -> CellViewType {
        let endDate = Calendar.current.date(byAdding: .second, value: -1, to: schedule.endDate) ?? schedule.endDate!
        
        if (day(date: schedule.startDate) == month.dayInt) && (day(date: endDate) == month.dayInt) {
            return .OneDate
        } else if day(date: schedule.startDate) == month.dayInt {
            return .StartDate
        } else if day(date: schedule.endDate) == month.dayInt {
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
        selectedEvent: .constant(nil)
    )
    .environmentObject(EventStoreManager())
}
