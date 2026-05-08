//
//  No_Nonsense_SportsApp.swift
//  No Nonsense Sports
//
//  Created by Liam Wilcox on 08/05/2026.
//

import SwiftUI
import SwiftData

@main
struct No_Nonsense_SportsApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
