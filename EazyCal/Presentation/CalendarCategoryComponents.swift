import SwiftData
import SwiftUI

struct CalendarCategoryGrid: View {
    let categories: [CalendarCategory]
    @Binding var selectedCategory: CalendarCategory?
    @Binding var draggedCalendarIdentifier: String?

    @State private var categoryIcon = ""
    @State private var categoryTitle = ""
    @State private var requestedCategory: CalendarCategory?
    @State private var isEditPresented = false
    @State private var isDeletePresented = false
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var eventManager: EventStoreManager

    private let columns = Array(repeating: GridItem(.flexible()), count: 4)

    var body: some View {
        LazyVGrid(columns: columns) {
            ForEach(categories, id: \.id) { category in
                categoryButton(category)
                    .contextMenu {
                        if canEdit(category) {
                            Button(String(localized: "EDIT")) {
                                categoryTitle = category.title
                                categoryIcon = category.icon
                                requestedCategory = category
                                isEditPresented = true
                            }
                            Button(String(localized: "DELETE")) {
                                requestedCategory = category
                                isDeletePresented = true
                            }
                        }
                    }
                    .onDrop(of: [.text], isTargeted: nil) { _ in
                        moveDraggedCalendar(to: category)
                    }
            }
        }
        .alert(String(localized: "CATEGORY_EDIT"), isPresented: $isEditPresented) {
            TextField(String(localized: "CATEGORY_ICON"), text: $categoryIcon)
            TextField(String(localized: "CATEGORY_TITLE"), text: $categoryTitle)
            Button(String(localized: "CANCEL"), role: .cancel, action: resetRequest)
            Button(String(localized: "EDIT"), action: updateRequestedCategory)
        }
        .alert(String(localized: "CATEGORY_DELETE"), isPresented: $isDeletePresented) {
            Button(String(localized: "CANCEL"), role: .cancel, action: resetRequest)
            Button(String(localized: "DELETE"), role: .destructive, action: deleteRequestedCategory)
        }
    }

    private func categoryButton(_ category: CalendarCategory) -> some View {
        let isSelected = category.isSelected ?? false

        return Button {
            withAnimation {
                SwiftDataCalendarCategoryRepository(context: context).select(category, in: categories)
                selectedCategory = category
                Task {
                    await eventManager.refreshCalendarEntries()
                }
            }
        } label: {
            VStack {
                Text(category.icon)
                    .font(.system(size: 12))
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 12).fill(Color.background)
                    }
                    .opacity(isSelected ? 1 : 0.5)
                    .overlay {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.primaryBlue, lineWidth: 2)
                        }
                    }
                Text(category.title)
                    .lineLimit(1)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundStyle(isSelected ? .primaryBlue : .gray400)
            }
        }
        .buttonStyle(.plain)
    }

    private func canEdit(_ category: CalendarCategory) -> Bool {
        category.title != String(localized: "TOTAL")
            && category.title != String(localized: "NOT_CATEGORY")
    }

    private func moveDraggedCalendar(to category: CalendarCategory) -> Bool {
        guard let draggedCalendarIdentifier else { return false }
        let source = selectedCategory?.title == String(localized: "TOTAL") ? nil : selectedCategory
        SwiftDataCalendarCategoryRepository(context: context).moveCalendar(
            identifier: draggedCalendarIdentifier,
            from: source,
            to: category
        )
        selectedCategory = category
        self.draggedCalendarIdentifier = nil
        return true
    }

    private func updateRequestedCategory() {
        if let requestedCategory {
            SwiftDataCalendarCategoryRepository(context: context).update(
                requestedCategory,
                icon: categoryIcon,
                title: categoryTitle
            )
        }
        resetRequest()
    }

    private func deleteRequestedCategory() {
        if let requestedCategory {
            SwiftDataCalendarCategoryRepository(context: context).delete(requestedCategory)
        }
        resetRequest()
    }

    private func resetRequest() {
        categoryTitle = ""
        categoryIcon = ""
        requestedCategory = nil
    }
}

struct CategorizedCalendarList: View {
    let calendars: [CalendarItem]
    let categories: [CalendarCategory]
    let selectedCategory: CalendarCategory?
    @Binding var draggedCalendarIdentifier: String?

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(filteredCalendars) { calendar in
                    CategoryLabelView(
                        calendar: calendar,
                        currentDragCalendarIdentifier: $draggedCalendarIdentifier
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 12).fill(Color.background)
        }
    }

    private var filteredCalendars: [CalendarItem] {
        let categorizedIdentifiers = categories.dropFirst(2).flatMap(\.calendars)

        return calendars.filter { calendar in
            if selectedCategory?.title == String(localized: "TOTAL") {
                true
            } else if selectedCategory?.title == String(localized: "NOT_CATEGORY") {
                !categorizedIdentifiers.contains(calendar.id)
            } else if let selectedCategory {
                selectedCategory.calendars.contains(calendar.id)
            } else {
                false
            }
        }
    }
}
