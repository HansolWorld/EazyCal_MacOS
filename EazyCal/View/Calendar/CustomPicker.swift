//
//  CustomPicker.swift
//  EazyCal
//
//  Created by apple on 10/18/23.
//

import SwiftUI
import EventKit

struct CustomPicker: View {
    let title: String
    let categoryList: [CalendarItem]
    @State var isShow = false
    @Binding var selected: CalendarItem
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundStyle(.gray400)
            Spacer()
            Button(action: {
                isShow = true
            }) {
                HStack {
                    Image(systemName: SFSymbol.circleFill.name)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 8, height: 8)
                        .foregroundStyle(Color(calendarColor: selected.color))
                    Text(selected.title)
                        .font(.body)
                        .foregroundStyle(.gray400)
                    Image(systemName: SFSymbol.chevronRight.name)
                        .font(.body)
                        .foregroundStyle(.gray300)
                }
            }
            .buttonStyle(.plain)
            .popover(isPresented: $isShow) {
                VStack(alignment: .leading) {
                    ForEach(categoryList) { category in
                        Button(action: {
                            selected = category
                            isShow = false
                        }) {
                            HStack {
                                Image(systemName: SFSymbol.circleFill.name)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 8, height: 8)
                                    .foregroundStyle(Color(calendarColor: category.color))
                                Text(category.title)
                                    .font(.caption)
                                    .foregroundStyle(.gray400)
                            }
                            .background {
                                Color.clear
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                .background {
                    Color.white
                        .scaleEffect(1.5)
                }
            }
        }
    }
}

#Preview {
    CustomPicker(
        title: "캘린더",
        categoryList: [],
        selected: .constant(CalendarItem(id: "preview", title: "Preview", color: .clear))
    )
}
