//
//  CategoryView.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import SwiftUI

struct CategoryView: View {
    let categories: [CalendarCategory]
    @State var isCheck: Bool = true
    var body: some View {
        VStack(spacing: 19) {
            HStack {
                Text("캘린더")
                    .font(.semiTitle)
                Spacer()
                Button(action: {
                    
                }) {
                    Image(systemName: SFSymbol.circlePlus.name)
                }
            }
            .foregroundStyle(.secondary)
            ForEach(categories, id: \.self) { category in
                CategoryLabel(
                    name: category.name,
                    color: UIColor(named: category.color) ?? UIColor.black,
                    isCheck: $isCheck
                )
            }
        }
        .padding()
    }
}

#Preview {
    CategoryView(categories: [
        CalendarCategory(name: "기본 캘린더", color: "Blue"),
        CalendarCategory(name: "사이드 프로젝트", color: "Puple"),
        CalendarCategory(name: "개인 공부", color: "Orange"),
        CalendarCategory(name: "집안일", color: "Pink")
    ])
}
