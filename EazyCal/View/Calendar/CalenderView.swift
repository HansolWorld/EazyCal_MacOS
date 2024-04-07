//
//  CalenderView.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import SwiftUI
import SwiftData
import EventKit

struct CalenderView: View {
    @Binding var currentDragTemplate: Template?
    @State var mode = true
    @State var isShow = false
    @State var selectedEvent: EKEvent?
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @EnvironmentObject var eventManager: EventStoreManager
    
    @Environment(\.modelContext) private var context
    @Query(sort: \CalendarCategory.date, animation: .snappy) private var categories: [CalendarCategory]
    
    var body: some View {
        VStack {
            HStack {
                MonthButton
                Spacer()
            }
            VStack {
                DayOfWeek
                CalendarGrid
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .foregroundStyle(.white)
                            .onTapGesture {
                                selectedEvent = nil
                            }
                    }
            }
            .frame(maxHeight: .infinity)
        }
        .task {
            await listenForCalendarChanges()
        }
        .padding()
    }
    
    @ViewBuilder
    var MonthButton: some View {
        HStack(spacing: 20) {
            Button(action: {
                previousMonth()
                eventManager.date = calendarViewModel.date
                Task {
                    await eventManager.loadEvents()
                }
            }) {
                Image(systemName: SFSymbol.chevronBackward.name)
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundStyle(.gray300)
                    .padding(12)
                    .background {
                        Circle()
                            .foregroundStyle(Color.white)
                    }
            }
            .buttonStyle(.plain)
            
            Text(calendarViewModel.monthYearString())
                .font(.largeTitle)
                .foregroundStyle(.gray400)
            
            Button(action: {
                nextMonth()
                eventManager.date = calendarViewModel.date
                Task {
                    await eventManager.loadEvents()
                }
            }) {
                Image(systemName: SFSymbol.chevronForward.name)
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundStyle(.gray300)
                    .padding(12)
                    .background {
                        Circle()
                            .foregroundStyle(Color.white)
                    }
            }
            .buttonStyle(.plain)
            
            Button(action: {
                calendarViewModel.date = Date()
                eventManager.date = calendarViewModel.date
                Task {
                    await eventManager.loadEvents()
                }
            }) {
                Text("오늘")
                    .font(.body)
                    .foregroundStyle(.gray300)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background {
                        Capsule()
                            .foregroundStyle(.white)
                    }
            }
            .buttonStyle(.plain)
        }
    }
    
    @ViewBuilder
    var DayOfWeek: some View {
        HStack(spacing: 4) {
            Text("일")
                .foregroundStyle(.red)
                .padding(.leading, 6)
            Spacer()
            Text("월")
                .foregroundStyle(.black)
                .padding(.leading, 6)
            Spacer()
            Text("화")
                .foregroundStyle(.black)
                .padding(.leading, 6)
            Spacer()
            Text("수")
                .foregroundStyle(.black)
                .padding(.leading, 6)
            Spacer()
            Text("목")
                .foregroundStyle(.black)
                .padding(.leading, 6)
            Spacer()
            Text("금")
                .foregroundStyle(.black)
                .padding(.leading, 6)
            Spacer()
            Text("토")
                .foregroundStyle(.black)
                .padding(.leading, 6)
            Spacer()
        }
    }
    
    @ViewBuilder
    var CalendarGrid: some View {
        let daysInMonth = calendarViewModel.daysInMonth(nil)
        let firstOfDay = calendarViewModel.firstOfMonth()
        let staringSpacees = calendarViewModel.weekDay(firstOfDay)
        let start = staringSpacees == 0 ? staringSpacees + 7 : staringSpacees
        let previousMonth = calendarViewModel.previousMonth()
        let daysInPreviousMonth = calendarViewModel.daysInMonth(previousMonth)
        let schedules = calendarViewModel.calculateSchedulesLayers(schedules: eventManager.events)
        let categoriedCalendar: [String] = categories[2...].flatMap { $0.calendars }
        let categorySchedules = schedules.filter {
            if let category = categories.first(where: { $0.isSelected == true} ) {
                if category.title == "전체" {
                    return true
                } else if category.title == "미등록" {
                    return !categoriedCalendar.contains( $0.0.calendar.calendarIdentifier)
                } else {
                    return category.calendars.contains($0.0.calendar.calendarIdentifier)
                }
            }
            
            return false
        }
        
        VStack(spacing: 0) {
            ForEach(0..<6) { row in
                HStack(spacing: 0) {
                    ForEach(1..<8) { column in
                        let count = column + (row * 7)
                        
                        let month = monthStruct(
                            count: count,
                            start: start,
                            daysInMonth: daysInMonth,
                            daysInPrevMonth: daysInPreviousMonth
                        )
                    
                        CalendarCell(
                            schedules: calendarViewModel.schedules(
                                monthStruct: month,
                                year: calendarViewModel.year(),
                                month: calendarViewModel.month(),
                                scheduler: categorySchedules
                            ),
                            month: month,
                            isToday: checkToday(count: count, start: start),
                            count: count,
                            start: start,
                            daysInMonth: daysInMonth,
                            daysInPrevMonth: daysInPreviousMonth,
                            calendarViewModel: calendarViewModel,
                            currentDragTemplate: $currentDragTemplate,
                            selectedEvent: $selectedEvent
                        )
                        if column != 7 {
                            Divider()
                                .frame(width: 1)
                                .overlay(Color.calendarLine)
                        }   
                    }
                }
                if row != 5 {
                    Divider()
                        .frame(height: 1)
                        .overlay(Color.calendarLine)
                }
            }
        }
    }
    
    func checkToday(count: Int, start: Int) -> Bool {
        let calendar = Calendar.current
        
        let currentDate = Date()
        let currentYear = calendar.component(.year, from: currentDate)
        let currentMonth = calendar.component(.month, from: currentDate)
        let currentDay = calendar.component(.day, from: currentDate)
        
        let viewYear = calendarViewModel.year()
        let viewMonth = calendarViewModel.month()
        let viewDay = count - start
        
        return  currentYear == viewYear && currentMonth == viewMonth && currentDay == viewDay
    }
    
    func monthStruct(count: Int, start: Int, daysInMonth: Int, daysInPrevMonth: Int) -> Month {
        if(count <= start) {
            let day = daysInPrevMonth + count - start
            return Month(monthType: MonthType.Previous, dayInt: day)
        } else if (count - start > daysInMonth) {
            let day = count - start - daysInMonth
            return Month(monthType: MonthType.Next, dayInt: day)
        }
        
        let day = count - start
        return Month(monthType: MonthType.Current, dayInt: day)
    }
    
    func previousMonth() {
        calendarViewModel.minusMonth()
    }
    
    func nextMonth() {
        calendarViewModel.plusMonth()
    }
    
    func listenForCalendarChanges() async {
        let center = NotificationCenter.default
        let notifications = center.notifications(named: .EKEventStoreChanged).map({ (notification: Notification) in notification.name })

        guard eventManager.eventStore.isFullAccessAuthorized else { return }
        for await _ in notifications {
            await eventManager.loadCalendar()
            await eventManager.loadEvents()
            await eventManager.loadReminder()
            await eventManager.loadUpcommingEvents()
        }
    }
}

#Preview {
    CalenderView(currentDragTemplate: .constant(nil))
        .environmentObject(CalendarViewModel())
}
