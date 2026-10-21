//
//  CalendarHeaderView.swift
//  EazyCal
//

import SwiftUI

struct CalendarHeaderView: View {
    @Binding var isSide: Bool
    @ObservedObject var calendarViewModel: CalendarViewModel
    @EnvironmentObject private var eventManager: EventStoreManager

    var body: some View {
        HStack(spacing: 15) {
            Button {
                withAnimation {
                    isSide.toggle()
                }
            } label: {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(isSide ? Color.calendarBlue : Color.gray300)
                    .padding(7)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSide ? Color.calendarBlue.opacity(0.1) : Color.white)
                    }
            }
            .buttonStyle(.plain)

            monthButton(symbol: SFSymbol.chevronBackward.name) {
                calendarViewModel.minusMonth()
            }

            Text(calendarViewModel.monthYearString())
                .font(.largeTitle)
                .foregroundStyle(.gray400)

            monthButton(symbol: SFSymbol.chevronForward.name) {
                calendarViewModel.plusMonth()
            }

            Button {
                calendarViewModel.date = Date()
                refreshVisibleMonth()
            } label: {
                Text(String(localized: "TODAY"))
                    .font(.body)
                    .foregroundStyle(.gray300)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background {
                        Capsule()
                            .foregroundStyle(.white)
                    }
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }

    private func monthButton(symbol: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
            refreshVisibleMonth()
        } label: {
            Image(systemName: symbol)
                .font(.body)
                .fontWeight(.bold)
                .foregroundStyle(.gray300)
                .padding(12)
                .background {
                    Circle()
                        .foregroundStyle(Color.white)
                }
        }
        .buttonStyle(.plain)
    }

    private func refreshVisibleMonth() {
        eventManager.date = calendarViewModel.date
        Task {
            await eventManager.refreshCalendarEntries()
        }
    }
}
