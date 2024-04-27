//
//  TempleteLabel.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import SwiftUI
import EventKit

struct TemplateLabel: View {
    @Bindable var template: Template
    @Binding var currentDragTemplate: Template?
    @State var calendar: EKCalendar
    @State var newTitle: String
    @State var newIsAllDay: Bool
    @State var newStartDate: Date
    @State var newEndTime: Date
    @State var newTodo: String = ""
    @State var newTodos: [String]
    @State private var editTemplateRequest = false
    @State private var deleteTemplateRequest = false
    @State private var onHover = false
    @State private var onPress = false
    @Environment(\.modelContext) private var context
    @EnvironmentObject var eventManager: EventStoreManager
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: SFSymbol.circleFill.name)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 8, height: 8)
                    .foregroundStyle(Color(calendar.cgColor))
                Text(template.title)
                    .font(.body)
                    .foregroundStyle(Color.gray400)
                Spacer()
                Text(template.startTime, style: .time)
                    .font(.subheadline)
                    .foregroundStyle(Color.gray300)
            }
            .padding(8)
            .background {
                if onHover {
                    Color.calendarBlue
                        .cornerRadius(12)
                        .opacity(0.1)
                } else {
                    Color(calendar.cgColor)
                        .opacity(0.1)
                        .cornerRadius(12)
                }
            }
            .onDrag { () -> NSItemProvider in
                self.currentDragTemplate = template
                return NSItemProvider(object: template.id.uuidString as NSString)
            }
        }
        .frame(height: 32)
        .contextMenu {
            Button(action: {
                deleteTemplateRequest = true
            }) {
                Text(String(localized: "DELETE"))
            }
        }
        .onTapGesture(count: 2) {
            editTemplateRequest = true
        }
        .popover(isPresented: $editTemplateRequest, arrowEdge: .trailing) {
            VStack(alignment: .leading, spacing: 8) {
                TextField(String(localized: "TEMPLATE_DEFAULT_TITLE"), text: $newTitle)
                    .font(.title3)
                    .foregroundStyle(Color.gray400)
                    .textFieldStyle(.plain)
                VStack(alignment: .leading) {
                    HStack {
                        Text(String(localized: "ALL_DAY"))
                            .font(.body)
                            .foregroundStyle(Color.gray400)
                        Spacer()
                        Toggle("", isOn: $newIsAllDay)
                            .foregroundStyle(Color.gray200)
                            .toggleStyle(BackgroundToggleStyle())
                            .labelsHidden()
                    }
                    if !newIsAllDay {
                        VStack {
                            HStack {
                                Text(String(localized: "START"))
                                    .font(.body)
                                    .foregroundStyle(Color.gray400)
                                Spacer()
                                DatePicker("", selection: $newStartDate, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .foregroundStyle(Color.gray400)
                            }
                            HStack {
                                Text(String(localized: "END"))
                                    .font(.body)
                                    .foregroundStyle(Color.gray400)
                                Spacer()
                                DatePicker("", selection: $newEndTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .foregroundStyle(Color.gray400)
                            }
                        }
                        .transition(.identity)
                    }
                    CustomPicker(title: String(localized: "CATEGORY"), categoryList: eventManager.calendars, selected: $calendar)
                    Text(String(localized: "REMINDER"))
                        .font(.body)
                        .foregroundStyle(Color.gray400)
                    ForEach(newTodos.indices, id:\.self) { index in
                        HStack {
                            Image(systemName: SFSymbol.circle.name)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 12, height: 12)
                                .foregroundStyle(Color.calendarBlue)
                            TextField("", text: $newTodos[index])
                                .foregroundStyle(Color.gray400)
                                .textFieldStyle(.plain)
                        }
                    }
                    HStack {
                        Image(systemName: SFSymbol.circle.name)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                            .foregroundStyle(Color.calendarBlue)
                        TextField(String(localized: "NEW_REMINDER"), text: $newTodo)
                            .font(.body)
                            .foregroundStyle(Color.gray400)
                            .textFieldStyle(.plain)
                            .onSubmit {
                                newTodos.append(newTodo)
                                newTodo = ""
                            }
                    }
                }
                .frame(width: 200)
            }
            .padding()
            .background {
                Color.white
                    .scaleEffect(1.5)
            }
            .onAppear {
                newTitle = template.title
                newStartDate = template.startTime
                newEndTime = template.endTime
                newTodos = template.todos
            }
            .onDisappear {
                template.title = newTitle
                template.isAllDay = newIsAllDay
                template.startTime = newStartDate
                template.endTime = newEndTime
                template.todos = newTodos
                template.calendarId = calendar.calendarIdentifier
            }
        }
        .alert(String(localized: "TEMPLATE_DELETE"), isPresented: $deleteTemplateRequest) {
            Button(String(localized: "CANCEL"), role: .cancel) {
            }
            Button(String(localized: "DELETE"), role: .destructive) {
                context.delete(template)
            }
        }
        .onHover { hovering in
            onHover = hovering
        }
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
                .frame(width: 30, height: 17, alignment: .center)
                .overlay(
                    Circle()
                        .foregroundColor(.white)
                        .padding(.all, 2)
                        .offset(x: configuration.isOn ? 6 : -6, y: 0)
                        .animation(.easeIn, value: configuration.isOn)
                    
                )
                .cornerRadius(10)
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}
