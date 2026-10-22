import EventKit

struct EventKitDependencies {
    let calendarRepository: EventKitCalendarRepository
    let reminderRepository: EventKitReminderRepository
    let changeObserver: EventKitChangeObserver

    init(eventStore: EKEventStore = EKEventStore()) {
        calendarRepository = EventKitCalendarRepository(eventStore: eventStore)
        reminderRepository = EventKitReminderRepository(eventStore: eventStore)
        changeObserver = EventKitChangeObserver(eventStore: eventStore)
    }
}
