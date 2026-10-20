//
//  TabButton.swift
//  EazyCal
//
//  Created by apple on 11/13/23.
//

import SwiftUI

struct TabButton: View {
    var image: String
    var tab: HomeTab
    @Binding var selectedTab: HomeTab
    
    var body: some View {
        Button(action: {
            selectedTab = tab
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
                                    .opacity(selectedTab == tab ? 0.1 : 0)
                            )
                    }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(tab.rawValue)
    }
}

#Preview {
    TabButton(image: "calendar", tab: .calendar, selectedTab: .constant(.calendar))
}
