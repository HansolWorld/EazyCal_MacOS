//
//  TempleteLabel.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import SwiftUI

struct TempleteLabel: View {
    let name: String
    let color: UIColor
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .frame(width: 44, height: 44)
                    .opacity(0.1)
                Text(icon)
                    .font(.icon)
            }
            Text(name)
                .font(.templete)
        }
    }
}

#Preview {
    TempleteLabel(name: "회의록", color: .blue, icon: "😀")
}
