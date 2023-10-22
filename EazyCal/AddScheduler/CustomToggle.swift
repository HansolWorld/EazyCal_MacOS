//
//  CustomToggle.swift
//  EazyCal
//
//  Created by apple on 10/18/23.
//

import SwiftUI

struct CustomToggle: View {
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .customStyle(.caption)
                .foregroundStyle(Color.black)
            Spacer()
            Button(action: {
                isOn.toggle()
            }) {
                withAnimation() {
                    ZStack(alignment: .center) {
                        Capsule()
                            .frame(width: 30, height: 20)
                            .foregroundStyle(isOn ? Color.blue : Color.gray200)
                        Circle()
                            .frame(width: 14, height: 14)
                            .foregroundStyle(Color.white)
                            .offset(x: isOn ? 5 : -5)
                    }
                }
            }
        }
    }
}

#Preview {
    CustomToggle(title: "종일", isOn: .constant(false))
}
