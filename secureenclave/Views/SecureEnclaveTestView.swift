//
//  SecureEnclaveTestView.swift
//  secureenclave
//
//  Created by shelchin on 2025/9/5.
//

import SwiftUI
import SwiftData

struct SecureEnclaveTestView: View {
    @StateObject private var seManager = SecureEnclaveManager()
    @State private var keyTag = "TestKey_\(UUID().uuidString.prefix(8))"
    @State private var requireBiometry = false
    @State private var testData = "Hello Secure Enclave!"
    @State private var currentPrivateKey: SecKey?
    @State private var currentPublicKeyData: Data?
    @State private var signature: Data?
    
    @Environment(\.modelContext) private var modelContext
    @Query private var savedKeys: [KeychainItem]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Status Section
                statusSection
                
                // Key Generation Section
                keyGenerationSection
                
                // Key Operations Section
                if currentPrivateKey != nil {
                    keyOperationsSection
                }
                
                // Saved Keys Section
                savedKeysSection
                
                // Logs Section
                logsSection
            }
            .padding()
        }
        .navigationTitle("Secure Enclave Test")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Status")
                .font(.headline)
            
            HStack {
                Image(systemName: seManager.isSecureEnclaveAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(seManager.isSecureEnclaveAvailable ? .green : .red)
                Text("Secure Enclave: \(seManager.isSecureEnclaveAvailable ? "Available" : "Not Available")")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private var keyGenerationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Key Generation")
                .font(.headline)
            
            TextField("Key Tag", text: $keyTag)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Toggle("Require Biometry", isOn: $requireBiometry)
            
            HStack(spacing: 10) {
                Button(action: generateKey) {
                    Label("Generate Key", systemImage: "key.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                Button(action: authenticateWithBiometrics) {
                    Label("Test Biometry", systemImage: "faceid")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(10)
    }
    
    private var keyOperationsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Key Operations")
                .font(.headline)
            
            TextField("Test Data", text: $testData)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            HStack(spacing: 10) {
                Button(action: signData) {
                    Label("Sign Data", systemImage: "signature")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(currentPrivateKey == nil)
                
                Button(action: verifySignature) {
                    Label("Verify", systemImage: "checkmark.seal")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(signature == nil)
            }
            
            if let sig = signature {
                Text("Signature: \(sig.base64EncodedString().prefix(30))...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 10) {
                Button(action: retrieveKey) {
                    Label("Retrieve Key", systemImage: "arrow.down.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Button(action: deleteKey) {
                    Label("Delete Key", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .cornerRadius(10)
    }
    
    private var savedKeysSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Saved Keys (\(savedKeys.count))")
                    .font(.headline)
                Spacer()
                Button("List All") {
                    listAllKeys()
                }
                .font(.caption)
            }
            
            ForEach(savedKeys) { key in
                HStack {
                    VStack(alignment: .leading) {
                        Text(key.label)
                            .font(.subheadline)
                        Text(key.keyTag)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: key.isHardwareBacked ? "lock.circle.fill" : "lock.circle")
                        .foregroundColor(key.isHardwareBacked ? .green : .gray)
                }
                .padding(.horizontal)
                .padding(.vertical, 5)
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
                    seManager.clearLogs()
                }
                .font(.caption)
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(Array(seManager.logs.enumerated()), id: \.offset) { index, log in
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
    
    private func generateKey() {
        let (privateKey, publicKeyData) = seManager.generateSecureEnclaveKey(tag: keyTag, requireBiometry: requireBiometry)
        currentPrivateKey = privateKey
        currentPublicKeyData = publicKeyData
        
        if let publicKeyData = publicKeyData {
            // Save to SwiftData
            let keychainItem = KeychainItem(
                label: "SE Key \(Date().formatted(date: .abbreviated, time: .shortened))",
                keyTag: keyTag,
                keyType: .secureEnclaveKey,
                accessControl: requireBiometry ? "biometryCurrentSet" : "privateKeyUsage"
            )
            keychainItem.publicKeyData = publicKeyData
            keychainItem.isHardwareBacked = true
            
            modelContext.insert(keychainItem)
            
            // Generate new tag for next key
            keyTag = "TestKey_\(UUID().uuidString.prefix(8))"
        }
    }
    
    private func signData() {
        guard let privateKey = currentPrivateKey,
              let data = testData.data(using: .utf8) else { return }
        
        signature = seManager.signData(data, with: privateKey)
    }
    
    private func verifySignature() {
        guard let sig = signature,
              let publicKeyData = currentPublicKeyData,
              let data = testData.data(using: .utf8) else { return }
        
        // Create public key from data
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits as String: 256
        ]
        
        guard let publicKey = SecKeyCreateWithData(publicKeyData as CFData, attributes as CFDictionary, nil) else {
            seManager.log("Failed to recreate public key")
            return
        }
        
        _ = seManager.verifySignature(sig, for: data, with: publicKey)
    }
    
    private func retrieveKey() {
        currentPrivateKey = seManager.retrieveKey(tag: keyTag)
    }
    
    private func deleteKey() {
        _ = seManager.deleteKey(tag: keyTag)
        currentPrivateKey = nil
        currentPublicKeyData = nil
        signature = nil
    }
    
    private func authenticateWithBiometrics() {
        seManager.authenticateWithBiometrics { success, error in
            // Handle result
        }
    }
    
    private func listAllKeys() {
        _ = seManager.listAllKeys()
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