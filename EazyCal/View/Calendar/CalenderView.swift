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
    @Binding var isSide: Bool
    @State var mode = true
    @State var isShow = false
    @State var selectedEvent: EKEvent?
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @EnvironmentObject var eventManager: EventStoreManager
    
    @Environment(\.modelContext) private var context
    @Query(sort: \CalendarCategory.date, animation: .snappy) private var categories: [CalendarCategory]
    
    var body: some View {
        VStack(spacing: 19) {
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
        .padding(.top, 29)
        .padding([.bottom, .horizontal], 23)
    }
    
    @ViewBuilder
    var MonthButton: some View {
        HStack(spacing: 15) {
            Button(action: {
                withAnimation {
                    isSide.toggle()
                }
            }) {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(isSide ? Color.calendarBlue : Color.gray300)
                    .padding(7)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSide ? Color.calendarBlue.opacity(0.1) : Color.white)
                    }
            }
            .buttonStyle(.plain)
            
            Button(action: {
                previousMonth()
                eventManager.date = calendarViewModel.date
                Task {
                    do {
                        try await eventManager.loadEvents()
                    } catch {
                        print(error)
                    }
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
                    do {
                        try await eventManager.loadEvents()
                    } catch {
                        print(error)
                    }
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
                    do {
                        try await eventManager.loadEvents()
                    } catch {
                        print(error)
                    }
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
        let categoriedCalendar: [String] = categories[2...].flatMap { $0.calendars }
        let categorySchedules = eventManager.events.filter {
            if let category = categories.first(where: { $0.isSelected == true} ) {
                if category.title == "전체" {
                    return true
                } else if category.title == "미등록" {
                    return !categoriedCalendar.contains($0.calendar?.calendarIdentifier ?? "")
                } else {
                    return category.calendars.contains($0.calendar?.calendarIdentifier ?? "")
                }
            }
            
            return false
        }
        
        let schedules = calendarViewModel.calculateSchedulesLayers(schedules: categorySchedules)

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
                                scheduler: schedules
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
}

#Preview {
    CalenderView(currentDragTemplate: .constant(nil), isSide: .constant(false))
        .environmentObject(CalendarViewModel())
}
