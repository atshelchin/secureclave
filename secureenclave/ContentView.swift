//
//  ContentView.swift
//  secureenclave
//
//  Created by shelchin on 2025/9/5.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var keychainItems: [KeychainItem]

    var body: some View {
        NavigationView {
            List {
                Section("Security Features") {
                    NavigationLink(destination: SecureEnclaveTestView()) {
                        Label("Secure Enclave", systemImage: "lock.circle.fill")
                    }
                    
                    NavigationLink(destination: PasskeysTestView()) {
                        Label("Passkeys", systemImage: "person.badge.key.fill")
                    }
                    
                    NavigationLink(destination: CloudSyncDebugView()) {
                        Label("iCloud Sync Debug", systemImage: "icloud.circle.fill")
                    }
                }
                
                Section("Recent Keys (\(keychainItems.count))") {
                    ForEach(keychainItems.prefix(5)) { item in
                        HStack {
                            Image(systemName: iconForKeyType(item.keyType))
                                .foregroundColor(colorForKeyType(item.keyType))
                            
                            VStack(alignment: .leading) {
                                Text(item.label)
                                    .font(.subheadline)
                                Text(item.keyTag)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if item.isHardwareBacked {
                                Image(systemName: "lock.shield.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                            }
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
                
                Section("Debug Info") {
                    HStack {
                        Text("Total Keys")
                        Spacer()
                        Text("\(keychainItems.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("SE Keys")
                        Spacer()
                        Text("\(keychainItems.filter { $0.keyType == .secureEnclaveKey }.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Passkeys")
                        Spacer()
                        Text("\(keychainItems.filter { $0.keyType == .passkey }.count)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Secure Enclave Debug")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: clearAllData) {
                        Image(systemName: "trash")
                    }
                }
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(keychainItems[index])
            }
        }
    }
    
    private func clearAllData() {
        for item in keychainItems {
            modelContext.delete(item)
        }
    }
    
    private func iconForKeyType(_ type: KeyType) -> String {
        switch type {
        case .secureEnclaveKey:
            return "lock.circle"
        case .passkey:
            return "person.badge.key"
        case .regularKey:
            return "key"
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

#Preview {
    ContentView()
        .modelContainer(for: KeychainItem.self, inMemory: true)
}
