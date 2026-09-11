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
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Transaction.self,
            Category.self,
            PaymentMethod.self,
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
            if hasCompletedOnboarding {
                HomeView()
            } else {
//                OnboardingView()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
