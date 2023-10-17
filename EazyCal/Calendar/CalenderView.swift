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
                    .foregroundStyle(.white)
            }
            Text(calendarViewModel.monthYearString())
            Button(action: {
                nextMonth()
            }) {
                Image(systemName: SFSymbol.chevronForward.name)
                    .foregroundStyle(.white)
                    
            }
        }
        .font(.title)
        .foregroundStyle(.black)
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
        let previousMonth = calendarViewModel.previousMonth()
        let daysInPreviousMonth = calendarViewModel.daysInMonth(previousMonth)
        
        VStack {
            ForEach(0..<6) { row in
                HStack {
                    ForEach(1..<8) { column in
                        let count = column + (row * 7)
                        CalendarCell(
                            calendarViewModel: calendarViewModel,
                            count: count,
                            startingSpaces: staringSpacees,
                            daysInMonth: daysInMonth,
                            daysInPrevMonth: daysInPreviousMonth
                        )
                    }
                }
            }
        }
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
