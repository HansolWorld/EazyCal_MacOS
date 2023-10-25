//
//  EazyCalApp.swift
//  EazyCal
//
//  Created by apple on 10/13/23.
//

import SwiftUI

@main
struct EazyCalApp: App {
    @StateObject var eventStore = EventStore()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(eventStore)
        }
    }
}
