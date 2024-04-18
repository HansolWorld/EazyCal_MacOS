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
        ZStack(alignment: .topLeading) {
            HStack(spacing: 0) {
                    HStack(spacing:0) {
                        VStack(spacing: 24) {
                            TabButton(image: "calendar", title: "Calendar", selectedTab: $homeData.selectedTab)
                            TabButton(image: "list.bullet", title: "List", selectedTab: $homeData.selectedTab)
                            TabButton(image: "doc.plaintext", title: "ScheduleList", selectedTab: $homeData.selectedTab)
                            Spacer()
                        }
                        .padding()
                        .padding(.top, 30)
                        
                        if isSide {
                            ZStack {
                                switch homeData.selectedTab {
                                case "Calendar":
                                    CalendarTabView(currentDragTemplate: $currentDragTemplate)
                                case "List":
                                    TodoView()
                                default:
                                    ScheduleListView()
                                }
                            }
                            .background(Color.white)
                            .frame(maxWidth: 330-52)
                        }ㅎ
                    }
                
                CalenderView(currentDragTemplate: $currentDragTemplate)
            }
            
            Button(action: {
                withAnimation {
                    isSide.toggle()
                }
            }) {
                Image(systemName: "sidebar.left")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14)
            }
            .buttonStyle(.plain)
            .padding(.leading, 70)
            .padding(.top, 8)
        }
        .background(Color.background)
        .environmentObject(homeData)
    }
}

class HomeViewModel: ObservableObject {
    @Published var selectedTab = "Calendar"
}


#Preview {
    Home()
        .environmentObject(EventStoreManager())
}
