//
//  CalendarTabView.swift
//  EazyCal
//
//  Created by apple on 10/26/23.
//

import SwiftUI
import EventKit

struct CalendarTabView: View {
    @Binding var currentDragTemplate: Template?
    @EnvironmentObject var eventManager: EventStoreManager
    var body: some View {
        VStack(spacing: 24) {
            CalendarCategoryView()
                .environmentObject(eventManager)
            TemplateView(currentDragTemplate: $currentDragTemplate)
                .environmentObject(eventManager)
        }
        .padding()
    }
}

#Preview {
    Home()
        .environmentObject(EventStoreManager())
}
