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
                
                CalendarEntryListView(
                    schedules: schedules,
                    visibleRowCount: taskViewCount,
                    cellDate: cellDate,
                    selectedEventIdentifier: $selectedEventIdentifier,
                    selectedReminderIdentifier: $selectedReminderIdentifier
                )
                .environmentObject(eventManager)
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
