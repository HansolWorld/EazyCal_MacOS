//
//  ScheduledReminderLabelView.swift
//  EazyCal
//

import EventKit
import SwiftUI

struct ScheduledReminderLabelView: View {
    let reminder: EKReminder
    @Binding var selectedEvent: EKEvent?
    @Binding var selectedReminder: EKReminder?
    @EnvironmentObject private var eventManager: EventStoreManager

    private var tintColor: Color {
        guard let color = reminder.calendar?.cgColor else {
            return .calendarBlue
        }
        return Color(cgColor: color)
    }

    private var isSelected: Bool {
        selectedReminder == reminder
    }

    var body: some View {
        HStack(spacing: 5) {
            Button {
                Task {
                    try await eventManager.completeReminder(reminder: reminder)
                    selectedReminder = nil
                }
            } label: {
                Image(systemName: "circle")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.white : tintColor)
            }
            .buttonStyle(.plain)
            .help(String(localized: "COMPLETE_REMINDER"))

            Text(reminder.title ?? "")
                .font(.callout)
                .foregroundStyle(isSelected ? Color.white : Color.black)
                .lineLimit(1)
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(tintColor)
                .opacity(isSelected ? 1 : 0.12)
                .padding(.horizontal, 4)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                selectedEvent = nil
                selectedReminder = reminder
            }
        }
        .onDrag {
            selectedEvent = nil
            selectedReminder = reminder
            return NSItemProvider(object: reminder.calendarItemIdentifier as NSString)
        }
        .contextMenu {
            Button(String(localized: "COMPLETE_REMINDER")) {
                Task {
                    try await eventManager.completeReminder(reminder: reminder)
                    selectedReminder = nil
                }
            }
        }
    }
}
