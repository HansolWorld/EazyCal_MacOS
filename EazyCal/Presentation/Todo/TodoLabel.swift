import SwiftUI

struct TodoLabel: View {
    @State private var isComplete = false
    @State var editTodo: String
    @State var newPriority: String
    @State private var lastButtonPressTime: Date?
    @Binding var todo: ReminderItem
    @Binding var selectedId: String
    @FocusState private var isFocus: Bool
    @EnvironmentObject private var eventManager: EventStoreManager

    var body: some View {
        VStack {
            HStack(spacing: 8) {
                completionButton

                HStack(spacing: 4) {
                    if !priorityMark.isEmpty {
                        Text(priorityMark)
                            .font(.body)
                            .foregroundStyle(.red)
                    }

                    TextField(String(localized: "REMINDER_EDIT"), text: $editTodo)
                        .font(.body)
                        .foregroundStyle(.black)
                        .strikethrough(todo.isCompleted)
                        .textFieldStyle(.plain)
                        .focused($isFocus)
                        .onChange(of: editTodo) { _, newValue in
                            todo.title = newValue
                            updateReminder()
                        }
                        .onChange(of: isFocus) { _, isFocused in
                            if isFocused {
                                withAnimation {
                                    selectedId = todo.id
                                }
                            }
                        }

                    Spacer()
                    Text(relativeDueDateText)
                        .font(.caption)
                        .foregroundStyle(.gray300)
                }
            }

            if selectedId == todo.id {
                ReminderMetadataEditor(reminder: $todo, priority: $newPriority)
                    .environmentObject(eventManager)
            }
        }
    }

    private var completionButton: some View {
        Button {
            withAnimation {
                isComplete.toggle()
                lastButtonPressTime = Date()

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    guard isComplete,
                          let lastButtonPressTime,
                          Date().timeIntervalSince(lastButtonPressTime) >= 1.5 else { return }
                    Task {
                        try await eventManager.completeReminder(identifier: todo.id)
                    }
                }
            }
        } label: {
            Image(systemName: isComplete ? SFSymbol.checkCircle.name : SFSymbol.circle.name)
                .resizable()
                .scaledToFit()
                .frame(width: 12, height: 12)
                .foregroundStyle(.gray300)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var priorityMark: String {
        if (6...9).contains(todo.priority) {
            "!"
        } else if todo.priority == 5 {
            "!!"
        } else if (1...4).contains(todo.priority) {
            "!!!"
        } else {
            ""
        }
    }

    private var relativeDueDateText: String {
        guard let date = todo.dueDateComponents?.date else { return " " }

        let calendar = Calendar.current
        let todayComponents = calendar.dateComponents(
            [.calendar, .era, .year, .month, .day, .hour],
            from: Date()
        )
        guard let today = todayComponents.date else { return "" }
        let components = calendar.dateComponents(
            [.day, .hour],
            from: today,
            to: date
        )
        guard let daysDifference = components.day,
              let hourDifference = components.hour else { return "" }

        if daysDifference < 0 {
            return String(localized: "\(abs(daysDifference)) PAST_DATE")
        } else if daysDifference == 0 {
            if hourDifference > 0 {
                return String(localized: "\(hourDifference) BEFORE_TIME")
            }
            return String(localized: "\(abs(hourDifference)) PAST_TIME")
        }
        return String(localized: "\(daysDifference) BEFORE_DATE")
    }

    private func updateReminder() {
        Task {
            try await eventManager.updateReminder(reminder: todo)
        }
    }
}

#Preview {
    TodoLabel(
        editTodo: "",
        newPriority: "기본",
        todo: .constant(
            ReminderItem(
                id: "preview",
                title: "Preview",
                priority: 0,
                dueDateComponents: nil,
                isCompleted: false,
                color: .clear
            )
        ),
        selectedId: .constant("")
    )
    .environmentObject(EventStoreManager())
}
