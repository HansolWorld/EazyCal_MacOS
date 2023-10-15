//
//  CategoryView.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import SwiftUI

struct CategoryView: View {
    @StateObject private var categoryViewModel = CategoryViewModel()

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
            ForEach(categoryViewModel.categories) { category in
                CategoryLabel(category: category)
            }
        }
        .padding()
    }
}

#Preview {
    CategoryView()
}
