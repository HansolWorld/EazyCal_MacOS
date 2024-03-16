//
//  CalendarCategoryPopoverView.swift
//  EazyCal
//
//  Created by apple on 11/13/23.
//

import SwiftUI

struct CalendarCategoryPopoverView: View {
    private let icons: [String] = ["🐶", "🌳", "🍚", "💼", "🔥", "⚽️", "🏖️", "💻", "💡", "💰", "💊", "🎁", "📚", "🩷", "🎄", "🎅"]
    let categoryCount: Int
    @State private var isHoverFirst = false
    @State private var isHoverSecond = false
    @Binding var isShow: Bool
    @Environment(\.modelContext) private var context
    @EnvironmentObject var eventManager: EventStoreManager
    
    var body: some View {
        VStack(alignment: .leading) {
            if categoryCount < 4 {
                Button(action: {
                    let newCategory = CalendarCategory(icon: getRandomIcon(), title: "무제")
                    context.insert(newCategory)
                    isShow = false
                }) {
                    Text("새로운 카테고리")
                        .font(.body)
                        .foregroundStyle(isHoverFirst ? .white : .calendarBlack)
                }
                .contentShape(Rectangle())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 3)
                .padding(.horizontal, 7)
                .buttonStyle(.plain)
                .background {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(isHoverFirst ? .calendarBlue : .clear)
                }
                .onHover { hovering in
                    isHoverFirst = hovering
                }
            }
            
            Button(action: {
                Task {
                    isShow = false
                    try await eventManager.createNewCalendar()
                }
            }) {
                Text("새로운 캘린더")
                    .font(.body)
                    .foregroundStyle(isHoverSecond ? .white : .calendarBlack)
            }
            .contentShape(Rectangle())
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 3)
            .padding(.horizontal, 7)
            .background {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(isHoverSecond ? .calendarBlue : .clear)
            }
            .onHover { hovering in
                isHoverSecond = hovering
            }
            
        }
        .padding(4)
        .background {
            Color.white
                .scaleEffect(1.5)
        }
    }
    
    func getRandomIcon() -> String {
        let randomIndex = Int(arc4random_uniform(UInt32(icons.count)))
        return icons[randomIndex]
    }
}

#Preview {
    CalendarCategoryPopoverView(categoryCount: 2, isShow: .constant(true))
}
