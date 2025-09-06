//
//  PasskeysTestView.swift
//  secureenclave
//
//  Created by shelchin on 2025/9/5.
//

import SwiftUI
import SwiftData
import AuthenticationServices

struct PasskeysTestView: View {
    @StateObject private var passkeysManager = PasskeysManager()
    @State private var username = "testuser@atshelchin.github.io"
    @State private var showingCredentials = false
    
    @Environment(\.modelContext) private var modelContext
    @Query private var allKeychainItems: [KeychainItem]
    
    private var savedPasskeys: [KeychainItem] {
        allKeychainItems.filter { $0.keyType == .passkey }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Configuration Section
                configSection
                
                // Registration Section
                registrationSection
                
                // Authentication Section
                authenticationSection
                
                // Credentials Management
                credentialsSection
                
                // Saved Passkeys
                savedPasskeysSection
                
                // Logs Section
                logsSection
            }
            .padding()
        }
        .navigationTitle("Passkeys Test")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var configSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Configuration")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("Domain:")
                        .fontWeight(.medium)
                    Text(passkeysManager.domain)
                        .foregroundColor(.blue)
                }
                
                HStack {
                    Text("RP ID:")
                        .fontWeight(.medium)
                    Text(passkeysManager.rpID)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            Text("⚠️ Ensure apple-app-site-association is deployed at:")
                .font(.caption)
                .foregroundColor(.orange)
            Text("https://\(passkeysManager.domain)/.well-known/apple-app-site-association")
                .font(.caption2)
                .foregroundColor(.blue)
        }
    }
    
    private var registrationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Registration (Create Passkey)")
                .font(.headline)
            
            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
            
            Button(action: createPasskey) {
                Label("Create Passkey", systemImage: "person.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(10)
    }
    
    private var authenticationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Authentication")
                .font(.headline)
            
            VStack(spacing: 10) {
                Button(action: signIn) {
                    Label("Sign In with Passkey", systemImage: "person.badge.key")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                Button(action: setupAutoFill) {
                    Label("Setup AutoFill", systemImage: "keyboard")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .cornerRadius(10)
    }
    
    private var credentialsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Credential Management")
                .font(.headline)
            
            HStack(spacing: 10) {
                Button(action: listCredentials) {
                    Label("List Credentials", systemImage: "list.bullet")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Button(action: removeAllCredentials) {
                    Label("Remove All", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
            }
            
        }
        .padding()
        .background(Color.orange.opacity(0.05))
        .cornerRadius(10)
    }
    
    private var savedPasskeysSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Saved Passkeys in SwiftData (\(savedPasskeys.count))")
                .font(.headline)
            
            ForEach(savedPasskeys) { passkey in
                VStack(alignment: .leading, spacing: 5) {
                    Text(passkey.label)
                        .font(.subheadline)
                    if let rp = passkey.relyingParty {
                        Text("RP: \(rp)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let credID = passkey.credentialID {
                        Text("Credential: \(credID.base64EncodedString().prefix(30))...")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Text("Created: \(passkey.createdAt.formatted())")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            }
        }
    }
    
    private var logsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Logs")
                    .font(.headline)
                Spacer()
                Button("Clear") {
                    passkeysManager.clearLogs()
                }
                .font(.caption)
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(Array(passkeysManager.logs.enumerated()), id: \.offset) { index, log in
                        Text(log)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(logColor(for: log))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 200)
            .padding(10)
            .background(Color.black.opacity(0.05))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Actions
    
    private func createPasskey() {
        passkeysManager.createPasskey(username: username)
        
        // Save to SwiftData
        let passkeyItem = KeychainItem(
            label: "Passkey: \(username)",
            keyTag: "passkey_\(UUID().uuidString)",
            keyType: .passkey
        )
        passkeyItem.relyingParty = passkeysManager.rpID
        passkeyItem.userHandle = username.data(using: .utf8)
        
        modelContext.insert(passkeyItem)
    }
    
    private func signIn() {
        passkeysManager.signInWithPasskey()
    }
    
    private func setupAutoFill() {
        passkeysManager.performAutoFillAssistedRequests()
    }
    
    private func listCredentials() {
        passkeysManager.listStoredCredentials()
    }
    
    private func removeAllCredentials() {
        passkeysManager.removeAllCredentials()
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
}