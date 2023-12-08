//
//  TabButton.swift
//  EazyCal
//
//  Created by apple on 11/13/23.
//

import SwiftUI

struct TabButton: View {
    var image: String
    var title: String
    @Binding var selectedTab: String
    
    var body: some View {
        Button(action: {
            selectedTab = title
        }) {
            VStack(spacing: 7) {
                Image(systemName: image)
                    .font(.system(size: 24))
                    .foregroundStyle(Color.primaryBlue)
                    .padding(.vertical, 12)
                    .frame(width: 52)
                    .contentShape(Circle())
                    .background {
                        Circle()
                            .fill(
                                Color.primaryBlue
                                    .opacity(selectedTab == title ? 0.1 : 0)
                            )
                    }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    TabButton(image: "calendar", title: "calendar", selectedTab: .constant("calendar"))
}
