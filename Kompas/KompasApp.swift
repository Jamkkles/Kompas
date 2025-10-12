//
//  KompasApp.swift
//  Kompas
//
//  Created by Pablo Correa Mella on 12-10-25.
//

import SwiftUI

@main
struct KompasApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
