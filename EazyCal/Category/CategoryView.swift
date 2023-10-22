//
//  CategoryView.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import SwiftUI

struct CategoryView: View {
    @State var isShow = false
    @StateObject private var categoryViewModel = CategoryViewModel()

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text(IndexCategory.calendar.title)
                    .customStyle(.body)
                    .foregroundStyle(.gray)
                Spacer()
                Button(action: {
                    isShow = true
                }) {
                    Image(systemName: SFSymbol.circlePlus.name)
                        .tint(Color.background)
                        .background {
                            Circle()
                                .foregroundStyle(Color.gray300)
                                .scaleEffect(0.8)
                        }
                }
            }
            ScrollView {
                ForEach(categoryViewModel.categories) { category in
                    CategoryLabelView(category: category)
                }
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    CategoryView()
}
