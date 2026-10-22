import SwiftUI

struct TodoView: View {
    @State private var selectedReminderIdentifier = ""
    @EnvironmentObject private var eventManager: EventStoreManager

    var body: some View {
        VStack(spacing: 24) {
            todoSection(title: IndexCategory.readyTodo.title, usesCardBackground: false) {
                ForEach($eventManager.upcomingEvents) { $schedule in
                    if schedule.notes.contains("☐") {
                        ScheduleTodoCellView(schedule: $schedule)
                            .environmentObject(eventManager)
                    }
                }
            }

            todoSection(title: IndexCategory.todo.title, usesCardBackground: true) {
                ForEach($eventManager.reminders) { $reminder in
                    TodoLabel(
                        editTodo: reminder.title,
                        priority: reminder.priority,
                        todo: $reminder,
                        selectedId: $selectedReminderIdentifier
                    )
                    .environmentObject(eventManager)
                }

                NewReminderComposer(selectedReminderIdentifier: $selectedReminderIdentifier)
                    .environmentObject(eventManager)
            }
        }
        .padding()
    }

    private func todoSection<Content: View>(
        title: String,
        usesCardBackground: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 15) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.gray300)
                Spacer()
            }
            ScrollView {
                if usesCardBackground {
                    VStack(spacing: 16) {
                        content()
                    }
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 12).fill(Color.background)
                    }
                } else {
                    VStack(spacing: 16) {
                        content()
                    }
                    .padding(.bottom, 24)
                }
            }
        }
    }

}

#Preview {
    TodoView()
        .environmentObject(EventStoreManager())
}
