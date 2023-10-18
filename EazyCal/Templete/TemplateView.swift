//
//  TemplateView.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import SwiftUI

struct TemplateView: View {
    @StateObject private var templateViewModel = TemplateViewModel()
    var columns: [GridItem] = Array(repeating: .init(.flexible()), count: 3)
    
    var body: some View {
        VStack(spacing: 19) {
            HStack {
                Text(IndexCategory.template.title)
                    .customStyle(.subtitle)
                Spacer()
                Button(action: {
                    
                }) {
                    Image(systemName: SFSymbol.circlePlus.name)
                }
            }
            .foregroundStyle(.gray)
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach(templateViewModel.templates) { template in
                        TemplateLabel(template: template)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    TemplateView()
}
