import SwiftUI

struct CalendarEntryListView: View {
    let schedules: [LayeredCalendarEntry]
    let visibleRowCount: Int
    let cellDate: Date
    @Binding var selectedEventIdentifier: String?
    @Binding var selectedReminderIdentifier: String?

    @State private var isOverflowPresented = false
    @EnvironmentObject private var eventManager: EventStoreManager

    var body: some View {
        ForEach(0...max(visibleRowCount - 2, 0), id: \.self) { index in
            if let schedule = schedules.first(where: { $0.layer == index + 1 }) {
                entryLabel(schedule.entry, viewType: cellViewType(schedule.entry))
            } else {
                Text(" ")
                    .font(.body)
                    .padding(2)
            }
        }

        if !overflowSchedules.isEmpty {
            Text(String(localized: "+\(overflowSchedules.count) EVENT_COUNT"))
                .font(.body)
                .foregroundStyle(Color.gray300)
                .padding(.horizontal, 6)
                .padding(.bottom, 4)
                .onTapGesture {
                    isOverflowPresented = true
                }
                .popover(isPresented: $isOverflowPresented, arrowEdge: .trailing) {
                    VStack(alignment: .leading) {
                        ForEach(schedules) { schedule in
                            entryLabel(schedule.entry, viewType: .OneDate)
                        }
                    }
                    .padding(4)
                    .background {
                        Color.white.scaleEffect(1.5)
                    }
                }
        }
    }

    private var overflowSchedules: [LayeredCalendarEntry] {
        schedules.filter { $0.layer > (visibleRowCount - 1) }
    }

    @ViewBuilder
    private func entryLabel(_ entry: CalendarEntry, viewType: CellViewType) -> some View {
        switch entry.kind {
        case .event:
            if let event = eventManager.event(withIdentifier: entry.sourceIdentifier) {
                CalendarCategoryLabelView(
                    schedule: event,
                    viewType: viewType,
                    selectedEventIdentifier: $selectedEventIdentifier,
                    selectedReminderIdentifier: $selectedReminderIdentifier
                )
                .environmentObject(eventManager)
            }
        case .reminder:
            if let reminder = eventManager.reminder(withIdentifier: entry.sourceIdentifier) {
                ScheduledReminderLabelView(
                    reminder: reminder,
                    selectedEventIdentifier: $selectedEventIdentifier,
                    selectedReminderIdentifier: $selectedReminderIdentifier
                )
                .environmentObject(eventManager)
            }
        }
    }

    private func cellViewType(_ entry: CalendarEntry) -> CellViewType {
        guard entry.kind == .event else { return .OneDate }

        let calendar = Calendar.current
        let currentDate = calendar.startOfDay(for: cellDate)
        let startDate = calendar.startOfDay(for: entry.startDate)
        let endDate = calendar.startOfDay(for: entry.endDate)

        if startDate == currentDate && endDate == currentDate {
            return .OneDate
        } else if startDate == currentDate {
            return .StartDate
        } else if endDate == currentDate {
            return .DoDate
        } else {
            return .Dating
        }
    }
}
