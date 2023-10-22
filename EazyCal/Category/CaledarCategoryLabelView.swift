//
//  CalendarCategoryLabelView.swift
//  EazyCal
//
//  Created by apple on 10/20/23.
//

import SwiftUI

struct CalendarCategoryLabelView: View {
    let title: String
    let color: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: SFSymbol.poweron.name)
                .fontWeight(.heavy)
                .foregroundStyle(Color(color))
            Text(title)
                .customStyle(.body)
                .foregroundStyle(.black)
        }
    }
}

#Preview {
    CalendarCategoryLabelView(title: CalendarCategory.dummyCategory(to: 0).name, color: CalendarCategory.dummyCategory(to: 0).color)
}
