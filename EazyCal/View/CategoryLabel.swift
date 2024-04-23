//
//  CategoryLabel.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import SwiftUI
import SwiftData
import EventKit

struct CategoryLabelView: View {
    let calendar: EKCalendar
    @State private var onHover = false
    @State private var calendarTitle = ""
    @State private var calendarColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
    @State private var requestCalendar: EKCalendar?
    @State private var editCalendarRequest: Bool = false
    @State private var deleteCalendarRequest: Bool = false
    @Binding var currentDragItem: EKCalendar?
    @EnvironmentObject var eventManager: EventStoreManager
    
    var body: some View {
        Button(action: {
            var checkedCalendar = UserDefaults.standard.array(forKey: "checkedCategory") as? [String] ?? []
            
            if checkedCalendar.contains(calendar.calendarIdentifier) {
                checkedCalendar.removeAll { $0 == calendar.calendarIdentifier }
            } else {
                checkedCalendar.append(calendar.calendarIdentifier)
            }
            
            UserDefaults.standard.set(checkedCalendar, forKey: "checkedCategory")
            
            Task {
                do {
                    try await eventManager.loadEvents()
                } catch {
                    print(error)
                }
            }
        }) {
            HStack(spacing: 10) {
                Image(systemName: checkToImageName())
                    .resizable()
                    .scaledToFit()
                    .frame(width: 8, height: 8)
                    .fontWeight(.heavy)
                    .foregroundStyle(Color(cgColor: calendar.cgColor))
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
                self.currentDragItem = calendar
                return NSItemProvider(object: calendar.calendarIdentifier as NSString)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Section {
                Button(action: {
                    requestCalendar = calendar
                    calendarTitle = calendar.title
                    calendarColor = calendar.cgColor
                    editCalendarRequest = true
                }) {
                    Text("수정")
                }
                Button(action: {
                    requestCalendar = calendar
                    deleteCalendarRequest = true
                }) {
                    Text("삭제")
                }
            }
        }
        .sheet(isPresented: $editCalendarRequest) {
            VStack(spacing: 8) {
                TextField("캘린더 이름", text: $calendarTitle)
                ColorPicker(selection: $calendarColor, supportsOpacity: false) {
                    Text("사용자 지정")
                }
                .padding(.bottom)
                HStack {
                    Button(action: {
                        editCalendarRequest = false
                    }) {
                        Text("취소")
                    }
                    Spacer()
                    Button(action: {
                        calendar.cgColor = calendarColor
                        calendar.title = calendarTitle
                        Task {
                            try await eventManager.updateCalendar(calendar: calendar)
                        }
                        editCalendarRequest = false
                    }) {
                        Text("수정")
                    }
                }
            }
            .padding()
        }
        .alert("\(requestCalendar?.title ?? "") 캘린더 삭제", isPresented: $deleteCalendarRequest) {
            Button("취소", role: .cancel) {
                requestCalendar = nil
            }
            Button("삭제", role: .destructive) {
                if let calendar = requestCalendar {
                    Task {
                        try await eventManager.removeCalendar(calendar: calendar)
                        requestCalendar = nil
                    }
                }
            }
        } message: {
            Text("이 캘린더를 삭제하면\n캘린더와 관련된 모든 이벤트도 삭제됩니다.")
        }
        .onHover { hovering in
            onHover = hovering
        }
    }
    
    func checkToImageName() -> String {
        let checkedCategory = UserDefaults.standard.array(forKey: "checkedCategory") as? [String] ?? []

        switch checkedCategory.contains(calendar.calendarIdentifier) {
        case false:
            return SFSymbol.circle.name
        case true:
            return SFSymbol.circleFill.name
        }
    }
}
