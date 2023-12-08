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
                            Text(dateString)
                                .font(.callout)
                                .fontWeight(.bold)
                                .foregroundStyle(.gray400)
                                .opacity(0.4)
                                .id(dateString)
                            if let events = eventDict[dateString] {
                                ForEach(events, id:\.eventIdentifier) { event in
                                    if let calendar = event.calendar {
                                        VStack(alignment: .leading) {
                                            HStack {
                                                Image(systemName: SFSymbol.circleFill.name)
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 6, height: 6)
                                                    .fontWeight(.heavy)
                                                    .foregroundStyle(Color(cgColor: calendar.cgColor))
                                                Text(event.title)
                                                    .font(.body)
                                                    .foregroundStyle(Color.gray400)
                                                    .lineLimit(1)
                                            }
                                            HStack {
                                                if event.isAllDay || (Calendar.current.dateComponents([.day], from: event.startDate, to: event.endDate).day ?? 0 >= 1 && dateToString(event.endDate) != dateString ) {
                                                    Text("종일")
                                                    Spacer()
                                                } else {
                                                    Text(event.startDate, style: .time)
                                                    Text("-")
                                                    Text(event.endDate, style: .time)
                                                    Spacer()
                                                }
                                            }
                                            .font(.subheadline)
                                            .foregroundStyle(Color.gray300)
                                            .padding(.leading, 16)
                                        }
                                        .padding(12)
                                        .background {
                                            Color.background
                                                .cornerRadius(12)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
    }
    
    func dateToEvent(_ schedule: [EKEvent]) -> [String: [EKEvent]] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy년 MM월 dd일 EEEE"
        
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
    
    func dateToString(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy년 MM월 dd일 EEEE"
        
        return dateFormatter.string(from: date)
    }
}

#Preview {
    ScheduleListView()
}
