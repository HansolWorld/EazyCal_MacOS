//
//  MainView.swift
//  EazyCal
//
//  Created by apple on 10/13/23.
//

import SwiftUI
import CoreData

struct MainView: View {
    private var hGrid = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    @State var isTempleteShow: Bool = false
    @StateObject var calendarViewModel = CalendarViewModel()

    var body: some View {
        ZStack {
            Color.background
            HStack(spacing: 0) {
                GeometryReader { geometry in
                    VStack {
                        VStack {
                            CategoryView(calendarViewModel: calendarViewModel)
                            Divider()
                        }
                        .frame(height: geometry.size.height/4)
                        VStack {
                            TemplateView()
                            Divider()
                        }
                        .frame(height: geometry.size.height/4)
                        .onTapGesture {
                            isTempleteShow = true
                        }
                        .popover(isPresented: $isTempleteShow) {
                            Text("Coming Soon")
                                .padding()
                        }
                        VStack {
                            TodoView(mode: .Todo, calendarViewModel: calendarViewModel)
                        }
                        .frame(maxHeight: .infinity)
                    }
                    .padding(.vertical)
                    .background {
                        Color.white
                    }
                }
                .frame(maxWidth: 300)
                CalenderView(calendarViewModel: calendarViewModel)
            }
        }
        .ignoresSafeArea()
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    MainView()
        .environmentObject(EventStore())
}
