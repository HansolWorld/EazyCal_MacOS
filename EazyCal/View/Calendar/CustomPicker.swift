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
                        .foregroundStyle(Color(cgColor: selected.cgColor))
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
                    ForEach(categoryList, id: \.calendarIdentifier) { category in
                        Button(action: {
                            selected = category
                            isShow = false
                        }) {
                            HStack {
                                Image(systemName: SFSymbol.circleFill.name)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 8, height: 8)
                                    .foregroundStyle(Color(cgColor: category.cgColor))
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
    CustomPicker(title: "캘린더", categoryList: [], selected: .constant(EKCalendar()))
}
