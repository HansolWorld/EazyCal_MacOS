//
//  CategoryLabel.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import SwiftUI

struct CategoryLabel: View {
    let name: String
    let color: UIColor
    @Binding var isCheck: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 4)
                .frame(width: 4, height: 16)
            Text(name)
                .font(.category)
                .foregroundStyle(.black)
            Spacer()
            Button(action: {
                isCheck.toggle()
            }) {
                Image(systemName: checkToImageName())
            }
        }
        .foregroundStyle(Color(color))
    }
    
    func checkToImageName() -> String {
        switch self.isCheck {
        case true:
            return SFSymbol.check.name
        case false:
            return SFSymbol.square.name
        }
    }
}

#Preview {
    CategoryLabel(name: "기본 캘린더", color: .blue, isCheck: .constant(false))
}
