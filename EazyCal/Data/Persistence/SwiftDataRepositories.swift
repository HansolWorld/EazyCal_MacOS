//
//  SwiftDataRepositories.swift
//  EazyCal
//

import Foundation
import SwiftData

struct TemplateValues {
    let title: String
    let isAllDay: Bool
    let startTime: Date
    let endTime: Date
    let todos: [String]
    let calendarIdentifier: String
}

@MainActor
protocol TemplateRepository {
    func createDefault(calendarIdentifier: String)
    func update(_ template: Template, values: TemplateValues)
    func delete(_ template: Template)
}

@MainActor
struct SwiftDataTemplateRepository: TemplateRepository {
    let context: ModelContext

    func createDefault(calendarIdentifier: String) {
        context.insert(
            Template(
                title: String(localized: "DEFAULT_TEMPLETE_TITLE"),
                startTime: Date(),
                endTime: Date(),
                todos: [],
                calendarId: calendarIdentifier
            )
        )
    }

    func update(_ template: Template, values: TemplateValues) {
        template.title = values.title
        template.isAllDay = values.isAllDay
        template.startTime = values.startTime
        template.endTime = values.endTime
        template.todos = values.todos
        template.calendarId = values.calendarIdentifier
    }

    func delete(_ template: Template) {
        context.delete(template)
    }
}

@MainActor
protocol CalendarCategoryRepository {
    @discardableResult
    func createCategory(icon: String, title: String) -> CalendarCategory
    func update(_ category: CalendarCategory, icon: String, title: String)
    func delete(_ category: CalendarCategory)
    func select(_ category: CalendarCategory, in categories: [CalendarCategory])
    func moveCalendar(
        identifier: String,
        from source: CalendarCategory?,
        to destination: CalendarCategory
    )
    func prepareSelection(
        in categories: [CalendarCategory],
        totalTitle: String,
        uncategorizedTitle: String
    ) -> CalendarCategory?
}

@MainActor
struct SwiftDataCalendarCategoryRepository: CalendarCategoryRepository {
    let context: ModelContext

    @discardableResult
    func createCategory(icon: String, title: String) -> CalendarCategory {
        let category = CalendarCategory(icon: icon, title: title)
        context.insert(category)
        return category
    }

    func update(_ category: CalendarCategory, icon: String, title: String) {
        category.icon = icon
        category.title = title
    }

    func delete(_ category: CalendarCategory) {
        context.delete(category)
    }

    func select(_ category: CalendarCategory, in categories: [CalendarCategory]) {
        categories.forEach { $0.isSelected = ($0 == category) }
    }

    func moveCalendar(
        identifier: String,
        from source: CalendarCategory?,
        to destination: CalendarCategory
    ) {
        source?.calendars.removeAll { $0 == identifier }
        destination.calendars.removeAll { $0 == identifier }
        destination.calendars.append(identifier)
    }

    func prepareSelection(
        in categories: [CalendarCategory],
        totalTitle: String,
        uncategorizedTitle: String
    ) -> CalendarCategory? {
        categories.forEach { category in
            if category.title == "전체" || category.title == "total" {
                category.title = totalTitle
            } else if category.title == "미등록" || category.title == "Unregistered" {
                category.title = uncategorizedTitle
            }
        }

        if let selected = categories.first(where: { $0.isSelected == true }) {
            return selected
        }
        guard let total = categories.first(where: { $0.title == totalTitle }) else {
            return nil
        }
        select(total, in: categories)
        return total
    }
}
