import SwiftData
import SwiftUI

struct TemplateLabel: View {
    @Bindable var template: Template
    @Binding var currentDragTemplate: Template?
    @State var calendar: CalendarItem
    @State var newTitle: String
    @State var newIsAllDay: Bool
    @State var newStartDate: Date
    @State var newEndTime: Date
    @State var newTodos: [String]
    @State private var editTemplateRequest = false
    @State private var deleteTemplateRequest = false
    @State private var onHover = false
    @Environment(\.modelContext) private var context

    var body: some View {
        HStack {
            Image(systemName: SFSymbol.circleFill.name)
                .resizable()
                .scaledToFit()
                .frame(width: 8, height: 8)
                .foregroundStyle(Color(calendarColor: calendar.color))
            Text(template.title)
                .font(.body)
                .foregroundStyle(Color.gray400)
            Spacer()
            Text(template.startTime, style: .time)
                .font(.subheadline)
                .foregroundStyle(Color.gray300)
        }
        .padding(8)
        .frame(height: 32)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(onHover ? Color.calendarBlue : Color(calendarColor: calendar.color))
                .opacity(0.1)
        }
        .onDrag {
            currentDragTemplate = template
            return NSItemProvider(object: template.id.uuidString as NSString)
        }
        .contextMenu {
            Button(String(localized: "DELETE")) {
                deleteTemplateRequest = true
            }
        }
        .onTapGesture(count: 2) {
            editTemplateRequest = true
        }
        .popover(isPresented: $editTemplateRequest, arrowEdge: .trailing) {
            TemplateEditorView(
                title: $newTitle,
                isAllDay: $newIsAllDay,
                startDate: $newStartDate,
                endDate: $newEndTime,
                calendar: $calendar,
                todos: $newTodos
            )
            .onAppear(perform: prepareEditor)
            .onDisappear(perform: saveTemplate)
        }
        .alert(String(localized: "TEMPLATE_DELETE"), isPresented: $deleteTemplateRequest) {
            Button(String(localized: "CANCEL"), role: .cancel) {}
            Button(String(localized: "DELETE"), role: .destructive) {
                SwiftDataTemplateRepository(context: context).delete(template)
            }
        }
        .onHover { hovering in
            onHover = hovering
        }
    }

    private func prepareEditor() {
        newTitle = template.title
        newIsAllDay = template.isAllDay
        newStartDate = template.startTime
        newEndTime = template.endTime
        newTodos = template.todos
    }

    private func saveTemplate() {
        SwiftDataTemplateRepository(context: context).update(
            template,
            values: TemplateValues(
                title: newTitle,
                isAllDay: newIsAllDay,
                startTime: newStartDate,
                endTime: newEndTime,
                todos: newTodos,
                calendarIdentifier: calendar.id
            )
        )
    }
}

struct BackgroundToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            Rectangle()
                .foregroundColor(configuration.isOn ? .calendarBlue : .gray200)
                .animation(.snappy, value: configuration.isOn)
                .frame(width: 30, height: 17)
                .overlay {
                    Circle()
                        .foregroundColor(.white)
                        .padding(2)
                        .offset(x: configuration.isOn ? 6 : -6)
                        .animation(.easeIn, value: configuration.isOn)
                }
                .cornerRadius(10)
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}
