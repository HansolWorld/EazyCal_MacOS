import SwiftUI

struct TemplateEditorView: View {
    @Binding var title: String
    @Binding var isAllDay: Bool
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var calendar: CalendarItem
    @Binding var todos: [String]

    @State private var newTodo = ""
    @EnvironmentObject private var eventManager: EventStoreManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField(String(localized: "TEMPLATE_DEFAULT_TITLE"), text: $title)
                .font(.title3)
                .foregroundStyle(Color.gray400)
                .textFieldStyle(.plain)

            VStack(alignment: .leading) {
                HStack {
                    Text(String(localized: "ALL_DAY"))
                        .font(.body)
                        .foregroundStyle(Color.gray400)
                    Spacer()
                    Toggle("", isOn: $isAllDay)
                        .foregroundStyle(Color.gray200)
                        .toggleStyle(BackgroundToggleStyle())
                        .labelsHidden()
                }

                if !isAllDay {
                    timePicker(title: String(localized: "START"), selection: $startDate)
                    timePicker(title: String(localized: "END"), selection: $endDate)
                }

                CustomPicker(
                    title: String(localized: "CATEGORY"),
                    categoryList: eventManager.calendars,
                    selected: $calendar
                )

                Text(String(localized: "REMINDER"))
                    .font(.body)
                    .foregroundStyle(Color.gray400)

                ForEach(todos.indices, id: \.self) { index in
                    todoField(text: $todos[index])
                }

                todoField(text: $newTodo, prompt: String(localized: "NEW_REMINDER"))
                    .onSubmit {
                        guard !newTodo.isEmpty else { return }
                        todos.append(newTodo)
                        newTodo = ""
                    }
            }
            .frame(width: 200)
        }
        .padding()
        .background {
            Color.white.scaleEffect(1.5)
        }
    }

    private func timePicker(title: String, selection: Binding<Date>) -> some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundStyle(Color.gray400)
            Spacer()
            DatePicker("", selection: selection, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .foregroundStyle(Color.gray400)
        }
    }

    private func todoField(text: Binding<String>, prompt: String = "") -> some View {
        HStack {
            Image(systemName: SFSymbol.circle.name)
                .resizable()
                .scaledToFit()
                .frame(width: 12, height: 12)
                .foregroundStyle(Color.calendarBlue)
            TextField(prompt, text: text)
                .font(.body)
                .foregroundStyle(Color.gray400)
                .textFieldStyle(.plain)
        }
    }
}
