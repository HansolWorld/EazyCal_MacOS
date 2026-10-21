import SwiftData
import SwiftUI

struct CalendarCategoryView: View {
    @State private var isAddPopoverPresented = false
    @State private var selectedCategory: CalendarCategory?
    @State private var draggedCalendarIdentifier: String?
    @EnvironmentObject private var eventManager: EventStoreManager
    @Environment(\.modelContext) private var context
    @Query(sort: \CalendarCategory.date, animation: .snappy) private var categories: [CalendarCategory]

    var body: some View {
        VStack(spacing: 15) {
            header

            CalendarCategoryGrid(
                categories: categories,
                selectedCategory: $selectedCategory,
                draggedCalendarIdentifier: $draggedCalendarIdentifier
            )
            .environmentObject(eventManager)

            CategorizedCalendarList(
                calendars: eventManager.calendars,
                categories: categories,
                selectedCategory: selectedCategory,
                draggedCalendarIdentifier: $draggedCalendarIdentifier
            )
            .environmentObject(eventManager)
        }
        .onAppear(perform: prepareSelection)
    }

    private var header: some View {
        HStack {
            Text(IndexCategory.calendar.title)
                .font(.headline)
                .foregroundStyle(.gray300)
            Spacer(minLength: 10)

            Button {
                isAddPopoverPresented = true
            } label: {
                Image(systemName: SFSymbol.plus.name)
                    .foregroundStyle(Color.primaryBlue)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $isAddPopoverPresented) {
                CalendarCategoryPopoverView(isShow: $isAddPopoverPresented)
                    .environmentObject(eventManager)
            }
        }
    }

    private func prepareSelection() {
        selectedCategory = SwiftDataCalendarCategoryRepository(context: context).prepareSelection(
            in: categories,
            totalTitle: String(localized: "TOTAL"),
            uncategorizedTitle: String(localized: "NOT_CATEGORY")
        )

        Task {
            await eventManager.refreshCalendarEntries()
        }
    }
}

#Preview {
    CalendarCategoryView()
        .environmentObject(EventStoreManager())
}
