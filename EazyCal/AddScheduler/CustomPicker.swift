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
    @State var categoryList: [EKCalendar]
    @State var isShow = false
    @Binding var selected: EKCalendar
    
    var body: some View {
        HStack {
            Text(title)
                .customStyle(.caption)
            Spacer()
            Button(action: {
                isShow = true
            }) {
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .frame(width: 4, height: 16)
                        .foregroundStyle(Color(cgColor: selected.cgColor))
                    Text(selected.title)
                        .customStyle(.caption)
                        .foregroundStyle(.black)
                    Image(systemName: SFSymbol.chevronRight.name)
                        .font(CustomTextStyle.caption.font)
                }
            }
            .popover(isPresented: $isShow) {
                VStack(alignment: .leading) {
                    ForEach(categoryList, id: \.calendarIdentifier) { category in
                        Button(action: {
                            selected = category
                            isShow = false
                        }) {
                            HStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .frame(width: 4, height: 16)
                                    .foregroundStyle(Color(cgColor: category.cgColor))
                                Text(category.title)
                                    .customStyle(.caption)
                                    .foregroundStyle(.black)
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }
}

#Preview {
    CustomPicker(title: "캘린더", categoryList: [], selected: .constant(EKCalendar()))
}
