//
//  secureenclaveApp.swift
//  secureenclave
//
//  Created by shelchin on 2025/9/5.
//

import SwiftUI
import SwiftData

@main
struct secureenclaveApp: App {
    let modelContainer: ModelContainer
    
    init() {
        do {
            // Simple local-only container first to avoid blocking
            let schema = Schema([
                KeychainItem.self,
                OperationLog.self,
            ])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none  // Disable CloudKit for now
            )
            
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("Failed to create ModelContainer: \(error)")
            // Create in-memory container as last resort
            let schema = Schema([
                KeychainItem.self,
                OperationLog.self,
            ])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )
            modelContainer = try! ModelContainer(for: schema, configurations: [modelConfiguration])
        }
    }

    var body: some Scene {
        WindowGroup {
            ModernContentView()
        }
        .modelContainer(modelContainer)
    }
}
