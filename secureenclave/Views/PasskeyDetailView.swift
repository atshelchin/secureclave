//
//  PasskeyDetailView.swift
//  secureenclave
//
//  Created by shelchin on 2025/9/5.
//

import SwiftUI
import UIKit

struct PasskeyDetailView: View {
    let passkeyData: PasskeyData
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    @State private var copyFeedback = ""
    @State private var showCopyFeedback = false
    
    private func copyToClipboard(_ text: String, label: String) {
        UIPasteboard.general.string = text
        copyFeedback = "✅ Copied \(label)"
        showCopyFeedback = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showCopyFeedback = false
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerView
                    
                    // Passkey Info
                    infoCard
                    
                    // Technical Details
                    technicalDetailsCard
                    
                    // Actions
                    actionsCard
                }
                .padding()
            }
            .navigationTitle("Passkey Details")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [getPasskeyInfoText()])
        }
        .overlay(alignment: .top) {
            if showCopyFeedback {
                Text(copyFeedback)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.green.opacity(0.9))
                    .foregroundColor(.white)
                    .cornerRadius(20)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: showCopyFeedback)
                    .padding(.top, 10)
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 15) {
            Image(systemName: "person.badge.key.fill")
                .font(.system(size: 60))
                .foregroundColor(.purple)
            
            Text(passkeyData.username)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(passkeyData.relyingParty)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.1), Color.clear]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(15)
    }
    
    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Passkey Information")
                .font(.headline)
            
            InfoItem(label: "Username", value: passkeyData.username)
            InfoItem(label: "Relying Party", value: passkeyData.relyingParty)
            InfoItem(label: "Created", value: passkeyData.createdAt.formatted())
            InfoItem(label: "Type", value: "Platform Authenticator")
            InfoItem(label: "Backed Up", value: "iCloud Keychain ✅")
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
    }
    
    private var technicalDetailsCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Technical Details")
                .font(.headline)
            
            // Public Key (if available)
            if let publicKey = passkeyData.publicKeyData {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("Public Key (Hex) - \(publicKey.count * 2) chars")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button(action: {
                            copyToClipboard(publicKey.hexString, label: "Public Key Hex")
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: "doc.on.doc")
                                Text("Copy")
                            }
                            .font(.caption)
                        }
                        .buttonStyle(.borderless)
                    }
                    Text(publicKey.hexString.prefix(60) + "...")
                        .font(.system(.caption, design: .monospaced))
                        .padding(8)
                        .background(Color(UIColor.tertiarySystemBackground))
                        .cornerRadius(5)
                        .onTapGesture {
                            copyToClipboard(publicKey.hexString, label: "Public Key Hex")
                        }
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("Public Key (Base64)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button(action: {
                            copyToClipboard(publicKey.base64EncodedString(), label: "Public Key Base64")
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: "doc.on.doc")
                                Text("Copy")
                            }
                            .font(.caption)
                        }
                        .buttonStyle(.borderless)
                    }
                    Text(publicKey.base64EncodedString().prefix(50) + "...")
                        .font(.system(.caption, design: .monospaced))
                        .padding(8)
                        .background(Color(UIColor.tertiarySystemBackground))
                        .cornerRadius(5)
                        .onTapGesture {
                            copyToClipboard(publicKey.base64EncodedString(), label: "Public Key Base64")
                        }
                }
            }
            
            if let credentialID = passkeyData.credentialID {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("Credential ID (Hex) - \(credentialID.count * 2) chars")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button(action: {
                            copyToClipboard(credentialID.hexString, label: "Credential ID Hex")
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: "doc.on.doc")
                                Text("Copy")
                            }
                            .font(.caption)
                        }
                        .buttonStyle(.borderless)
                    }
                    Text(credentialID.hexString.prefix(60) + "...")
                        .font(.system(.caption, design: .monospaced))
                        .padding(8)
                        .background(Color(UIColor.tertiarySystemBackground))
                        .cornerRadius(5)
                        .onTapGesture {
                            copyToClipboard(credentialID.hexString, label: "Credential ID Hex")
                        }
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("Credential ID (Base64)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(credentialID.base64EncodedString().prefix(50) + "...")
                        .font(.system(.caption, design: .monospaced))
                        .padding(8)
                        .background(Color(UIColor.tertiarySystemBackground))
                        .cornerRadius(5)
                }
            }
            
            if let userHandle = passkeyData.userHandle {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("User Handle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button(action: {
                            copyToClipboard(userHandle.base64EncodedString(), label: "User Handle")
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: "doc.on.doc")
                                Text("Copy")
                            }
                            .font(.caption)
                        }
                        .buttonStyle(.borderless)
                    }
                    Text(String(data: userHandle, encoding: .utf8) ?? userHandle.base64EncodedString())
                        .font(.system(.caption, design: .monospaced))
                        .padding(8)
                        .background(Color(UIColor.tertiarySystemBackground))
                        .cornerRadius(5)
                        .onTapGesture {
                            copyToClipboard(userHandle.base64EncodedString(), label: "User Handle")
                        }
                }
            }
            
            // Attestation Object info
            if let attestation = passkeyData.attestationObject {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("Attestation Object - \(attestation.count) bytes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button(action: {
                            copyToClipboard(attestation.hexString, label: "Attestation Hex")
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: "doc.on.doc")
                                Text("Copy Hex")
                            }
                            .font(.caption)
                        }
                        .buttonStyle(.borderless)
                    }
                    Text(attestation.hexString.prefix(60) + "...")
                        .font(.system(.caption, design: .monospaced))
                        .padding(8)
                        .background(Color(UIColor.tertiarySystemBackground))
                        .cornerRadius(5)
                        .onTapGesture {
                            copyToClipboard(attestation.hexString, label: "Attestation Hex")
                        }
                }
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text("Security Features")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 15) {
                    SecurityFeature(icon: "faceid", label: "Biometric")
                    SecurityFeature(icon: "lock.icloud", label: "Synced")
                    SecurityFeature(icon: "shield.fill", label: "Encrypted")
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
    }
    
    private var actionsCard: some View {
        VStack(spacing: 10) {
            Button(action: { showingShareSheet = true }) {
                Label("Export Details", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            Button(action: {}) {
                Label("View in Settings", systemImage: "gear")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
    }
    
    private func getPasskeyInfoText() -> String {
        """
        Passkey Details
        ===============
        Username: \(passkeyData.username)
        Relying Party: \(passkeyData.relyingParty)
        Created: \(passkeyData.createdAt.formatted())
        
        Credential ID:
        \(passkeyData.credentialID?.base64EncodedString() ?? "N/A")
        
        User Handle:
        \(passkeyData.userHandle != nil ? String(data: passkeyData.userHandle!, encoding: .utf8) ?? "N/A" : "N/A")
        
        Security:
        - Biometric Protection: Enabled
        - iCloud Sync: Enabled
        - Platform: iOS
        """
    }
}

struct SecurityFeature: View {
    let icon: String
    let label: String
    
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(8)
    }
}