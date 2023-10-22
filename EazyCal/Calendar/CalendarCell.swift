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
    let schedules: [(Schedule, Int)]
    let month: Month
    let isToday: Bool
    let count : Int
    let start : Int
    let daysInMonth : Int
    let daysInPrevMonth : Int
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(month.dayInt)")
                .customStyle(.date)
                .foregroundColor(textColor(type: month.monthType))
                .padding(4)
                .background {
                    if self.isToday {
                        Circle()
                            .fill(Color.blue)
                    }
                }
            
            ForEach(1...4, id: \.self) { index in
                if let scheduleTuple = schedules.first(where: { $0.1 == index }) { // index =1 [(schedule1, 1), (schedule2, 4)]
                    
                    if day(date: scheduleTuple.0.startDate) == month.dayInt && day(date: scheduleTuple.0.doDate) == month.dayInt {
                        CalendarCategoryLabelView(title: scheduleTuple.0.title, color: scheduleTuple.0.category.color)
                            .font(CustomTextStyle.body2.font)
                            .padding(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background {
                                Rectangle()
                                    .fill(Color(scheduleTuple.0.category.color))
                                    .opacity(0.1)
                                    .cornerRadius(8, corners: .topLeft)
                                    .cornerRadius(8, corners: .topRight)
                                    .cornerRadius(8, corners: .bottomLeft)
                                    .cornerRadius(8, corners: .bottomRight)
                            }
                    }
                    else if day(date: scheduleTuple.0.startDate) == month.dayInt {
                        CalendarCategoryLabelView(title: scheduleTuple.0.title, color: scheduleTuple.0.category.color)
                            .font(CustomTextStyle.body2.font)
                            .padding(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background {
                                Rectangle()
                                    .fill(Color(scheduleTuple.0.category.color))
                                    .opacity(0.1)
                                    .cornerRadius(8, corners: .topLeft)
                                    .cornerRadius(8, corners: .bottomLeft)
                            }
                    } else if day(date: scheduleTuple.0.doDate) == month.dayInt {
                        Text(" ")
                            .customStyle(.body)
                            .padding(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background {
                                Rectangle()
                                    .fill(Color(scheduleTuple.0.category.color))
                                    .opacity(0.1)
                                    .cornerRadius(8, corners: .topRight)
                                    .cornerRadius(8, corners: .bottomRight)
                            }
                    } else {
                        Text(" ")
                            .customStyle(.body)
                            .padding(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background {
                                Rectangle()
                                    .fill(Color(scheduleTuple.0.category.color))
                                    .opacity(0.1)
                            }
                        
                    }
                    

                } else {
                    Text(" ")
                        .customStyle(.body)
                        .padding(4)
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            Color.white
                .onTapGesture(count: 2) {
                    isShow.toggle()
                }
        }
        .popover(isPresented: $isShow) {
            ZStack {
                Color.white
                    .scaleEffect(1.5)
                AddSchedulerView(
                    startDate:
                        calendarViewModel.stringToDate(
                            year: calendarViewModel.year(),
                            month: calendarViewModel.month(),
                            day: month.dayInt
                        ),
                    doDate: calendarViewModel.stringToDate(
                        year: calendarViewModel.year(),
                        month: calendarViewModel.month(),
                        day: month.dayInt
                    )
                )
            }
        }
    }
    
    
    func textColor(type: MonthType) -> Color {
        return type == MonthType.Current ? self.isToday ? Color.white : Color.black : Color.gray
    }
    
    func day(date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: date)
        return components.day ?? -1
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {

    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

#Preview {
    CalendarCell(calendarViewModel: CalendarViewModel(), schedules: [], month: Month(monthType: .Current, dayInt: 1), isToday: false, count: 1, start: 1, daysInMonth: 1, daysInPrevMonth: 1)
}
