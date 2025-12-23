//
//  PostureProApp.swift
//  PosturePro
//
//  Created by Arjun on 12/22/25.
//

import SwiftUI
import CoreData

@main
struct PostureProApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
