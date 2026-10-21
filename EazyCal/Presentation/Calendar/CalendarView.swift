//
//  CalendarView.swift
//  EazyCal
//

import SwiftUI

struct CalendarView: View {
    @Binding var currentDragTemplate: Template?
    @Binding var isSide: Bool
    @State private var selectedEventIdentifier: String?
    @State private var selectedReminderIdentifier: String?
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
                    selectedEventIdentifier: $selectedEventIdentifier,
                    selectedReminderIdentifier: $selectedReminderIdentifier
                )
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .foregroundStyle(.white)
                        .onTapGesture {
                            selectedEventIdentifier = nil
                            selectedReminderIdentifier = nil
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
