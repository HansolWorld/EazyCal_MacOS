//
//  TemplateView.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import SwiftUI
import SwiftData

struct TemplateView: View {
    @Binding var currentDragTemplate: Template?
    @EnvironmentObject var eventManager: EventStoreManager
    
    @Environment(\.modelContext) private var context
    @Query(sort: \Template.date, order: .reverse, animation: .snappy) private var templates: [Template]

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text(IndexCategory.template.title)
                    .font(.headline)
                    .foregroundStyle(.gray300)
                Spacer(minLength: 10)
                
                Button(action: {
                    if let calendar = eventManager.calendars.first {
                        SwiftDataTemplateRepository(context: context)
                            .createDefault(calendarIdentifier: calendar.id)
                    }
                }) {
                    Image(systemName: SFSymbol.plus.name)
                        .foregroundStyle(Color.primaryBlue)
                }
                .buttonStyle(.plain)
            }
            ScrollView(.vertical) {
                LazyVStack(spacing: 10) {
                    if let firstCalendar = eventManager.calendars.first {
                        ForEach(templates, id:\.id) { template in
                            let calendar = eventManager.calendars.first(where: { $0.id == template.calendarId }) ?? firstCalendar
                            TemplateLabel(
                                template: template,
                                currentDragTemplate: $currentDragTemplate,
                                calendar: calendar,
                                newTitle: template.title,
                                newIsAllDay: template.isAllDay,
                                newStartDate: template.startTime,
                                newEndTime: template.endTime,
                                newTodos: template.todos
                            )
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    TemplateView(currentDragTemplate: .constant(nil))
        .environmentObject(EventStoreManager())
}
