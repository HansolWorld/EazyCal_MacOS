//
//  ScheduleListView.swift
//  EazyCal
//
//  Created by apple on 11/26/23.
//

import SwiftUI
import EventKit

struct ScheduleListView: View {
    @EnvironmentObject var eventManager: EventStoreManager
    
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Text(IndexCategory.Upcomming.title)
                    .font(.headline)
                    .foregroundStyle(.gray300)
                Spacer()
            }
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    let eventDict = dateToEvent(eventManager.upcommingEvent)
                    ForEach(eventDict.keys.sorted(), id:\.self) { dateString in
                        VStack(alignment: .leading, spacing: 8) {
                            UpcomingScheduleDateView(dateString)
                            if let events = eventDict[dateString] {
                                ForEach(events, id:\.eventIdentifier) { schedule in
                                    UpcomingScheduleView(schedule: schedule, dateString: dateString)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
    }
     
    @ViewBuilder
    func UpcomingScheduleDateView(_ dateString: String) -> some View {
        Text(dateString)
            .font(.callout)
            .fontWeight(.bold)
            .foregroundStyle(.gray400)
            .opacity(0.4)
            .id(dateString)
    }
    
    func dateToEvent(_ schedule: [EKEvent]) -> [String: [EKEvent]] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = String(localized: "DATE_FORMAT_EVENT")
        
        var result: [String: [EKEvent]] = [:]
        
        let today = Calendar.current.startOfDay(for: Date())
        for event in schedule {
            let startDateComponent = Calendar.current.dateComponents([.year, .month, .day], from: event.startDate)
            let endDateComponent = Calendar.current.dateComponents([.year, .month, .day], from: event.endDate)
            
            if let startDate = Calendar.current.date(from: startDateComponent), let endDate = Calendar.current.date(from: endDateComponent) {
                var currentDate = startDate
                
                if currentDate <= today {
                    currentDate = today
                }
                
                while currentDate <= endDate {
                    let date = dateFormatter.string(from: currentDate)
                    
                    if result.contains(where: {$0.key == date}) {
                        result[date]?.append(event)
                    } else {
                        result[date] = [event]
                    }
                    
                    if let nextDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) {
                        currentDate = nextDate
                    } else {
                        break
                    }
                }
            }
        }
        
        return result
    }
}

extension EKEvent: Identifiable {
    
}

#Preview {
    ScheduleListView()
}


