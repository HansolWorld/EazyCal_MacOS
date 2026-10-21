//
//  CategoryLabel.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import SwiftUI
import SwiftData

struct CategoryLabelView: View {
    let calendar: CalendarItem
    @State private var onHover = false
    @State private var calendarTitle = ""
    @State private var calendarColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
    @State private var requestCalendar: CalendarItem?
    @State private var editCalendarRequest: Bool = false
    @State private var deleteCalendarRequest: Bool = false
    @Binding var currentDragCalendarIdentifier: String?
    @EnvironmentObject var eventManager: EventStoreManager
    
    var body: some View {
        Button(action: {
            Task {
                await eventManager.setCalendar(
                    identifier: calendar.id,
                    isChecked: !eventManager.isCalendarChecked(identifier: calendar.id)
                )
            }
        }) {
            HStack(spacing: 10) {
                Image(systemName: checkToImageName())
                    .resizable()
                    .scaledToFit()
                    .frame(width: 8, height: 8)
                    .fontWeight(.heavy)
                    .foregroundStyle(Color(calendarColor: calendar.color))
                Text(calendar.title)
                    .font(.body)
                    .foregroundStyle(.gray400)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: 35)
            .padding(8)
            .background {
                if onHover {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.calendarBlue)
                        .opacity(0.1)
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.clear)
                }
            }
            
            .onDrag { () -> NSItemProvider in
                currentDragCalendarIdentifier = calendar.id
                return NSItemProvider(object: calendar.id as NSString)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Section {
                Button(action: {
                    requestCalendar = calendar
                    calendarTitle = calendar.title
                    calendarColor = calendar.color.cgColor
                    editCalendarRequest = true
                }) {
                    Text(String(localized: "EDIT"))
                }
                Button(action: {
                    requestCalendar = calendar
                    deleteCalendarRequest = true
                }) {
                    Text(String(localized: "DELETE"))
                }
            }
        }
        .sheet(isPresented: $editCalendarRequest) {
            VStack(spacing: 8) {
                TextField(String(localized: "CALENDAR_NAME"), text: $calendarTitle)
                ColorPicker(selection: $calendarColor, supportsOpacity: false) {
                    Text(String(localized: "CUSTOM"))
                }
                .padding(.bottom)
                HStack {
                    Button(action: {
                        editCalendarRequest = false
                    }) {
                        Text(String(localized: "CANCEL"))
                    }
                    Spacer()
                    Button(action: {
                        var updatedCalendar = calendar
                        updatedCalendar.color = CalendarColor(calendarColor)
                        updatedCalendar.title = calendarTitle
                        Task {
                            try await eventManager.updateCalendar(calendar: updatedCalendar)
                        }
                        editCalendarRequest = false
                    }) {
                        Text(String(localized: "EDIT"))
                    }
                }
            }
            .padding()
        }
        .alert(String(localized: "\(requestCalendar?.title ?? "") CALENDAR_DELETE"), isPresented: $deleteCalendarRequest) {
            Button(String(localized: "CANCEL"), role: .cancel) {
                requestCalendar = nil
            }
            Button(String(localized: "DELETE"), role: .destructive) {
                if let calendar = requestCalendar {
                    Task {
                        try await eventManager.removeCalendar(identifier: calendar.id)
                        requestCalendar = nil
                    }
                }
            }
        } message: {
            Text(String(localized: "CALENDAR_DELETE_MASSAGE"))
        }
        .onHover { hovering in
            onHover = hovering
        }
    }
    
    func checkToImageName() -> String {
        switch eventManager.isCalendarChecked(identifier: calendar.id) {
        case false:
            return SFSymbol.circle.name
        case true:
            return SFSymbol.circleFill.name
        }
    }
}
