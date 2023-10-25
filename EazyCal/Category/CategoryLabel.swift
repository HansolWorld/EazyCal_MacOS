//
//  CategoryLabel.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import SwiftUI
import EventKit


class Locale {
    static var checkList: [String] {
        get {
            return UserDefaults.standard.array(forKey: "checkedCategory") as? [String] ?? []
        }
        set(newValue) {
            UserDefaults.standard.set(newValue, forKey: "checkedCategory")
        }
    }
}

struct CategoryLabelView: View {
    @Binding var checkedCategory: [String]
    let category: EKCalendar
    
    var body: some View {
        Button(action: {
            if checkedCategory.contains(category.calendarIdentifier) {
                guard let categoryIdIndex = Locale.checkList.firstIndex(of: category.calendarIdentifier) else { return }
                Locale.checkList.remove(at: categoryIdIndex)
                
                checkedCategory = Locale.checkList
            } else {
                Locale.checkList.append(category.calendarIdentifier)
                checkedCategory = Locale.checkList
            }
        }) {
            HStack(spacing: 8) {
                CalendarCategoryLabelView(title: category.title, color: category.cgColor)
                Spacer()
                Image(systemName: checkToImageName())
            }
        }
        .foregroundStyle(Color(cgColor: category.cgColor))
    }
    
    func checkToImageName() -> String {
        switch checkedCategory.contains(category.calendarIdentifier) {
        case true:
            return SFSymbol.check.name
        case false:
            return SFSymbol.square.name
        }
    }
}

#Preview {
    CategoryLabelView(checkedCategory: .constant([]), category: EKCalendar())
}
