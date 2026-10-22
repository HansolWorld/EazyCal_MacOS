import EventKit

final class EventKitChangeObserver: EventStoreChangeObserving {
    private let eventStore: EKEventStore
    private var observer: NSObjectProtocol?

    init(eventStore: EKEventStore) {
        self.eventStore = eventStore
    }

    func startObservingChanges(_ handler: @escaping @MainActor () -> Void) {
        guard observer == nil else { return }
        observer = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: eventStore,
            queue: .main
        ) { _ in
            Task { @MainActor in handler() }
        }
    }

    func stopObservingChanges() {
        guard let observer else { return }
        NotificationCenter.default.removeObserver(observer)
        self.observer = nil
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
