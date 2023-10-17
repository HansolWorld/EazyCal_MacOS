//
//  CalendarCell.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import SwiftUI

struct CalendarCell: View {
    @ObservedObject var calendarViewModel: CalendarViewModel
    @State var isShow = false
    let count : Int
    let startingSpaces : Int
    let daysInMonth : Int
    let daysInPrevMonth : Int
    
    var body: some View {
        Text("\(monthStruct().dayInt)")
            .foregroundColor(textColor(type: monthStruct().monthType))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background {
                Color.white
            }
            .popover(isPresented: $isShow) {
                AddSchedulerView()
            }
            .onTapGesture(count: 2) {
                isShow.toggle()
            }
    }
    func textColor(type: MonthType) -> Color {
        return type == MonthType.Current ? Color.black : Color.gray
    }
    
    func monthStruct() -> Month {
        let start = startingSpaces == 0 ? startingSpaces + 7 : startingSpaces
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
}

#Preview {
    CalendarCell(calendarViewModel: CalendarViewModel(), count: 1, startingSpaces: 1, daysInMonth: 1, daysInPrevMonth: 1)
}
