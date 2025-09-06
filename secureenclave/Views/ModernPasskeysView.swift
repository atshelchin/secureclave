//
//  ModernPasskeysView.swift
//  secureenclave
//
//  Created by shelchin on 2025/9/5.
//

import SwiftUI
import AuthenticationServices
import SwiftData
import UIKit
import Security
import CryptoKit

struct ModernPasskeysView: View {
    @StateObject private var passkeysManager = PasskeysManager()
    @Environment(\.modelContext) private var modelContext
    @Query private var allKeychainItems: [KeychainItem]
    
    @State private var username = ""
    @State private var showingDetail = false
    @State private var selectedPasskey: PasskeyData?
    @State private var isCreating = false
    @State private var isSigningIn = false
    @State private var showingSignature = false
    @State private var signatureMessage = "Test message for Passkey signature"
    @State private var signatureResult: Data?
    @State private var authenticatorData: Data?
    @State private var clientDataJSON: Data?
    @State private var currentChallenge: Data?
    @State private var currentPublicKey: Data?
    @State private var verificationResult: Bool?
    @State private var challengeIndex: Int?
    @State private var typeIndex: Int?
    @State private var userVerificationRequired: Bool = false
    @State private var copyFeedback = ""
    @State private var showCopyFeedback = false
    
    private var savedPasskeys: [KeychainItem] {
        allKeychainItems.filter { $0.keyType == .passkey }
    }
    
    // Listen for successful Passkey creation
    private let passkeyCreatedPublisher = NotificationCenter.default.publisher(
        for: Notification.Name("PasskeyCreatedSuccessfully")
    )
    
