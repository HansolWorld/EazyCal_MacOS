//
//  TempleteLabel.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import SwiftUI

struct TemplateLabel: View {
    @ObservedObject var template: Template
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .frame(width: 44, height: 44)
                    .foregroundStyle(Color(template.category.color))
                    .opacity(0.1)
                Text(template.icon)
                    .font(.icon)
                    .foregroundStyle(.black)
            }
            Text(template.name)
                .font(.templete)
                .foregroundStyle(.black)
        }
    }
}

#Preview {
    TemplateLabel(template:
                    Template(
                        name: "회의",
                        icon: "💼",
                        category: CalendarCategory(name: "사이드 프로젝트", color: "Puple", isCheck: true)
                    )
    )
}
