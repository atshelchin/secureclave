//
//  KeyDetailView.swift
//  secureenclave
//
//  Created by shelchin on 2025/9/5.
//

import SwiftUI
import CryptoKit
import UIKit

struct KeyDetailView: View {
    let keyData: KeyData
    let seManager: SecureEnclaveManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    @State private var testMessage = "Hello, Secure Enclave!"
    @State private var signature: Data?
    @State private var verificationResult: Bool?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Key Info Card
                    keyInfoCard
                    
                    // Public Key Display
                    publicKeyCard
                    
                    // Test Operations
                    testOperationsCard
                    
                    // Actions
                    actionsCard
                }
                .padding()
            }
            .navigationTitle(keyData.name)
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
            ShareSheet(items: [getKeyInfoText()])
        }
    }
    
    private var keyInfoCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Key Information")
                .font(.headline)
            
            InfoItem(label: "Name", value: keyData.name)
            InfoItem(label: "Tag", value: keyData.tag)
            InfoItem(label: "Algorithm", value: keyData.algorithm)
            InfoItem(label: "Created", value: keyData.createdAt.formatted())
            InfoItem(label: "Hardware Backed", value: keyData.isHardwareBacked ? "Yes ✅" : "No ❌")
            InfoItem(label: "Key Size", value: "\(keyData.publicKeyData.count * 8) bits")
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
    }
    
    private var publicKeyCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Public Key")
                    .font(.headline)
                Spacer()
                Button(action: { showingShareSheet = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.blue)
                }
            }
            
            // Hex Display
            HStack {
                Text("Hex Format")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: {
                    UIPasteboard.general.string = keyData.publicKeyData.hexString
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "doc.on.doc")
                        Text("Copy")
                    }
                    .font(.caption)
                }
                .buttonStyle(.borderless)
            }
            
            ScrollView(.horizontal, showsIndicators: true) {
                Text(keyData.publicKeyData.hexString)
                    .font(.system(.caption, design: .monospaced))
                    .padding(10)
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(8)
                    .onTapGesture {
                        UIPasteboard.general.string = keyData.publicKeyData.hexString
                    }
            }
            
            // Base64 Display
            HStack {
                Text("Base64 Format")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: {
                    UIPasteboard.general.string = keyData.publicKeyData.base64EncodedString()
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "doc.on.doc")
                        Text("Copy")
                    }
                    .font(.caption)
                }
                .buttonStyle(.borderless)
            }
            .padding(.top, 5)
            
            ScrollView(.horizontal, showsIndicators: true) {
                Text(keyData.publicKeyData.base64EncodedString())
                    .font(.system(.caption, design: .monospaced))
                    .lineLimit(3)
                    .padding(10)
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(8)
                    .onTapGesture {
                        UIPasteboard.general.string = keyData.publicKeyData.base64EncodedString()
                    }
            }
            
            // Visual Representation
            Text("Visual Hash")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 5)
            
            VisualHashView(data: keyData.publicKeyData)
                .frame(height: 60)
                .cornerRadius(8)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
    }
    
    private var testOperationsCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Test Operations")
                .font(.headline)
            
            TextField("Test Message", text: $testMessage)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            HStack(spacing: 10) {
                Button(action: signMessage) {
                    Label("Sign", systemImage: "signature")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                Button(action: verifySignature) {
                    Label("Verify", systemImage: "checkmark.seal")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(signature == nil)
            }
            
            if let signature = signature {
                VStack(alignment: .leading, spacing: 10) {
                    // Signed Message (Payload) in Hex
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text("Payload (Hex)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button(action: {
                                UIPasteboard.general.string = testMessage.data(using: .utf8)?.hexString ?? ""
                            }) {
                                HStack(spacing: 3) {
                                    Image(systemName: "doc.on.doc")
                                    Text("Copy")
                                }
                                .font(.caption)
                            }
                            .buttonStyle(.borderless)
                        }
                        
                        Text((testMessage.data(using: .utf8)?.hexString.prefix(60) ?? "") + "...")
                            .font(.system(.caption2, design: .monospaced))
                            .padding(5)
                            .background(Color(UIColor.tertiarySystemBackground))
                            .cornerRadius(5)
                            .onTapGesture {
                                UIPasteboard.general.string = testMessage.data(using: .utf8)?.hexString ?? ""
                            }
                    }
                    
                    // Signature in Hex
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text("Signature (Hex)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button(action: {
                                UIPasteboard.general.string = signature.hexString
                            }) {
                                HStack(spacing: 3) {
                                    Image(systemName: "doc.on.doc")
                                    Text("Copy")
                                }
                                .font(.caption)
                            }
                            .buttonStyle(.borderless)
                        }
                        
                        Text(signature.hexString.prefix(60) + "...")
                            .font(.system(.caption2, design: .monospaced))
                            .padding(5)
                            .background(Color(UIColor.tertiarySystemBackground))
                            .cornerRadius(5)
                            .onTapGesture {
                                UIPasteboard.general.string = signature.hexString
                            }
                    }
                    
                    // Signature in Base64
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text("Signature (Base64)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button(action: {
                                UIPasteboard.general.string = signature.base64EncodedString()
                            }) {
                                HStack(spacing: 3) {
                                    Image(systemName: "doc.on.doc")
                                    Text("Copy")
                                }
                                .font(.caption)
                            }
                            .buttonStyle(.borderless)
                        }
                        
                        Text(signature.base64EncodedString().prefix(50) + "...")
                            .font(.system(.caption2, design: .monospaced))
                            .padding(5)
                            .background(Color(UIColor.tertiarySystemBackground))
                            .cornerRadius(5)
                            .onTapGesture {
                                UIPasteboard.general.string = signature.base64EncodedString()
                            }
                    }
                }
            }
            
            if let result = verificationResult {
                HStack {
                    Image(systemName: result ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(result ? .green : .red)
                    Text(result ? "Signature Valid" : "Signature Invalid")
                        .font(.caption)
                }
                .padding(8)
                .background(result ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
    }
    
    private var actionsCard: some View {
        VStack(spacing: 10) {
            Button(action: exportKey) {
                Label("Export Public Key", systemImage: "doc.on.doc")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            Button(action: deleteKey) {
                Label("Delete Key", systemImage: "trash")
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.red)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
    }
    
    private func signMessage() {
        guard let data = testMessage.data(using: .utf8) else { return }
        
        if let privateKey = seManager.retrieveKey(tag: keyData.tag) {
            signature = seManager.signData(data, with: privateKey)
        }
    }
    
    private func verifySignature() {
        guard let sig = signature,
              let data = testMessage.data(using: .utf8) else { return }
        
        // Create public key from data
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits as String: 256
        ]
        
        guard let publicKey = SecKeyCreateWithData(
            keyData.publicKeyData as CFData,
            attributes as CFDictionary,
            nil
        ) else { return }
        
        verificationResult = seManager.verifySignature(sig, for: data, with: publicKey)
    }
    
    private func exportKey() {
        showingShareSheet = true
    }
    
    private func deleteKey() {
        _ = seManager.deleteKey(tag: keyData.tag)
        dismiss()
    }
    
    private func getKeyInfoText() -> String {
        """
        Secure Enclave Key Export
        ========================
        Name: \(keyData.name)
        Tag: \(keyData.tag)
        Algorithm: \(keyData.algorithm)
        Created: \(keyData.createdAt.formatted())
        
        Public Key (Hex):
        \(keyData.publicKeyData.hexString)
        
        Public Key (Base64):
        \(keyData.publicKeyData.base64EncodedString())
        """
    }
}

struct InfoItem: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

struct VisualHashView: View {
    let data: Data
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(0..<min(data.count, 32), id: \.self) { index in
                    Rectangle()
                        .fill(Color(hue: Double(data[index]) / 255.0, saturation: 0.8, brightness: 0.8))
                        .frame(width: geometry.size.width / 32)
                }
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// Data extension moved to DataExtensions.swift