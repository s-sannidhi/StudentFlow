//
//  StudentFlowApp.swift
//  StudentFlow
//
//  Created by Srujan Sannidhi on 4/6/25.
//

import SwiftUI

@main
struct StudentFlowApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
