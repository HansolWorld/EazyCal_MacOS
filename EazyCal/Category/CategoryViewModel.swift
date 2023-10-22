//
//  CategoryViewModel.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import Foundation

class CategoryViewModel: ObservableObject {
    @Published var categories: [CalendarCategory] = CalendarCategory.dummyCategories
    
    func addCategory(_ category: CalendarCategory) {
        categories.append(category)
    }
}
