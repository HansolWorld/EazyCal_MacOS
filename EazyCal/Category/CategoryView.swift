//
//  CategoryView.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import SwiftUI
import EventKit

struct CategoryView: View {
    @State var isShow = false
    @State var newTitle = ""
    @State var newColor = CGColor(red: 65/255, green: 129/255, blue: 255/255, alpha: 1)
    @State var checkedCategory = Locale.checkList
    @ObservedObject var calendarViewModel: CalendarViewModel
    @EnvironmentObject var eventStore: EventStore

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text(IndexCategory.calendar.title)
                    .customStyle(.body)
                    .foregroundStyle(.gray)
                Spacer()
                Button(action: {
                    isShow = true
                }) {
                    Image(systemName: SFSymbol.circlePlus.name)
                        .tint(Color.background)
                        .background {
                            Circle()
                                .foregroundStyle(Color.gray300)
                                .scaleEffect(0.8)
                        }
                        .popover(isPresented: $isShow) {
                            AddNewCategoryView(newTitle: $newTitle, newColor: $newColor)
                        }
                        .onChange(of: isShow) {
                            if isShow == false, newTitle != "" {
                                Task {
                                    await eventStore.createNewCalendar(title: newTitle, color: newColor)
                                    self.calendarViewModel.categories = await eventStore.loadCalendars()

                                    newTitle = ""
                                    newColor = CGColor(red: 65/255, green: 129/255, blue: 255/255, alpha: 1)
                                }
                            }
                        }
                }
            }
            ScrollView {
                ForEach(calendarViewModel.categories, id:\.calendarIdentifier) { category in
                    CategoryLabelView(checkedCategory: $checkedCategory, category: category)
                }
            }
        }
        .padding(.horizontal)
        .task {
            self.calendarViewModel.categories = await eventStore.loadCalendars()
        }
        .onChange(of: checkedCategory) {
            Task {
                await calendarViewModel.loadSchedule(eventStore: eventStore)
                await calendarViewModel.loadAllSchedule(eventStore: eventStore)
            }
        }
    }
}

#Preview {
    CategoryView(calendarViewModel: CalendarViewModel())
        .environmentObject(EventStore())
}
