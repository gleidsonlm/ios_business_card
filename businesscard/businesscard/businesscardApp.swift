//
//  businesscardApp.swift
//  businesscard
//
//  Created by Gleidson L Medeiros on 13/08/25.
//

import SwiftUI
import SwiftData

@main
struct businesscardApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            ThreatEvent.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    @State private var threatEventListener: ThreatEventListener?

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    setupThreatEventListener()
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    /// Sets up the global threat event listener for Appdome events
    private func setupThreatEventListener() {
        if threatEventListener == nil {
            let context = sharedModelContainer.mainContext
            threatEventListener = ThreatEventListener(modelContext: context)
            print("🛡️ Appdome threat event listener initialized")
        }
    }
}
