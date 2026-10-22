import SwiftUI

struct ReminderMetadataEditor: View {
    @Binding var reminder: ReminderItem
    @Binding var priority: ReminderPriority

    @State private var dueDate = Date()
    @State private var isDatePickerPresented = false
    @State private var isPriorityPickerPresented = false
    @EnvironmentObject private var eventManager: EventStoreManager

    var body: some View {
        HStack(spacing: 8) {
            Button {
                isDatePickerPresented = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                    if reminder.dueDateComponents?.date != nil {
                        Text(dueDate, style: .date)
                    } else {
                        Text(String(localized: "DATE_ADD"))
                    }
                }
                .optionStyle()
            }
            .buttonStyle(.plain)
            .popover(isPresented: $isDatePickerPresented) {
                HStack {
                    Text(String(localized: "DATE"))
                        .foregroundStyle(Color.calendarBlack)
                        .font(.body)
                    DatePicker("", selection: $dueDate)
                        .font(.body)
                        .labelsHidden()
                        .foregroundStyle(Color.gray400)
                        .onChange(of: dueDate) { _, newValue in
                            reminder.dueDateComponents = Calendar.current.dateComponents(
                                [.year, .month, .day, .hour, .minute],
                                from: newValue
                            )
                            updateReminder()
                        }
                }
                .padding(.horizontal, 8)
                .background {
                    Color.white.scaleEffect(1.5)
                }
            }

            Button {
                isPriorityPickerPresented = true
            } label: {
                HStack(spacing: 4) {
                    Text(priority.symbol)
                    Text(priority.localizedTitle)
                }
                .optionStyle()
            }
            .buttonStyle(.plain)
            .popover(isPresented: $isPriorityPickerPresented) {
                VStack(spacing: 4) {
                    ForEach(ReminderPriority.allCases, id: \.self) { option in
                        Button {
                            priority = option
                            isPriorityPickerPresented = false
                        } label: {
                            Text(option.localizedTitle)
                                .font(.body)
                                .foregroundStyle(priority == option ? .white : .gray400)
                                .padding(4)
                                .background {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(priority == option ? Color.primaryBlue : Color.clear)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(4)
                .background {
                    Color.white.scaleEffect(1.5)
                }
            }
            .onChange(of: priority) { _, newValue in
                reminder.priority = newValue
                updateReminder()
            }
        }
        .onAppear {
            if let date = reminder.dueDateComponents?.date {
                dueDate = date
            }
        }
    }

    private func updateReminder() {
        Task {
            try await eventManager.updateReminder(reminder: reminder)
        }
    }
}

private extension View {
    func optionStyle() -> some View {
        font(.subheadline)
            .foregroundStyle(Color.gray400)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray400)
                    .opacity(0.1)
            }
    }
}
