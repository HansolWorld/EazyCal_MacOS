//
//  Home.swift
//  EazyCal
//
//  Created by apple on 10/13/23.
//

import SwiftUI

struct Home: View {
    @StateObject var homeData = HomeViewModel()
    @State var currentDragTemplate: Template?
    @State var isSide = true
    var body: some View {
        HStack(spacing: 0) {
            if isSide {
                HStack(spacing:0) {
                    VStack(spacing: 24) {
                        TabButton(image: "calendar", tab: .calendar, selectedTab: $homeData.selectedTab)
                        TabButton(image: "list.bullet", tab: .reminders, selectedTab: $homeData.selectedTab)
                        TabButton(image: "doc.plaintext", tab: .scheduleList, selectedTab: $homeData.selectedTab)
                        Spacer()
                    }
                    .padding()
                    .padding(.top, 30)
                    
                    ZStack {
                        switch homeData.selectedTab {
                        case .calendar:
                            CalendarTabView(currentDragTemplate: $currentDragTemplate)
                        case .reminders:
                            TodoView()
                        case .scheduleList:
                            ScheduleListView()
                        }
                    }
                    .background(Color.white)
                }
                .frame(maxWidth: 330)
            }
            
            CalendarView(currentDragTemplate: $currentDragTemplate, isSide: $isSide)
        }
        .background(Color.background)
        .environmentObject(homeData)
    }
}

class HomeViewModel: ObservableObject {
    @Published var selectedTab: HomeTab = .calendar
}

enum HomeTab: String {
    case calendar
    case reminders
    case scheduleList
}


#Preview {
    Home()
        .environmentObject(EventStoreManager())
}
