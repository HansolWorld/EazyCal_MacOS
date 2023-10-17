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
        VStack(spacing: 15) {
            HStack {
                Text(IndexCategory.calendar.title)
                    .font(.semiTitle)
                Spacer()
                Button(action: {
                    
                }) {
                    Image(systemName: SFSymbol.circlePlus.name)
                }
            }
            .foregroundStyle(.gray)
            ScrollView {
                ForEach(categoryViewModel.categories) { category in
                    CategoryLabel(category: category)
                }
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    CategoryView()
}
