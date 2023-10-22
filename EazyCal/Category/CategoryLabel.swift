//
//  CategoryLabel.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import SwiftUI


struct CategoryLabelView: View {
    @ObservedObject var category: CalendarCategory
    
    var body: some View {
        HStack(spacing: 8) {
            CalendarCategoryLabelView(title: category.name, color: category.color)
            Spacer()
            Button(action: {
                category.isCheck.toggle()
            }) {
                Image(systemName: checkToImageName())
            }
        }
        .foregroundStyle(Color(category.color))
    }
    
    func checkToImageName() -> String {
        switch self.category.isCheck {
        case true:
            return SFSymbol.check.name
        case false:
            return SFSymbol.square.name
        }
    }
}

#Preview {
    CategoryLabelView(category: CalendarCategory(name: "기본 캘린더", color: "Blue", isCheck: false))
}
