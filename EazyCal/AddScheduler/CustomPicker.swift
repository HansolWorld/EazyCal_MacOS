//
//  CustomPicker.swift
//  EazyCal
//
//  Created by apple on 10/18/23.
//

import SwiftUI

struct CustomPicker: View {
    let title: String
    let categoryList: [CalendarCategory]
    @State var isShow = false
    @Binding var selected: CalendarCategory
    
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
                        .foregroundStyle(Color(selected.color))
                    Text(selected.name)
                        .customStyle(.caption)
                        .foregroundStyle(.black)
                    Image(systemName: SFSymbol.chevronRight.name)
                        .font(CustomTextStyle.caption.font)
                }
            }
            .popover(isPresented: $isShow) {
                VStack(alignment: .leading) {
                    ForEach(categoryList, id: \.self) { category in
                        Button(action: {
                            selected = category
                            isShow = false
                        }) {
                            HStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .frame(width: 4, height: 16)
                                    .foregroundStyle(Color(category.color))
                                Text(category.name)
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
    CustomPicker(title: "카테고리", categoryList: CalendarCategory.dummyCategories, selected: .constant(CalendarCategory(name: "개인일", color: "Blue", isCheck: true)))
}
