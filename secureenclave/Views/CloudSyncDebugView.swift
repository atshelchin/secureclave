//
//  CloudSyncDebugView.swift
//  secureenclave
//
//  Created by shelchin on 2025/9/5.
//

import SwiftUI
import SwiftData
import CloudKit

struct CloudSyncDebugView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allItems: [KeychainItem]
    @State private var iCloudStatus = "Checking..."
    @State private var syncLogs: [String] = []
    @State private var lastSyncDate: Date?
    @State private var pendingSyncCount = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // iCloud Status
                statusSection
                
                // Sync Statistics
                statsSection
                
                // Data Overview
                dataOverviewSection
                
                // Sync Actions
                syncActionsSection
                
                // Sync Logs
                logsSection
            }
            .padding()
        }
        .navigationTitle("iCloud Sync Debug")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkiCloudStatus()
        }
    }
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("iCloud Status")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: iCloudStatus == "Available" ? "checkmark.icloud.fill" : "exclamationmark.icloud.fill")
                        .foregroundColor(iCloudStatus == "Available" ? .green : .orange)
                    Text(iCloudStatus)
                        .fontWeight(.medium)
                }
                
                if let lastSync = lastSyncDate {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                        Text("Last Sync: \(lastSync.formatted())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(.blue)
                    Text("Pending: \(pendingSyncCount) items")
                        .font(.caption)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sync Statistics")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                StatCard(title: "Total Items", value: "\(allItems.count)", icon: "square.stack.3d.up", color: .blue)
                StatCard(title: "SE Keys", value: "\(allItems.filter { $0.keyType == .secureEnclaveKey }.count)", icon: "lock.circle", color: .green)
                StatCard(title: "Passkeys", value: "\(allItems.filter { $0.keyType == .passkey }.count)", icon: "person.badge.key", color: .purple)
                StatCard(title: "Regular Keys", value: "\(allItems.filter { $0.keyType == .regularKey }.count)", icon: "key", color: .orange)
            }
        }
    }
    
    private var dataOverviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Data Overview")
                .font(.headline)
            
            ForEach(allItems.prefix(5)) { item in
                HStack {
                    Image(systemName: iconForKeyType(item.keyType))
                        .foregroundColor(colorForKeyType(item.keyType))
                        .frame(width: 30)
                    
                    VStack(alignment: .leading) {
                        Text(item.label)
                            .font(.subheadline)
                        Text("Created: \(item.createdAt.formatted())")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "icloud.and.arrow.up")
                        .foregroundColor(.blue.opacity(0.5))
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            }
            
            if allItems.count > 5 {
                Text("... and \(allItems.count - 5) more items")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
        }
    }
    
    private var syncActionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sync Actions")
                .font(.headline)
            
            VStack(spacing: 10) {
                Button(action: forceSyncToCloud) {
                    Label("Force Sync to iCloud", systemImage: "icloud.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                Button(action: fetchFromCloud) {
                    Label("Fetch from iCloud", systemImage: "icloud.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Button(action: testCloudKitConnection) {
                    Label("Test CloudKit Connection", systemImage: "network")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Button(action: clearLocalData) {
                    Label("Clear Local Data", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(10)
    }
    
    private var logsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Sync Logs")
                    .font(.headline)
                Spacer()
                Button("Clear") {
                    syncLogs.removeAll()
                }
                .font(.caption)
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(Array(syncLogs.enumerated()), id: \.offset) { index, log in
                        Text(log)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(logColor(for: log))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 150)
            .padding(10)
            .background(Color.black.opacity(0.05))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Helper Methods
    
    private func checkiCloudStatus() {
        CKContainer.default().accountStatus { status, error in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    self.iCloudStatus = "Available"
                    self.log("✅ iCloud is available")
                case .noAccount:
                    self.iCloudStatus = "No iCloud Account"
                    self.log("❌ No iCloud account found")
                case .restricted:
                    self.iCloudStatus = "Restricted"
                    self.log("⚠️ iCloud is restricted")
                case .couldNotDetermine:
                    self.iCloudStatus = "Could Not Determine"
                    self.log("❌ Could not determine iCloud status")
                case .temporarilyUnavailable:
                    self.iCloudStatus = "Temporarily Unavailable"
                    self.log("⚠️ iCloud temporarily unavailable")
                @unknown default:
                    self.iCloudStatus = "Unknown"
                    self.log("❌ Unknown iCloud status")
                }
                
                if let error = error {
                    self.log("Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func forceSyncToCloud() {
        log("Forcing sync to iCloud...")
        
        // SwiftData with CloudKit automatically syncs, but we can try to save context
        do {
            try modelContext.save()
            log("✅ Context saved, sync initiated")
            lastSyncDate = Date()
            pendingSyncCount = 0
        } catch {
            log("❌ Failed to save context: \(error)")
        }
    }
    
    private func fetchFromCloud() {
        log("Fetching from iCloud...")
        
        // Create a fetch descriptor to refresh data
        let descriptor = FetchDescriptor<KeychainItem>()
        
        do {
            let items = try modelContext.fetch(descriptor)
            log("✅ Fetched \(items.count) items from store")
            lastSyncDate = Date()
        } catch {
            log("❌ Failed to fetch: \(error)")
        }
    }
    
    private func testCloudKitConnection() {
        log("Testing CloudKit connection...")
        
        let container = CKContainer(identifier: "iCloud.app.hotlabs.secureenclave")
        let database = container.privateCloudDatabase
        
        // Create a test query
        let query = CKQuery(recordType: "CD_KeychainItem", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "CD_createdAt", ascending: false)]
        
        database.fetch(withQuery: query, resultsLimit: 1) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let (matchResults, _)):
                    self.log("✅ CloudKit connection successful")
                    self.log("Found \(matchResults.count) record(s)")
                case .failure(let error):
                    self.log("❌ CloudKit error: \(error)")
                }
            }
        }
    }
    
    private func clearLocalData() {
        log("Clearing local data...")
        
        do {
            for item in allItems {
                modelContext.delete(item)
            }
            try modelContext.save()
            log("✅ Cleared \(allItems.count) items")
        } catch {
            log("❌ Failed to clear data: \(error)")
        }
    }
    
    private func log(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        syncLogs.append("[\(timestamp)] \(message)")
    }
    
    private func logColor(for log: String) -> Color {
        if log.contains("✅") {
            return .green
        } else if log.contains("❌") {
            return .red
        } else if log.contains("⚠️") {
            return .orange
        } else {
            return .primary
        }
    }
    
    private func iconForKeyType(_ type: KeyType) -> String {
        switch type {
        case .secureEnclaveKey:
            return "lock.circle.fill"
        case .passkey:
            return "person.badge.key.fill"
        case .regularKey:
            return "key.fill"
        }
    }
    
    private func colorForKeyType(_ type: KeyType) -> Color {
        switch type {
        case .secureEnclaveKey:
            return .green
        case .passkey:
            return .purple
        case .regularKey:
            return .orange
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}