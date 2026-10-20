//
//  EazyCalApp.swift
//  EazyCal
//

import SwiftUI
import SwiftData
import EventKit
import AppKit

@main
struct EazyCalApp: App {
    private let appContainer: ModelContainer
    @StateObject private var storeManager: EventStoreManager
    @StateObject private var calendarViewModel = CalendarViewModel()
    @State private var persistenceWarning: String?
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let result = Self.makeModelContainer()
        appContainer = result.container
        _persistenceWarning = State(initialValue: result.warning)
        _storeManager = StateObject(wrappedValue: EventStoreManager())
    }

    var body: some Scene {
        WindowGroup {
            Home()
                .environmentObject(storeManager)
                .environmentObject(calendarViewModel)
                .ignoresSafeArea(.all, edges: .all)
                .overlay {
                    if !storeManager.hasCalendarAccess {
                        PermissionRequiredView(
                            calendarStatus: storeManager.calendarAuthorizationStatus,
                            reminderStatus: storeManager.reminderAuthorizationStatus,
                            retry: { Task { await storeManager.prepare() } },
                            openSettings: openCalendarSettings
                        )
                    }
                }
                .overlay(alignment: .topTrailing) {
                    if storeManager.hasCalendarAccess && !storeManager.hasReminderAccess {
                        Button(action: openReminderSettings) {
                            Label(String(localized: "AUTHORITY_REMINDER"), systemImage: "exclamationmark.triangle")
                        }
                        .buttonStyle(.borderedProminent)
                        .padding()
                    }
                }
                .preferredColorScheme(.light)
                .task {
                    await storeManager.prepare()
                }
                .onAppear { storeManager.startObservingChanges() }
                .onDisappear { storeManager.stopObservingChanges() }
                .onChange(of: scenePhase) { _, phase in
                    guard phase == .active else { return }
                    Task { await storeManager.reloadAll() }
                }
                .alert(
                    "EazyCal",
                    isPresented: Binding(
                        get: { storeManager.lastErrorMessage != nil || persistenceWarning != nil },
                        set: { isPresented in
                            if !isPresented {
                                storeManager.lastErrorMessage = nil
                                persistenceWarning = nil
                            }
                        }
                    )
                ) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(storeManager.lastErrorMessage ?? persistenceWarning ?? "")
                }
        }
        .windowStyle(.hiddenTitleBar)
        .modelContainer(appContainer)
    }

    private func openCalendarSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    private func openReminderSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    private static func makeModelContainer() -> (container: ModelContainer, warning: String?) {
        do {
            let container = try ModelContainer(for: CalendarCategory.self, Template.self)
            try seedCategoriesIfNeeded(in: container)
            return (container, nil)
        } catch {
            do {
                let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
                let container = try ModelContainer(
                    for: CalendarCategory.self,
                    Template.self,
                    configurations: configuration
                )
                try seedCategoriesIfNeeded(in: container)
                return (
                    container,
                    "저장소를 열지 못해 이번 실행에서는 임시 저장소를 사용합니다: \(error.localizedDescription)"
                )
            } catch {
                preconditionFailure("Unable to create the persistent or fallback model container: \(error)")
            }
        }
    }

    private static func seedCategoriesIfNeeded(in container: ModelContainer) throws {
        var descriptor = FetchDescriptor<CalendarCategory>()
        descriptor.fetchLimit = 1
        guard try container.mainContext.fetch(descriptor).isEmpty else { return }

        container.mainContext.insert(
            CalendarCategory(icon: "🗄️", title: String(localized: "TOTAL"), isSelected: true)
        )
        container.mainContext.insert(
            CalendarCategory(icon: "🗑️", title: String(localized: "NOT_CATEGORY"))
        )
        try container.mainContext.save()
    }
}

private struct PermissionRequiredView: View {
    let calendarStatus: EKAuthorizationStatus
    let reminderStatus: EKAuthorizationStatus
    let retry: () -> Void
    let openSettings: () -> Void

    var body: some View {
        ZStack {
            Color.calendarBlack.opacity(0.9).ignoresSafeArea()
            VStack(spacing: 16) {
                Text(String(localized: "AUTHORITY_TITLE"))
                    .font(.title2)
                permissionRow(String(localized: "AUTHORITY_CALENDAR"), status: calendarStatus)
                permissionRow(String(localized: "AUTHORITY_REMINDER"), status: reminderStatus)
                HStack {
                    Button("Retry", action: retry)
                    Button("Open Settings", action: openSettings)
                }
            }
            .foregroundStyle(.white)
            .padding(32)
        }
    }

    private func permissionRow(_ title: String, status: EKAuthorizationStatus) -> some View {
        HStack {
            Image(systemName: status == .fullAccess ? "checkmark.circle.fill" : "xmark.circle.fill")
            Text(title)
        }
        .font(.headline)
    }
}
