//
//  CalendarView.swift
//  EazyCal
//

import EventKit
import SwiftUI

struct CalendarView: View {
    @Binding var currentDragTemplate: Template?
    @Binding var isSide: Bool
    @State private var selectedEvent: EKEvent?
    @State private var selectedReminder: EKReminder?
    @EnvironmentObject private var calendarViewModel: CalendarViewModel

    var body: some View {
        VStack(spacing: 19) {
            CalendarHeaderView(
                isSide: $isSide,
                calendarViewModel: calendarViewModel
            )

            VStack {
                CalendarWeekdayHeaderView()
                CalendarGridView(
                    calendarViewModel: calendarViewModel,
                    currentDragTemplate: $currentDragTemplate,
                    selectedEvent: $selectedEvent,
                    selectedReminder: $selectedReminder
                )
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .foregroundStyle(.white)
                        .onTapGesture {
                            selectedEvent = nil
                            selectedReminder = nil
                        }
                }
            }
            .frame(maxHeight: .infinity)
        }
        .padding(.top, 29)
        .padding([.bottom, .horizontal], 23)
    }
}

#Preview {
    CalendarView(currentDragTemplate: .constant(nil), isSide: .constant(false))
        .environmentObject(CalendarViewModel())
        .environmentObject(EventStoreManager())
}
