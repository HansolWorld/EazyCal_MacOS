import SwiftData
import XCTest
@testable import EazyCal

@MainActor
final class PersistenceRepositoryTests: XCTestCase {
    func testTemplateRepositoryCreatesUpdatesAndDeletesTemplate() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let repository = SwiftDataTemplateRepository(context: context)

        repository.createDefault(calendarIdentifier: "work")
        var templates = try context.fetch(FetchDescriptor<Template>())
        let template = try XCTUnwrap(templates.first)

        repository.update(
            template,
            values: TemplateValues(
                title: "Updated",
                isAllDay: true,
                startTime: template.startTime,
                endTime: template.endTime,
                todos: ["Check"],
                calendarIdentifier: "home"
            )
        )
        XCTAssertEqual(template.title, "Updated")
        XCTAssertEqual(template.calendarId, "home")
        XCTAssertEqual(template.todos, ["Check"])

        repository.delete(template)
        try context.save()
        templates = try context.fetch(FetchDescriptor<Template>())
        XCTAssertTrue(templates.isEmpty)
    }

    func testCategoryRepositorySelectsAndMovesCalendarWithoutDuplicates() throws {
        let container = try makeContainer()
        let repository = SwiftDataCalendarCategoryRepository(context: container.mainContext)
        let first = repository.createCategory(icon: "1", title: "First")
        let second = repository.createCategory(icon: "2", title: "Second")
        first.calendars = ["work"]

        repository.select(second, in: [first, second])
        repository.moveCalendar(identifier: "work", from: first, to: second)
        repository.moveCalendar(identifier: "work", from: first, to: second)

        XCTAssertEqual(first.isSelected, false)
        XCTAssertEqual(second.isSelected, true)
        XCTAssertTrue(first.calendars.isEmpty)
        XCTAssertEqual(second.calendars, ["work"])
    }

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: CalendarCategory.self,
            Template.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }
}
