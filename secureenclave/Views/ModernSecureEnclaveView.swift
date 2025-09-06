//
//  ModernSecureEnclaveView.swift
//  secureenclave
//
//  Created by shelchin on 2025/9/5.
//

import SwiftUI
import CryptoKit
import SwiftData
import UIKit

struct ModernSecureEnclaveView: View {
    @StateObject private var seManager = SecureEnclaveManager()
    @Environment(\.modelContext) private var modelContext
    @Query private var savedKeys: [KeychainItem]
    
    @State private var showingKeyDetail = false
    @State private var selectedKey: KeyData?
    @State private var isGenerating = false
    @State private var keyName = ""
    @State private var requireBiometry = true
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.05), Color.clear]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Status Card
                        statusCard
                        
                        // Generate Key Card
                        generateKeyCard
                        
                        // Saved Keys
                        if !savedKeys.isEmpty {
                            savedKeysSection
                        }
                        
                        // Operations Log
                        operationsLog
                    }
                    .padding()
                }
            }
            .navigationTitle("Secure Enclave")
            .sheet(item: $selectedKey) { keyData in
                KeyDetailView(keyData: keyData, seManager: seManager)
            }
        }
    }
    
    private var statusCard: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: seManager.isSecureEnclaveAvailable ? "lock.shield.fill" : "lock.trianglebadge.exclamationmark")
                    .font(.largeTitle)
                    .foregroundColor(seManager.isSecureEnclaveAvailable ? .green : .orange)
                
                VStack(alignment: .leading) {
                    Text("Secure Enclave")
                        .font(.headline)
                    Text(seManager.isSecureEnclaveAvailable ? "Available" : "Not Available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            if !seManager.isSecureEnclaveAvailable {
                Text("⚠️ Secure Enclave requires a physical device")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.top, 5)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
    }
    
    private var generateKeyCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Generate New Key")
                .font(.headline)
            
            TextField("Key Name", text: $keyName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Toggle(isOn: $requireBiometry) {
                HStack {
                    Image(systemName: "faceid")
                        .foregroundColor(.blue)
                    Text("Require Biometric Authentication")
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: .blue))
            
            Button(action: generateKey) {
                HStack {
                    if isGenerating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "key.fill")
                    }
                    Text("Generate Key")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(keyName.isEmpty || isGenerating)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
    }
    
    private var savedKeysSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Saved Keys (\(savedKeys.filter { $0.keyType == .secureEnclaveKey }.count))")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(savedKeys.filter { $0.keyType == .secureEnclaveKey }) { key in
                KeyCard(keychainItem: key) {
                    if let publicKeyData = key.publicKeyData {
                        selectedKey = KeyData(
                            id: key.id,
                            name: key.label,
                            tag: key.keyTag,
                            publicKeyData: publicKeyData,
                            createdAt: key.createdAt,
                            algorithm: key.algorithm,
                            isHardwareBacked: key.isHardwareBacked
                        )
                    }
                }
            }
        }
    }
    
    private var operationsLog: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Operations Log")
                    .font(.headline)
                Spacer()
                
                Button(action: {
                    let allLogs = seManager.logs.joined(separator: "\n")
                    UIPasteboard.general.string = allLogs
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "doc.on.doc")
                        Text("Copy All")
                    }
                    .font(.caption)
                }
                .buttonStyle(.borderless)
                
                Button("Clear") {
                    seManager.clearLogs()
                }
                .font(.caption)
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(Array(seManager.logs.suffix(10).enumerated()), id: \.offset) { _, log in
                        HStack {
                            Circle()
                                .fill(colorForLog(log))
                                .frame(width: 6, height: 6)
                            Text(log)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.primary)
                                .textSelection(.enabled)
                            Spacer()
                            Button(action: {
                                UIPasteboard.general.string = log
                            }) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.borderless)
                        }
                        .onTapGesture {
                            UIPasteboard.general.string = log
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 150)
            .padding()
            .background(Color(UIColor.tertiarySystemBackground))
            .cornerRadius(10)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
    }
    
    private func generateKey() {
        guard !keyName.isEmpty else { return }
        
        isGenerating = true
        let keyTag = "SE_\(UUID().uuidString.prefix(8))"
        
        DispatchQueue.global(qos: .userInitiated).async {
            let (privateKey, publicKeyData) = seManager.generateSecureEnclaveKey(
                tag: keyTag,
                requireBiometry: requireBiometry
            )
            
            DispatchQueue.main.async {
                if let publicKeyData = publicKeyData {
                    // Save to SwiftData
                    let keychainItem = KeychainItem(
                        label: keyName,
                        keyTag: keyTag,
                        keyType: .secureEnclaveKey,
                        accessControl: requireBiometry ? "biometryCurrentSet" : "privateKeyUsage"
                    )
                    keychainItem.publicKeyData = publicKeyData
                    keychainItem.isHardwareBacked = true
                    
                    modelContext.insert(keychainItem)
                    
                    // Show the detail
                    selectedKey = KeyData(
                        id: keychainItem.id,
                        name: keyName,
                        tag: keyTag,
                        publicKeyData: publicKeyData,
                        createdAt: Date(),
                        algorithm: "EC256",
                        isHardwareBacked: true
                    )
                }
                
                keyName = ""
                isGenerating = false
            }
        }
    }
    
    private func colorForLog(_ log: String) -> Color {
        if log.contains("✅") {
            return .green
        } else if log.contains("❌") {
            return .red
        } else if log.contains("⚠️") {
            return .orange
        } else {
            return .gray
        }
    }
}

struct KeyCard: View {
    let keychainItem: KeychainItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "key.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(keychainItem.label)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Created: \(keychainItem.createdAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if keychainItem.isHardwareBacked {
                        Label("Hardware", systemImage: "lock.shield.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(UIColor.tertiarySystemBackground))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
}

struct KeyData: Identifiable {
    let id: UUID
    let name: String
    let tag: String
    let publicKeyData: Data
    let createdAt: Date
    let algorithm: String
    let isHardwareBacked: Bool
}