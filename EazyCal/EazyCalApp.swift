//
//  EazyCalApp.swift
//  EazyCal
//
//  Created by apple on 10/13/23.
//

import SwiftUI
import SwiftData

@main
struct EazyCalApp: App {

    let appContainer: ModelContainer = {
        do {
            let container = try ModelContainer(for: CalendarCategory.self, Template.self)

            // Make sure the persistent store is empty. If it's not, return the non-empty container.
            var itemFetchDescriptor = FetchDescriptor<CalendarCategory>()
            itemFetchDescriptor.fetchLimit = 1
            
            guard try container.mainContext.fetch(itemFetchDescriptor).count == 0 else { return container }
            
            // This code will only run if the persistent store is empty.
            let calendarCategories = [
                CalendarCategory(icon: "🗄️", title: String(localized: "TOTAL"), isSelected: true),
                CalendarCategory(icon: "🗑️", title: String(localized: "NOT_CATEGORY"))
            ]
            
            
            for calendarCategory in calendarCategories {
                container.mainContext.insert(calendarCategory)
            }
            
            return container
        } catch {
            fatalError("Failed to create container")
        }
    }()
    
    @StateObject private var storeManager = EventStoreManager()
    @StateObject var calendarViewModel = CalendarViewModel()
    
    var body: some Scene {
        WindowGroup {
            Home()
                .environmentObject(storeManager)
                .environmentObject(calendarViewModel)
                .ignoresSafeArea(.all, edges: .all)
                .overlay {
                    if !storeManager.eventStore.isFullAccessAuthorized {
                        ZStack {
                            Color.calendarBlack
                                .opacity(0.9)
                            
                            VStack(alignment: .center) {
                                Text(String(localized: "AUTHORITY_TITLE"))
                                    .font(.title2)
                                    .padding(.bottom, 16)
                                Text(String(localized: "AUTHORITY_CALENDAR"))
                                    .font(.headline)
                                Text(String(localized: "AUTHORITY_REMINDER"))
                                    .font(.headline)
                            }
                            .foregroundStyle(Color.white)
                            
                        }
                        .ignoresSafeArea()
                    } else {
                        EmptyView()
                    }
                }
                .preferredColorScheme(.light)   
                .task {
                    await listenForCalendarChanges()
                }
                .onChange(of: storeManager.eventStore.isFullAccessAuthorized) { oldValue, newValue in
                    if !oldValue, newValue {
                        Task {
                            await listenForCalendarChanges()
                        }
                    }
                }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .modelContainer(appContainer)
    }
    
    func listenForCalendarChanges() async {
        let center = NotificationCenter.default
        let notifications = center.notifications(named: .EKEventStoreChanged).map({ (notification: Notification) in notification.name })

        guard storeManager.eventStore.isFullAccessAuthorized else { return }
        for await _ in notifications {
            do {
                try await storeManager.loadCalendar()
                try await storeManager.loadEvents()
                try await storeManager.loadReminder()
                try await storeManager.loadUpcommingEvents()
            } catch {
                print(error)
            }
        }
    }
}
