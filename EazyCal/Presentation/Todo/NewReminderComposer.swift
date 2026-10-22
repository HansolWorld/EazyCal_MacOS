import SwiftUI

struct NewReminderComposer: View {
    @Binding var selectedReminderIdentifier: String

    @State private var title = ""
    @State private var priority: ReminderPriority = .none
    @State private var isPriorityPickerPresented = false
    @State private var dueDate = Date()
    @State private var includesDueDate = false
    @State private var isDatePickerPresented = false
    @FocusState private var isTitleFocused: Bool
    @EnvironmentObject private var eventManager: EventStoreManager

    var body: some View {
        VStack {
            HStack {
                Image(systemName: SFSymbol.circle.name)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                    .foregroundStyle(.gray300)

                TextField(String(localized: "NEW_REMINDER"), text: $title)
                    .font(.body)
                    .foregroundStyle(Color.gray400)
                    .textFieldStyle(.plain)
                    .focused($isTitleFocused)
                    .onSubmit(createReminder)
                    .onChange(of: isTitleFocused) { _, isFocused in
                        if isFocused {
                            withAnimation {
                                selectedReminderIdentifier = ""
                            }
                        }
                    }
            }

            HStack(spacing: 8) {
                dueDateButton
                priorityButton
            }
        }
    }

    private var dueDateButton: some View {
        Button {
            includesDueDate.toggle()
            isDatePickerPresented = includesDueDate
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                Text(includesDueDate ? String(localized: "DATE_DELETE") : String(localized: "DATE_ADD"))
            }
            .reminderOptionStyle()
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
            }
            .padding(.horizontal, 8)
            .background {
                Color.white.scaleEffect(1.5)
            }
        }
    }

    private var priorityButton: some View {
        Button {
            isPriorityPickerPresented = true
        } label: {
            HStack(spacing: 4) {
                Text("!")
                Text(String(localized: "RANKING"))
            }
            .reminderOptionStyle()
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
    }

    private func createReminder() {
        guard !title.isEmpty else { return }

        Task {
            do {
                try await eventManager.createNewReminder(
                    title: title,
                    date: includesDueDate ? dueDate : nil,
                    priority: priority
                )
                title = ""
                priority = .none
                includesDueDate = false
            } catch {
                return
            }
        }
    }
}

private extension View {
    func reminderOptionStyle() -> some View {
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
