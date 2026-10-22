import Combine
import Foundation

@MainActor
final class EventStoreManager: ObservableObject {
    private let permissionStore: EventStorePermissionStore
    private let calendarStore: CalendarFeatureStore
    private let reminderStore: ReminderFeatureStore
    private let changeObserver: (any EventStoreChangeObserving)?
    private var cancellables: Set<AnyCancellable> = []

    var date: Date {
        get { calendarStore.date }
        set {
            calendarStore.date = newValue
            reminderStore.date = newValue
        }
    }

    var calendars: [CalendarItem] {
        get { calendarStore.calendars }
        set { calendarStore.calendars = newValue }
    }

    var events: [EventItem] {
        get { calendarStore.events }
        set { calendarStore.events = newValue }
    }

    var upcomingEvents: [EventItem] {
        get { calendarStore.upcomingEvents }
        set { calendarStore.upcomingEvents = newValue }
    }

    var reminders: [ReminderItem] {
        get { reminderStore.reminders }
        set { reminderStore.reminders = newValue }
    }

    var scheduledReminders: [ReminderItem] {
        get { reminderStore.scheduledReminders }
        set { reminderStore.scheduledReminders = newValue }
    }

    var calendarAuthorizationStatus: AuthorizationStatus {
        permissionStore.calendarAuthorizationStatus
    }

    var reminderAuthorizationStatus: AuthorizationStatus {
        permissionStore.reminderAuthorizationStatus
    }

    var lastErrorMessage: String? {
        get {
            permissionStore.lastErrorMessage
                ?? calendarStore.lastErrorMessage
                ?? reminderStore.lastErrorMessage
        }
        set {
            guard newValue == nil else { return }
            permissionStore.clearError()
            calendarStore.clearError()
            reminderStore.clearError()
        }
    }

    var hasCalendarAccess: Bool { permissionStore.hasCalendarAccess }
    var hasReminderAccess: Bool { permissionStore.hasReminderAccess }

    init(
        calendarRepository: any CalendarRepository,
        reminderRepository: any ReminderRepository,
        changeObserver: (any EventStoreChangeObserving)? = nil,
        userDefaults: UserDefaults = .standard
    ) {
        permissionStore = EventStorePermissionStore(
            calendarRepository: calendarRepository,
            reminderRepository: reminderRepository
        )
        calendarStore = CalendarFeatureStore(
            repository: calendarRepository,
            userDefaults: userDefaults
        )
        reminderStore = ReminderFeatureStore(repository: reminderRepository)
        self.changeObserver = changeObserver
        reminderStore.date = calendarStore.date
        forwardFeatureChanges()
    }

    convenience init(userDefaults: UserDefaults = .standard) {
        let dependencies = EventKitDependencies()
        self.init(
            calendarRepository: dependencies.calendarRepository,
            reminderRepository: dependencies.reminderRepository,
            changeObserver: dependencies.changeObserver,
            userDefaults: userDefaults
        )
    }

    func prepare() async {
        await requestAccess()
        await reloadAll()
    }

    func startObservingChanges() {
        changeObserver?.startObservingChanges { [weak self] in
            Task { @MainActor [weak self] in
                await self?.reloadAll()
            }
        }
    }

    func stopObservingChanges() {
        changeObserver?.stopObservingChanges()
    }

    func requestAccess() async {
        await permissionStore.requestAccess()
    }

    func reloadAll() async {
        permissionStore.refreshStatuses()

        if hasCalendarAccess {
            await calendarStore.reloadAll()
        } else {
            calendarStore.clear()
        }

        if hasReminderAccess {
            await reminderStore.reloadAll()
        } else {
            reminderStore.clear()
        }
    }

    func refreshCalendarEntries() async {
        if hasCalendarAccess {
            await calendarStore.refreshEvents()
        }
        if hasReminderAccess {
            await reminderStore.refreshScheduledReminders()
        }
    }

    func loadCalendars() async throws {
        try await calendarStore.loadCalendars()
    }

    func loadEvents() async throws {
        try await calendarStore.loadEvents()
    }

    func loadUpcomingEvents() async throws {
        try await calendarStore.loadUpcomingEvents()
    }

    func loadReminders() async throws {
        try await reminderStore.loadReminders()
    }

    func loadScheduledReminders() async throws {
        try await reminderStore.loadScheduledReminders()
    }

    func event(withIdentifier identifier: String) -> EventItem? {
        calendarStore.event(withIdentifier: identifier)
    }

    func reminder(withIdentifier identifier: String) -> ReminderItem? {
        reminderStore.reminder(withIdentifier: identifier)
    }

    func createNewReminder(title: String, date: Date?, priority: ReminderPriority) async throws {
        try await reminderStore.createReminder(title: title, date: date, priority: priority)
    }

    func completeReminder(identifier: String) async throws {
        try await reminderStore.completeReminder(identifier: identifier)
    }

    func updateReminder(reminder: ReminderItem) async throws {
        try await reminderStore.updateReminder(reminder)
    }

    func rescheduleReminder(identifier: String, to targetDate: Date) async throws {
        try await reminderStore.rescheduleReminder(identifier: identifier, to: targetDate)
    }

    func saveEvent(
        title: String,
        isAllDay: Bool,
        startDate: Date,
        endDate: Date,
        repeatDate: RepeatType,
        url: URL?,
        notes: [String],
        calendarIdentifier: String
    ) async throws {
        try await calendarStore.saveEvent(
            title: title,
            isAllDay: isAllDay,
            startDate: startDate,
            endDate: endDate,
            repeatDate: repeatDate,
            url: url,
            notes: notes,
            calendarIdentifier: calendarIdentifier
        )
    }

    func updateEvent(event: EventItem) async throws {
        try await calendarStore.updateEvent(event)
    }

    func moveEvent(identifier: String, to targetDate: Date) async throws {
        try await calendarStore.moveEvent(identifier: identifier, to: targetDate)
    }

    func removeEvent(identifier: String) async throws {
        try await calendarStore.removeEvent(identifier: identifier)
    }

    func createNewCalendar() async throws {
        try await calendarStore.createCalendar()
    }

    func updateCalendar(calendar: CalendarItem) async throws {
        try await calendarStore.updateCalendar(calendar)
    }

    func removeCalendar(identifier: String) async throws {
        try await calendarStore.removeCalendar(identifier: identifier)
    }

    func setCalendar(identifier: String, isChecked: Bool) async {
        await calendarStore.setCalendar(identifier: identifier, isChecked: isChecked)
    }

    func isCalendarChecked(identifier: String) -> Bool {
        calendarStore.isCalendarChecked(identifier: identifier)
    }

    private func forwardFeatureChanges() {
        permissionStore.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
        calendarStore.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
        reminderStore.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }
}
