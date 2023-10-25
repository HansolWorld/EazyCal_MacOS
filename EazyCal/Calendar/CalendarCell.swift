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
    @ObservedObject var calendarViewModel: CalendarViewModel
    @EnvironmentObject var eventStore: EventStore
    
    @State var isShow = false
    
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(month.dayInt)")
                .customStyle(.date)
                .foregroundColor(count % 7 == 1 ? Color.calendarRed : textColor(type: month.monthType))
                .padding(4)
                .background {
                    if self.isToday {
                        Circle()
                            .fill(Color.calendarBlue)
                    }
                }
            Spacer()
            
            ForEach(1...4, id: \.self) { index in
                if let scheduleTuple = schedules.first(where: { $0.1 == index }) {
                    if (day(date: scheduleTuple.0.startDate) == month.dayInt) && (day(date: scheduleTuple.0.endDate) == month.dayInt) {
                        CalendarCategoryLabelView(title: scheduleTuple.0.title, color: scheduleTuple.0.calendar.cgColor)
                            .font(CustomTextStyle.body2.font)
                            .padding(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background {
                                if scheduleTuple.0.isAllDay {
                                    Rectangle()
                                        .fill(Color(cgColor: scheduleTuple.0.calendar.cgColor))
                                        .opacity(0.1)
                                        .cornerRadius(8, corners: .topLeft)
                                        .cornerRadius(8, corners: .topRight)
                                        .cornerRadius(8, corners: .bottomLeft)
                                        .cornerRadius(8, corners: .bottomRight)
                                }
                            }
                    } else if day(date: scheduleTuple.0.startDate) == month.dayInt {
                        CalendarCategoryLabelView(title: scheduleTuple.0.title, color: scheduleTuple.0.calendar.cgColor)
                            .font(CustomTextStyle.body2.font)
                            .padding(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background {
                                if scheduleTuple.0.isAllDay {
                                    Rectangle()
                                        .fill(Color(cgColor: scheduleTuple.0.calendar.cgColor))
                                        .opacity(0.1)
                                        .cornerRadius(8, corners: .topLeft)
                                        .cornerRadius(8, corners: .bottomLeft)
                                }
                            }
                    } else if day(date: scheduleTuple.0.endDate) == month.dayInt {
                        Text(" ")
                            .customStyle(.body)
                            .padding(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background {
                                if scheduleTuple.0.isAllDay {
                                    Rectangle()
                                        .fill(Color(cgColor: scheduleTuple.0.calendar.cgColor))
                                        .opacity(0.1)
                                        .cornerRadius(8, corners: .topRight)
                                        .cornerRadius(8, corners: .bottomRight)
                                }
                            }
                    } else {
                        Text(" ")
                            .customStyle(.body)
                            .padding(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background {
                                if scheduleTuple.0.isAllDay {
                                    Rectangle()
                                        .fill(Color(cgColor: scheduleTuple.0.calendar.cgColor))
                                        .opacity(0.1)
                                }
                            }
                    }
                } else {
                    Text(" ")
                        .customStyle(.body)
                        .padding(4)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
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
                    ),
                    categories: eventStore.calendaries,
                    category: eventStore.calendaries.first ?? EKCalendar(),
                    calendarViewModel: calendarViewModel
                )
            }
        }
    }
    
    func textColor(type: MonthType) -> Color {
        if type == MonthType.Current {
            if self.isToday {
                return Color.white
            } else {
                return Color.calendarBlack
            }
        } else {
            return Color.gray
        }
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
    CalendarCell(schedules: [], month: Month(monthType: .Current, dayInt: 1), isToday: true, count: 1, start: 1, daysInMonth: 1, daysInPrevMonth: 1, calendarViewModel: CalendarViewModel())
}
