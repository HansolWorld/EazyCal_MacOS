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
                CalendarCategory(icon: "🗄️", title: "전체", isSelected: true),
                CalendarCategory(icon: "🗑️", title: "미등록")
            ]
            
            
            for calendarCategory in calendarCategories {
                container.mainContext.insert(calendarCategory)
            }
            
            return container
        } catch {
            fatalError("Failed to create container")
        }
    }()
    
    @StateObject private var storeManager: EventStoreManager = EventStoreManager()
    @StateObject var calendarViewModel = CalendarViewModel()
    
    var body: some Scene {
        WindowGroup {
            Home()
                .environmentObject(storeManager)
                .environmentObject(calendarViewModel)
                .ignoresSafeArea(.all, edges: .all)
                .task {
                    await storeManager.listenForCalendarChanges()
                }
                .overlay {
                    if !storeManager.eventStore.isFullAccessAuthorized {
                        ZStack {
                            Color.calendarBlack
                                .opacity(0.9)
                            
                            VStack(alignment: .center) {
                                Text("앱을 사용하기 위해 설정에서 권한을 허락후 앱을 재실행 해주세요.")
                                    .font(.title2)
                                    .padding(.bottom, 16)
                                Text("시스템 설정 > 개인정보 보호 및 보안 > 캘린더")
                                    .font(.headline)
                                Text("시스템 설정 > 개인정보 보호 및 보안 > 미리 알림")
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
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .modelContainer(appContainer)
    }
}

extension EventStoreManager {
    func listenForCalendarChanges() async {
        let center = NotificationCenter.default
        let notifications = center.notifications(named: .EKEventStoreChanged).map({ (notification: Notification) in notification.name })

        guard eventStore.isFullAccessAuthorized else { return }
        for await _ in notifications {
            await self.loadCalendar()
            await self.loadEvents()
            await self.loadReminder()
            await self.loadUpcommingEvents()
        }
    }
}