    // Listen for Passkey signature
    private let passkeySignaturePublisher = NotificationCenter.default.publisher(
        for: Notification.Name("PasskeySignatureCreated")
    )
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.05), Color.clear]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Domain Selector Card
                        domainSelectorCard
                        
                        // Domain Configuration Card
                        domainCard
                        
                        // Create Passkey Card
                        createPasskeyCard
                        
                        // Sign In Card
                        signInCard
                        
                        // Signature Test Card
                        signatureTestCard
                        
                        // Saved Passkeys
                        if !savedPasskeys.isEmpty {
                            savedPasskeysSection
                        }
                        
                        // Logs
                        logsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Passkeys")
            .sheet(item: $selectedPasskey) { passkeyData in
                PasskeyDetailView(passkeyData: passkeyData)
            }
            .onReceive(passkeyCreatedPublisher) { notification in
                handlePasskeyCreated(notification)
            }
            .onReceive(passkeySignaturePublisher) { notification in
                handlePasskeySignature(notification)
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
                        .padding(.top, 50)
                }
            }
        }
    }
    
    private func handlePasskeyCreated(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let credentialID = userInfo["credentialID"] as? Data,
              let rpID = userInfo["rpID"] as? String else {
            passkeysManager.log("❌ Invalid notification data")
            return
        }
        
        // Extract attestation object which contains public key
        let attestationObject = userInfo["attestationObject"] as? Data
        let rawClientData = userInfo["rawClientDataJSON"] as? Data
        let extractedPublicKey = userInfo["publicKey"] as? Data
        
        // Use the extracted public key from PasskeysManager
        var publicKeyData: Data? = extractedPublicKey
        
        if let publicKey = extractedPublicKey {
            passkeysManager.log("✅ Using extracted public key: \(publicKey.count) bytes")
            passkeysManager.log("🔑 Public Key (hex): \(publicKey.hexString)")
        } else if let attestation = attestationObject {
            passkeysManager.log("⚠️ No extracted public key, attestation size: \(attestation.count) bytes")
            passkeysManager.log("📦 Will save attestation for later parsing")
        }
        
        // Save to SwiftData with attestation object
        let keychainItem = KeychainItem(
            label: username,
            keyTag: "passkey_\(username)_\(Date().timeIntervalSince1970)",
            keyType: .passkey,
            algorithm: "ES256"  // Passkeys use ES256 (P-256 with SHA-256)
        )
        keychainItem.createdAt = Date()
        keychainItem.isHardwareBacked = true
        keychainItem.requiresBiometry = true
        keychainItem.relyingParty = rpID
        keychainItem.credentialID = credentialID
        keychainItem.publicKeyData = publicKeyData  // Store extracted public key
        keychainItem.attestationObject = attestationObject
        keychainItem.rawClientData = rawClientData
        
        modelContext.insert(keychainItem)
        
        // Log operation
        let operation = OperationLog(
            operation: "create_passkey",
            success: true,
            details: "Passkey created for \(username)"
        )
        operation.keychainItem = keychainItem
        
        modelContext.insert(operation)
        
        // Save to iCloud SwiftData
        do {
            try modelContext.save()
            passkeysManager.log("✅ Passkey saved to iCloud SwiftData with attestation object")
            if let attestationObject = attestationObject {
                passkeysManager.log("📝 Attestation object size: \(attestationObject.count) bytes (contains public key)")
            }
        } catch {
            passkeysManager.log("❌ Failed to save to SwiftData: \(error)")
        }
        
        // Clear username after successful creation
        username = ""
        isCreating = false
    }
    
    private var domainSelectorCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "globe")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                Text("Select RP ID Domain")
                    .font(.headline)
                
                Spacer()
            }
            
            Picker("Domain", selection: $passkeysManager.currentDomain) {
                ForEach(PasskeysManager.SupportedDomain.allCases, id: \.self) { domain in
                    HStack {
                        Text(domain.displayName)
                        Text("(\(domain.rawValue))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .tag(domain)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            HStack {
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundColor(.blue)
                Text("Current RP ID: \(passkeysManager.rpID)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if passkeysManager.currentDomain == .github {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text("CDN cache may have old Team ID")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
    }
    
    private var domainCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "network")
                    .font(.title2)
                    .foregroundColor(.purple)
                
                VStack(alignment: .leading) {
                    Text("Domain Configuration")
                        .font(.headline)
                    Text(passkeysManager.domain)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
            
            Text("Associated Domains")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Text("webcredentials:\(passkeysManager.domain)")
                    .font(.system(.caption, design: .monospaced))
                    .padding(8)
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(5)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
    }
    
    private var createPasskeyCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Create Passkey")
                .font(.headline)
            
            HStack {
                Image(systemName: "person.circle")
                    .foregroundColor(.purple)
                TextField("Username (e.g., user@example.com)", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
            }
            
            Button(action: createPasskey) {
                HStack {
                    if isCreating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "person.badge.plus")
                    }
                    Text("Create Passkey")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.purple, Color.purple.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(username.isEmpty || isCreating)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
    }
    
    private var signatureTestCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "signature")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                Text("Passkey Signature Test")
                    .font(.headline)
                
                Spacer()
            }
            
            // Message Input
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("Message to Sign")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button(action: {
                        copyToClipboard(signatureMessage, label: "Message")
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "doc.on.doc")
                            Text("Copy")
                        }
                        .font(.caption)
                    }
                    .buttonStyle(.borderless)
                }
                
                TextField("Enter message", text: $signatureMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(.body, design: .monospaced))
            }
            
            // Sign Button
            Button(action: signWithPasskey) {
                HStack {
                    Image(systemName: "pencil.circle.fill")
                    Text("Sign with Passkey")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.orange, Color.orange.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(signatureMessage.isEmpty || savedPasskeys.isEmpty)
            
            // Signature Result
            if let signature = signatureResult {
                VStack(alignment: .leading, spacing: 10) {
                    Divider()
                    
                    Text("📝 WebAuthn Verification Components")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                    
                    // 1. Challenge (original message as hex)
                    if let challenge = currentChallenge {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text("challenge: (Hex) - \(challenge.count * 2) chars")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button(action: {
                                    copyToClipboard("0x" + challenge.hexString, label: "Challenge")
                                }) {
                                    HStack(spacing: 3) {
                                        Image(systemName: "doc.on.doc")
                                        Text("Copy")
                                    }
                                    .font(.caption)
                                }
                                .buttonStyle(.borderless)
                            }
                            
                            Text("0x" + challenge.hexString.prefix(60) + "...")
                                .font(.system(.caption2, design: .monospaced))
                                .padding(5)
                                .background(Color(UIColor.tertiarySystemBackground))
                                .cornerRadius(5)
                                .onTapGesture {
                                    copyToClipboard("0x" + challenge.hexString, label: "Challenge")
                                }
                        }
                    }
                    
                    // 2. Public Key
                    if let publicKey = currentPublicKey {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text("publicKey: (Hex) - \(publicKey.count * 2) chars")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button(action: {
                                    copyToClipboard("0x" + publicKey.hexString, label: "Public Key")
                                }) {
                                    HStack(spacing: 3) {
                                        Image(systemName: "doc.on.doc")
                                        Text("Copy")
                                    }
                                    .font(.caption)
                                }
                                .buttonStyle(.borderless)
                            }
                            
                            Text("0x" + publicKey.hexString.prefix(60) + "...")
                                .font(.system(.caption2, design: .monospaced))
                                .padding(5)
                                .background(Color(UIColor.tertiarySystemBackground))
                                .cornerRadius(5)
                                .onTapGesture {
                                    copyToClipboard("0x" + publicKey.hexString, label: "Public Key")
                                }
                        }
                    }
                    
                    // 3. Authenticator Data (metadata part 1)
                    if let authData = authenticatorData {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text("authenticatorData: (Hex) - \(authData.count * 2) chars")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button(action: {
                                    copyToClipboard("0x" + authData.hexString, label: "Authenticator Data")
                                }) {
                                    HStack(spacing: 3) {
                                        Image(systemName: "doc.on.doc")
                                        Text("Copy")
                                    }
                                    .font(.caption)
                                }
                                .buttonStyle(.borderless)
                            }
                            
                            Text("0x" + authData.hexString.prefix(60) + "...")
                                .font(.system(.caption2, design: .monospaced))
                                .padding(5)
                                .background(Color(UIColor.tertiarySystemBackground))
                                .cornerRadius(5)
                                .onTapGesture {
                                    copyToClipboard("0x" + authData.hexString, label: "Authenticator Data")
                                }
                        }
                    }
                    
                    // 4. Client Data JSON (metadata part 2)
                    if let clientData = clientDataJSON {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text("clientDataJSON: (Base64)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button(action: {
                                    copyToClipboard(clientData.base64EncodedString(), label: "Client Data JSON")
                                }) {
                                    HStack(spacing: 3) {
                                        Image(systemName: "doc.on.doc")
                                        Text("Copy")
                                    }
                                    .font(.caption)
                                }
                                .buttonStyle(.borderless)
                            }
                            
                            if let jsonString = String(data: clientData, encoding: .utf8) {
                                Text(jsonString.prefix(100) + "...")
                                    .font(.system(.caption2, design: .monospaced))
                                    .padding(5)
                                    .background(Color(UIColor.tertiarySystemBackground))
                                    .cornerRadius(5)
                                    .onTapGesture {
                                        copyToClipboard(jsonString, label: "Client Data JSON")
                                    }
                            }
                        }
                    }
                    
                    // 5. Signature
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text("signature: (Hex) - \(signature.count * 2) chars")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button(action: {
                                copyToClipboard("0x" + signature.hexString, label: "Signature")
                            }) {
                                HStack(spacing: 3) {
                                    Image(systemName: "doc.on.doc")
                                    Text("Copy")
                                }
                                .font(.caption)
                            }
                            .buttonStyle(.borderless)
                        }
                        
                        Text("0x" + signature.hexString.prefix(60) + "...")
                            .font(.system(.caption2, design: .monospaced))
                            .padding(5)
                            .background(Color(UIColor.tertiarySystemBackground))
                            .cornerRadius(5)
                            .onTapGesture {
                                copyToClipboard("0x" + signature.hexString, label: "Signature")
                            }
                    }
                    
                    // Metadata Indexes
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Metadata Indexes (for ox library):")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 20) {
                            if let idx = challengeIndex {
                                Label("Challenge: \(idx)", systemImage: "number.circle")
                                    .font(.caption2)
                            }
                            if let idx = typeIndex {
                                Label("Type: \(idx)", systemImage: "number.circle")
                                    .font(.caption2)
                            }
                            Label("UV: \(userVerificationRequired ? "Yes" : "No")", systemImage: userVerificationRequired ? "checkmark.shield" : "xmark.shield")
                                .font(.caption2)
                        }
                        .padding(5)
                        .background(Color(UIColor.tertiarySystemBackground))
                        .cornerRadius(5)
                    }
                    
                    // Verification Result
                    if let isValid = verificationResult {
                        HStack {
                            Image(systemName: isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(isValid ? .green : .red)
                            Text("Verification: \(isValid ? "✅ VALID" : "❌ INVALID")")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(isValid ? .green : .red)
                        }
                        .padding(8)
                        .background(isValid ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Copy All as JSON
                    Button(action: {
                        copyAllVerificationData()
                    }) {
                        HStack {
                            Image(systemName: "doc.on.doc.fill")
                            Text("Copy All as JSON")
                        }
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(Color.purple.opacity(0.1))
                        .foregroundColor(.purple)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    // Info about signature format
                    HStack {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text("WebAuthn signs: authData || SHA256(clientDataJSON)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if savedPasskeys.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text("Create a Passkey first to test signatures")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
    }
    
    private var signInCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Authentication")
                .font(.headline)
            
            Button(action: signIn) {
                HStack {
                    if isSigningIn {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "person.badge.key")
                    }
                    Text("Sign In with Passkey")
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
            .disabled(isSigningIn)
            
            Text("Sign in using your saved passkey")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
    }
    
    private var savedPasskeysSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Saved Passkeys (\(savedPasskeys.count))")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(savedPasskeys) { passkey in
                PasskeyCard(keychainItem: passkey) {
                    selectedPasskey = PasskeyData(
                        id: passkey.id,
                        username: passkey.label,
                        relyingParty: passkey.relyingParty ?? passkeysManager.rpID,
                        createdAt: passkey.createdAt,
                        credentialID: passkey.credentialID,
                        userHandle: passkey.userHandle,
                        publicKeyData: passkey.publicKeyData,
                        attestationObject: passkey.attestationObject
                    )
                }
            }
        }
    }
    
    private var logsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Activity Log")
                    .font(.headline)
                Spacer()
                
                Button(action: {
                    let allLogs = passkeysManager.logs.joined(separator: "\n")
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
                    passkeysManager.clearLogs()
                }
                .font(.caption)
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(Array(passkeysManager.logs.suffix(10).enumerated()), id: \.offset) { _, log in
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
            .frame(height: 120)
            .padding()
            .background(Color(UIColor.tertiarySystemBackground))
            .cornerRadius(10)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
    }
    
    private func createPasskey() {
        guard !username.isEmpty else { return }
        
        isCreating = true
        
        // Don't save to SwiftData immediately - wait for success callback
        // The PasskeysManager will handle the actual creation
        passkeysManager.createPasskey(username: username)
        
        // Reset UI after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isCreating = false
            // Don't clear username yet - let user retry if needed
        }
    }
    
    private func signIn() {
        isSigningIn = true
        passkeysManager.signInWithPasskey()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isSigningIn = false
        }
    }
    
    private func signWithPasskey() {
        guard !signatureMessage.isEmpty else { return }
        
        // Use the sign-in flow with custom challenge (the message to sign)
        passkeysManager.log("")
        passkeysManager.log("===== PASSKEY SIGNATURE TEST =====")
        passkeysManager.log("📝 Message: \(signatureMessage)")
        passkeysManager.log("📏 Message length: \(signatureMessage.count) bytes")
        
        if let messageData = signatureMessage.data(using: .utf8) {
            passkeysManager.log("🔢 Message (hex): \(messageData.hexString.prefix(60))...")
            
            // Create SHA256 hash of the message for WebAuthn
            let messageHash = SHA256.hash(data: messageData)
            let hashData = Data(messageHash)
            
            passkeysManager.log("🔒 Message SHA256: \(hashData.hexString)")
            
            // Use the hash as challenge for WebAuthn
            // Note: WebAuthn will sign authenticatorData + clientDataHash
            passkeysManager.signInWithPasskey(customChallenge: hashData)
            
            passkeysManager.log("⏳ Waiting for WebAuthn response...")
            passkeysManager.log("⚠️ WebAuthn signs: authenticatorData + SHA256(clientDataJSON)")
            passkeysManager.log("⚠️ Not compatible with standard P256.verify()")
            passkeysManager.log("===== END SIGNATURE TEST =====")
        }
    }
    
    private func handlePasskeySignature(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let signature = userInfo["signature"] as? Data,
              let authData = userInfo["authenticatorData"] as? Data,
              let clientData = userInfo["clientDataJSON"] as? Data else {
            passkeysManager.log("❌ Invalid signature notification data")
            return
        }
        
        // Store all components
        signatureResult = signature
        self.authenticatorData = authData
        self.clientDataJSON = clientData
        
        // Store metadata indexes
        self.challengeIndex = userInfo["challengeIndex"] as? Int
        self.typeIndex = userInfo["typeIndex"] as? Int
        self.userVerificationRequired = userInfo["userVerificationRequired"] as? Bool ?? false
        
        // Extract challenge from clientDataJSON
        if let messageData = signatureMessage.data(using: .utf8) {
            let messageHash = SHA256.hash(data: messageData)
            self.currentChallenge = Data(messageHash)
            
            // Also log the original message for debugging
            passkeysManager.log("📝 Original message: \(signatureMessage)")
            passkeysManager.log("📝 Challenge (SHA256): \(messageHash.compactMap { String(format: "%02x", $0) }.joined())")
        }
        
        // Get public key from saved passkey
        if let firstPasskey = savedPasskeys.first {
            if let publicKey = firstPasskey.publicKeyData {
                self.currentPublicKey = publicKey
                
                passkeysManager.log("🔑 Using saved public key:")
                passkeysManager.log("  - Source: \(firstPasskey.label)")
                passkeysManager.log("  - Size: \(publicKey.count) bytes")
                passkeysManager.log("  - Hex: \(publicKey.hexString)")
                
                // Perform verification
                let isValid = passkeysManager.verifyWebAuthnSignature(
                    publicKey: publicKey,
                    signature: signature,
                    authenticatorData: authData,
                    clientDataJSON: clientData
                )
                self.verificationResult = isValid
                
                passkeysManager.log("")
                passkeysManager.log("📝 SIGNATURE VERIFICATION RESULT:")
                passkeysManager.log("  - Result: \(isValid ? "✅ VALID" : "❌ INVALID")")
                passkeysManager.log("  - Challenge Index: \(challengeIndex ?? -1)")
                passkeysManager.log("  - Type Index: \(typeIndex ?? -1)")
                passkeysManager.log("  - User Verification: \(userVerificationRequired)")
            } else {
                passkeysManager.log("❌ Passkey found but no public key data")
                passkeysManager.log("  - Label: \(firstPasskey.label)")
                passkeysManager.log("  - Created: \(firstPasskey.createdAt)")
                
                // Try to extract from attestation if available
                if let attestation = firstPasskey.attestationObject {
                    passkeysManager.log("  - Attestation available: \(attestation.count) bytes")
                    passkeysManager.log("  ⚠️ Public key was not extracted during creation!")
                }
            }
        } else {
            passkeysManager.log("❌ No saved passkey found")
        }
        
        passkeysManager.log("")
        passkeysManager.log("📋 ALL COMPONENTS AVAILABLE FOR COPY:")
        passkeysManager.log("  1. challenge (original message hash)")
        passkeysManager.log("  2. publicKey (from saved passkey)")
        passkeysManager.log("  3. authenticatorData (WebAuthn metadata)")
        passkeysManager.log("  4. clientDataJSON (contains challenge)")
        passkeysManager.log("  5. signature (DER encoded ECDSA)")
        passkeysManager.log("  6. metadata indexes (challengeIndex, typeIndex, userVerificationRequired)")
        passkeysManager.log("")
        passkeysManager.log("Use 'Copy All as JSON' button to export for external verification")
    }
    
    private func copyToClipboard(_ text: String, label: String) {
        UIPasteboard.general.string = text
        copyFeedback = "✅ Copied \(label)"
        showCopyFeedback = true
        
        // Hide feedback after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showCopyFeedback = false
        }
    }
    
    private func copyAllVerificationData() {
        var jsonData: [String: Any] = [:]
        
        if let challenge = currentChallenge {
            jsonData["challenge"] = "0x" + challenge.hexString
        }
        
        // Make sure we have the public key
        if let publicKey = currentPublicKey {
            jsonData["publicKey"] = "0x" + publicKey.hexString
        } else {
            // Try to get it from saved passkey if not in current state
            if let firstPasskey = savedPasskeys.first,
               let publicKey = firstPasskey.publicKeyData {
                jsonData["publicKey"] = "0x" + publicKey.hexString
                passkeysManager.log("⚠️ Using public key from saved passkey for export")
            } else {
                jsonData["publicKey"] = "MISSING - CHECK iOS LOGS"
                passkeysManager.log("❌ NO PUBLIC KEY AVAILABLE FOR EXPORT!")
            }
        }
        
        // Metadata for ox library
        var metadata: [String: Any] = [:]
        if let authData = authenticatorData {
            metadata["authenticatorData"] = "0x" + authData.hexString
        }
        if let clientData = clientDataJSON {
            metadata["clientDataJSON"] = clientData.base64EncodedString()
        }
        if let idx = challengeIndex {
            metadata["challengeIndex"] = idx
        }
        if let idx = typeIndex {
            metadata["typeIndex"] = idx
        }
        metadata["userVerificationRequired"] = userVerificationRequired
        
        jsonData["metadata"] = metadata
        
        if let signature = signatureResult {
            jsonData["signature"] = "0x" + signature.hexString
        }
        
        // Also include raw data for debugging
        if let authData = authenticatorData {
            jsonData["authenticatorData_raw"] = "0x" + authData.hexString
        }
        
        if let clientData = clientDataJSON {
            jsonData["clientDataJSON_raw"] = clientData.base64EncodedString()
            if let jsonString = String(data: clientData, encoding: .utf8) {
                jsonData["clientDataJSON_decoded"] = jsonString
            }
        }
        
        jsonData["message"] = signatureMessage
        jsonData["verificationResult"] = verificationResult ?? false
        
        // Create formatted JSON
        if let jsonData = try? JSONSerialization.data(withJSONObject: jsonData, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            copyToClipboard(jsonString, label: "All Verification Data")
            passkeysManager.log("✅ Copied all verification data as JSON (ox library compatible format)")
        }
    }
    
    private func colorForLog(_ log: String) -> Color {
        if log.contains("✅") {
            return .green
        } else if log.contains("❌") {
            return .red
        } else if log.contains("⚠️") {
            return .orange
        } else if log.contains("💡") {
            return .blue
        } else {
            return .gray
        }
    }
}

struct PasskeyCard: View {
    let keychainItem: KeychainItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "person.badge.key.fill")
                    .font(.title2)
                    .foregroundColor(.purple)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(keychainItem.label)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let rp = keychainItem.relyingParty {
                        Text(rp)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Created: \(keychainItem.createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(UIColor.tertiarySystemBackground))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
}

struct PasskeyData: Identifiable {
    let id: UUID
    let username: String
    let relyingParty: String
    let createdAt: Date
    let credentialID: Data?
    let userHandle: Data?
    let publicKeyData: Data?
    let attestationObject: Data?
}