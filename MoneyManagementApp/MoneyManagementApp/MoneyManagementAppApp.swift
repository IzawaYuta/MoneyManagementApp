//
//  MoneyManagementAppApp.swift
//  MoneyManagementApp
//
//  Created by Engineer MacBook Air on 2026/09/06.
//

import SwiftUI
import SwiftData

@main
struct MoneyManagementAppApp: App {
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
            HomeView()
        }
        .modelContainer(sharedModelContainer)
    }
}
