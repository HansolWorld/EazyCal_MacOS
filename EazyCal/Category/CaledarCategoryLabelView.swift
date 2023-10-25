//
//  CalendarCategoryLabelView.swift
//  EazyCal
//
//  Created by apple on 10/20/23.
//

import SwiftUI

struct CalendarCategoryLabelView: View {
    var title: String
    var color: CGColor
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: SFSymbol.poweron.name)
                .fontWeight(.heavy)
                .foregroundStyle(Color(cgColor: color))
            Text(title)
                .customStyle(.body)
                .foregroundStyle(.black)
        }
    }
}

#Preview {
    CalendarCategoryLabelView(title: "title", color: CGColor(gray: 1, alpha: 1))
}
