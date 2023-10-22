//
//  CalenderView.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import SwiftUI

struct CalenderView: View {
    @StateObject var calendarViewModel = CalendarViewModel()
    @State var mode = true
    @State var isShow = false
    
    var body: some View {
        VStack {
            HStack {
                MonthButton
                Spacer()
                Toggle(isOn: $mode) {
                    EmptyView()
                }
                .toggleStyle(.switch)
            }
            .padding(.bottom, 27)
            VStack {
                DayOfWeek
                CalendarGrid
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .foregroundStyle(.white)
                    }
            }
        }
        .padding()
    }
    
    @ViewBuilder
    var MonthButton: some View {
        HStack(spacing: 16) {
            Button(action: {
                previousMonth()
            }) {
                Image(systemName: SFSymbol.chevronBackward.name)
                    .font(CustomTextStyle.title.font)
                    .tint(Color.white)
                    .background{
                        Circle()
                            .foregroundStyle(Color.gray300)
                            .scaleEffect(0.8)
                    }
            }
            Text(calendarViewModel.monthYearString())
                .customStyle(.title)
                .foregroundStyle(.black)
            Button(action: {
                nextMonth()
            }) {
                Image(systemName: SFSymbol.chevronForward.name)
                    .font(CustomTextStyle.title.font)
                    .tint(Color.white)
                    .background{
                        Circle()
                            .foregroundStyle(Color.gray300)
                            .scaleEffect(0.8)
                    }
            }
        }
    }
    
    @ViewBuilder
    var DayOfWeek: some View {
        HStack(spacing: 1) {
            Text("일")
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity)
            Text("월")
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
            Text("화")
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
            Text("수")
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
            Text("목")
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
            Text("금")
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
            Text("토")
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
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
        let schedules = calendarViewModel.calculateSchedulesLayers()
        
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
                            calendarViewModel: calendarViewModel,
                            schedules: 
                                calendarViewModel.schedules(
                                    monthStruct: month,
                                    year: calendarViewModel.year(),
                                    month: calendarViewModel.month(),
                                    scheduler: schedules
                                ),
                            month: month,
                            isToday:
                                checkToday(
                                    count: count,
                                    start: start
                                ),
                            count: count,
                            start: start,
                            daysInMonth: daysInMonth,
                            daysInPrevMonth: daysInPreviousMonth
                        )
                        
                        if column != 7 {
                            Divider()
                        }
                    }
                }
                if row != 5 {
                    Divider()
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
    CalenderView()
}
