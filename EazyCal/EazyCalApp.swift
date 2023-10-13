//
//  EazyCalApp.swift
//  EazyCal
//
//  Created by apple on 10/13/23.
//

import SwiftUI

@main
struct EazyCalApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
