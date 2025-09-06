//
//  PasskeysManager.swift
//  secureenclave
//
//  Created by shelchin on 2025/9/5.
//

import Foundation
import AuthenticationServices
import SwiftUI
import LocalAuthentication
import CryptoKit
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

class PasskeysManager: NSObject, ObservableObject {
    @Published var logs: [String] = []
    @Published var currentCredentials: [ASPasskeyCredentialIdentity] = []
    
    // Support multiple RP IDs
    enum SupportedDomain: String, CaseIterable {
        case github = "atshelchin.github.io"
        case github2 = "shelchin2025.github.io" // Alternative GitHub Pages
        
        var displayName: String {
            switch self {
            case .github: return "GitHub Pages (Main)"
            case .github2: return "GitHub Pages (2025)"
            }
        }
    }
    
    @Published var currentDomain: SupportedDomain = .github
    
    var domain: String { currentDomain.rawValue }
    var rpID: String { currentDomain.rawValue }
    
    override init() {
        super.init()
        log("PasskeysManager initialized with domain: \(domain)")
        checkDeviceCapabilities()
        performPrerequisitesCheck()
    }
    
    // MARK: - Prerequisites Check
    
    func checkiPhoneCache() {
        log("")
        log("===== iPhone LOCAL CACHE CHECK =====")
        log("🔍 Testing domain: \(domain)")
        log("📱 Expected Team ID: F9W689P9NE")
        log("")
        log("⚠️ If you see error with Team ID: 9RS8E64FWL")
        log("   → iPhone has OLD cached AASA")
        log("")
        log("🔄 To clear iPhone cache:")
        log("   1. Delete this app")
        log("   2. Settings → Safari → Clear History & Data")
        log("   3. Turn on Airplane Mode for 30 seconds")
        log("   4. Turn off Airplane Mode")
        log("   5. Reinstall the app")
        log("")
        log("💡 Or use 'GitHub Pages (2025)' domain instead")
        log("===== END CACHE CHECK =====")
        log("")
    }
    
    func checkAppleCDNStatus() {
        log("")
        log("===== CHECKING APPLE CDN STATUS =====")
        log("🔄 Fetching AASA from Apple CDN...")
        
        // Check Apple's CDN
        let cdnURL = URL(string: "https://app-site-association.cdn-apple.com/a/v1/\(domain)")!
        let task = URLSession.shared.dataTask(with: cdnURL) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    self.log("❌ CDN fetch error: \(error.localizedDescription)")
                    return
                }
                
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let webcredentials = json["webcredentials"] as? [String: Any],
                   let apps = webcredentials["apps"] as? [String] {
                    self.log("📱 Apple CDN AASA Content:")
                    for app in apps {
                        self.log("  - \(app)")
                        if app == "F9W689P9NE.app.hotlabs.secureenclave" {
                            self.log("  ✅ Correct Team ID found!")
                        } else if app.contains("9RS8E64FWL") {
                            self.log("  ❌ Old Team ID still cached!")
                            self.log("  ⏰ Cache typically refreshes in 24-48 hours")
                            self.log("  💡 Alternative: Use alternate mode or wait for cache refresh")
                        }
                    }
                } else {
                    self.log("⚠️ Could not parse CDN response")
                }
                
                // Also check direct URL
                self.log("")
                self.log("🔍 Checking direct GitHub Pages URL...")
                let directURL = URL(string: "https://\(self.domain)/.well-known/apple-app-site-association")!
                let directTask = URLSession.shared.dataTask(with: directURL) { data, _, error in
                    DispatchQueue.main.async {
                        if let data = data,
                           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let webcredentials = json["webcredentials"] as? [String: Any],
                           let apps = webcredentials["apps"] as? [String] {
                            self.log("📱 Direct GitHub Pages AASA:")
                            for app in apps {
                                self.log("  - \(app)")
                            }
                        }
                        self.log("===== END CDN STATUS CHECK =====")
                        self.log("")
                    }
                }
                directTask.resume()
            }
        }
        task.resume()
    }
    
    func performPrerequisitesCheck() {
        log("")
        log("===== PASSKEYS PREREQUISITES CHECK =====")
        
        var allChecksPassed = true
        
        // 1. iOS Version Check
        if #available(iOS 16.0, *) {
            log("✅ iOS 16.0+ detected - Passkeys API available")
        } else {
            log("❌ iOS 15 or lower - Passkeys require iOS 16+")
            allChecksPassed = false
        }
        
        // 2. Physical Device Check
        #if targetEnvironment(simulator)
        log("⚠️ Running on Simulator - Passkeys may not work properly")
        log("   Recommendation: Use physical device for testing")
        allChecksPassed = false
        #else
        log("✅ Running on physical device")
        #endif
        
        // 3. Associated Domains Configuration
        log("📱 Associated Domains Configuration:")
        log("   - Domain: \(domain)")
        log("   - RP ID: \(rpID)")
        log("   - Required: webcredentials:\(domain) in entitlements")
        log("   - AASA file: https://\(domain)/.well-known/apple-app-site-association")
        
        // 4. Biometric Enrollment Check
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            log("✅ Biometric authentication available")
        } else {
            log("⚠️ Biometric authentication not available: \(error?.localizedDescription ?? "Unknown")")
            log("   Note: Passkeys can still work with passcode")
        }
        
        // 5. Keychain Access
        log("✅ Keychain access available (required for Passkeys)")
        
        // 6. iCloud Sign-in Check
        if FileManager.default.ubiquityIdentityToken != nil {
            log("✅ iCloud account signed in")
        } else {
            log("⚠️ No iCloud account detected")
            log("   Note: Passkeys will be device-only without iCloud sync")
        }
        
        // 7. Network Connectivity (for AASA verification)
        log("📡 Network required for domain verification")
        
        // Summary
        log("")
        if allChecksPassed {
            log("✅ ALL PREREQUISITES MET - Passkeys should work")
        } else {
            log("⚠️ Some prerequisites not met - See warnings above")
        }
        log("===== END PREREQUISITES CHECK =====")
        log("")
    }
    
    private func checkDeviceCapabilities() {
        #if targetEnvironment(simulator)
        log("⚠️ Running on Simulator - Passkeys may have limited functionality")
        log("💡 For full Passkey testing, please use a physical device")
        #else
        log("✅ Running on physical device")
        #endif
        
        // Check if platform supports passkeys
        if #available(iOS 16.0, *) {
            log("✅ iOS 16+ detected - Passkeys supported")
        } else {
            log("❌ iOS version too old for Passkeys (requires iOS 16+)")
        }
    }
    
    // MARK: - Registration (Create Passkey)
    
    func createPasskey(username: String, userID: Data? = nil) {
        log("")
        log("========== PASSKEY CREATION START ==========")
        log("📝 Username: \(username)")
        log("🌐 Domain: \(domain)")
        log("🔑 RP ID: \(rpID)")
        log("📦 Bundle ID: \(Bundle.main.bundleIdentifier ?? "Unknown")")
        log("👥 Team ID: F9W689P9NE")
        
        // Verify configuration
        if domain != rpID {
            log("❌ CRITICAL: Domain (\(domain)) != RP ID (\(rpID))")
        }
        
        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: rpID)
        log("✅ Provider created with RP ID: \(rpID)")
        
        let userIDToUse = userID ?? username.data(using: .utf8)!
        let challenge = generateChallenge()
        
        log("📋 Creating registration request...")
        let registrationRequest = provider.createCredentialRegistrationRequest(
            challenge: challenge,
            name: username,
            userID: userIDToUse
        )
        log("✅ Registration request created")
        
        // Configure preferences  
        registrationRequest.userVerificationPreference = .preferred
        // Use .none for attestation as required by iOS
        registrationRequest.attestationPreference = .none
        
        log("⚙️ Configuration:")
        log("  - User Verification: preferred")
        log("  - Attestation: none")
        log("  📝 Note: Even with .none, rawAttestationObject should contain public key")
        
        let authController = ASAuthorizationController(authorizationRequests: [registrationRequest])
        authController.delegate = self
        authController.presentationContextProvider = self
        
        log("🚀 Starting registration flow...")
        log("⏳ Waiting for system UI...")
        log("⚠️ IMPORTANT: Public key extraction will occur after successful creation")
        log("🔍 Watch for 'PUBLIC KEY EXTRACTION DEBUG' messages in the log")
        authController.performRequests()
        log("✅ performRequests() called")
    }
    
    // MARK: - Authentication (Use Passkey)
    
    func signInWithPasskey() {
        signInWithPasskey(customChallenge: nil)
    }
    
    func signInWithPasskey(customChallenge: Data? = nil) {
        log("")
        log("========== PASSKEY SIGN-IN START ==========")
        log("🌐 Domain: \(domain)")
        log("🔑 RP ID: \(rpID)")
        
        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: rpID)
        log("✅ Provider created with RP ID: \(rpID)")
        
        // Use custom challenge for signature testing
        let challenge = customChallenge ?? generateChallenge()
        if let custom = customChallenge {
            log("📝 Using custom challenge (message to sign)")
            log("📏 Challenge size: \(custom.count) bytes")
            log("🔢 Challenge (hex): \(custom.map { String(format: "%02x", $0) }.joined().prefix(60))...")
        }
        log("📋 Creating assertion request...")
        
        let assertionRequest = provider.createCredentialAssertionRequest(challenge: challenge)
        log("✅ Assertion request created")
        
        // Optional: Allow password fallback
        let passwordProvider = ASAuthorizationPasswordProvider()
        let passwordRequest = passwordProvider.createRequest()
        log("📱 Including password fallback option")
        
        let authController = ASAuthorizationController(authorizationRequests: [assertionRequest, passwordRequest])
        authController.delegate = self
        authController.presentationContextProvider = self
        
        log("🚀 Presenting sign-in UI...")
        log("⏳ Waiting for user selection...")
        authController.performRequests()
        log("✅ performRequests() called for sign-in")
    }
    
    // MARK: - AutoFill Suggestions
    
    func performAutoFillAssistedRequests() {
        #if os(iOS)
        log("Setting up AutoFill assisted requests...")
        
        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: rpID)
        let challenge = generateChallenge()
        
        let assertionRequest = provider.createCredentialAssertionRequest(challenge: challenge)
        
        let authController = ASAuthorizationController(authorizationRequests: [assertionRequest])
        authController.delegate = self
        authController.presentationContextProvider = self
        
        authController.performAutoFillAssistedRequests()
        log("AutoFill setup complete")
        #else
        log("AutoFill not available on this platform")
        #endif
    }
    
    // MARK: - Credential Management
    
    func listStoredCredentials() {
        log("Fetching stored credentials...")
        
        // Note: ASCredentialIdentityStore is primarily for credential provider extensions
        // For regular apps, we can't directly list all stored passkeys
        // Instead, we'll track them in our SwiftData model
        log("⚠️ Direct credential listing requires credential provider extension")
        log("Use SwiftData to track created passkeys")
    }
    
    func removeAllCredentials() {
        log("Removing all credentials...")
        log("⚠️ Credential removal should be handled through Settings app")
        log("User can manage passkeys in Settings > Passwords")
    }
    
    // MARK: - Helper Methods
    
    private func generateChallenge() -> Data {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes)
    }
    
    func log(_ message: String) {
        // Print to Xcode console immediately
        print("[PasskeysManager] \(message)")
        
        // Also append to logs array for UI display
        DispatchQueue.main.async {
            let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
            self.logs.append("[\(timestamp)] \(message)")
        }
    }
    
    func clearLogs() {
        logs.removeAll()
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension PasskeysManager: ASAuthorizationControllerDelegate {
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        log("")
        log("🎉🎉🎉 AUTHORIZATION SUCCESS CALLBACK 🎉🎉🎉")
        log("Credential Type: \(type(of: authorization.credential))")
        
        switch authorization.credential {
        case let credentialRegistration as ASAuthorizationPlatformPublicKeyCredentialRegistration:
            // Handle successful registration
            log("===== PASSKEY REGISTRATION SUCCESS =====")
            log("✅ Passkey created successfully!")
            log("🔐 This passkey is now saved in iCloud Keychain")
            log("  - Credential ID: \(credentialRegistration.credentialID.base64EncodedString())")
            log("  - Credential ID (hex): \(credentialRegistration.credentialID.map { String(format: "%02x", $0) }.joined())")
            
            // Check for attestation object
            log("")
            log("🔍 Checking attestation object...")
            
            // Debug all available properties
            let hasAttestation = credentialRegistration.rawAttestationObject != nil
            log("  - rawAttestationObject: \(hasAttestation ? "✅ Present" : "❌ NIL")")
            
            if let attestationObject = credentialRegistration.rawAttestationObject {
                log("  - Size: \(attestationObject.count) bytes")
                log("")
                log("📦 ATTESTATION OBJECT FOUND!")
                log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                
                // Log full hex for analysis
                let hexString = attestationObject.map { String(format: "%02x", $0) }.joined()
                log("Full hex (\(attestationObject.count) bytes):")
                for i in stride(from: 0, to: hexString.count, by: 64) {
                    let endIndex = min(i + 64, hexString.count)
                    let startIdx = hexString.index(hexString.startIndex, offsetBy: i)
                    let endIdx = hexString.index(hexString.startIndex, offsetBy: endIndex)
                    log("  \(String(hexString[startIdx..<endIdx]))")
                }
                log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            } else {
                log("")
                log("❌ NO ATTESTATION OBJECT RECEIVED")
                log("This prevents public key extraction")
            }
            
            log("  - Raw Client Data: \(String(data: credentialRegistration.rawClientDataJSON, encoding: .utf8)?.prefix(100) ?? "N/A")...")
            
            // Now we can safely store to SwiftData with public key
            storeCredentialToSwiftData(credentialRegistration)
            
            // Store credential info for backend
            storeCredential(credentialRegistration)
            
        case let credentialAssertion as ASAuthorizationPlatformPublicKeyCredentialAssertion:
            // Handle successful authentication
            log("===== PASSKEY AUTHENTICATION SUCCESS =====")
            log("✅ Passkey authentication successful!")
            log("  - User ID: \(credentialAssertion.userID.base64EncodedString())")
            log("  - Credential ID: \(credentialAssertion.credentialID.base64EncodedString())")
            
            // Signature details
            log("")
            log("📝 SIGNATURE DETAILS:")
            log("  - Signature (DER): \(credentialAssertion.signature.map { String(format: "%02x", $0) }.joined())")
            log("  - Signature length: \(credentialAssertion.signature.count) bytes")
            log("  - Signature (Base64): \(credentialAssertion.signature.base64EncodedString())")
            
            // Raw authenticator data (includes signature counter, etc)
            log("")
            log("🔐 RAW AUTHENTICATOR DATA:")
            log("  - Auth Data: \(credentialAssertion.rawAuthenticatorData.map { String(format: "%02x", $0) }.joined().prefix(100))...")
            log("  - Auth Data length: \(credentialAssertion.rawAuthenticatorData.count) bytes")
            
            // Client data JSON
            log("")
            log("📄 CLIENT DATA:")
            if let clientDataString = String(data: credentialAssertion.rawClientDataJSON, encoding: .utf8) {
                log("  - Client Data JSON: \(clientDataString)")
            }
            log("  - Client Data (hex): \(credentialAssertion.rawClientDataJSON.map { String(format: "%02x", $0) }.joined().prefix(100))...")
            
            // Extract metadata for ox library compatibility
            var challengeIndex: Int? = nil
            var typeIndex: Int? = nil
            var userVerificationRequired = false
            
            if let clientDataString = String(data: credentialAssertion.rawClientDataJSON, encoding: .utf8) {
                // Find challenge index in clientDataJSON
                if let range = clientDataString.range(of: "\"challenge\"") {
                    challengeIndex = clientDataString.distance(from: clientDataString.startIndex, to: range.lowerBound)
                }
                
                // Find type index in clientDataJSON
                if let range = clientDataString.range(of: "\"type\"") {
                    typeIndex = clientDataString.distance(from: clientDataString.startIndex, to: range.lowerBound)
                }
            }
            
            // Extract user verification from authenticatorData flags
            if credentialAssertion.rawAuthenticatorData.count > 32 {
                let flags = credentialAssertion.rawAuthenticatorData[32]
                userVerificationRequired = (flags & 0x04) != 0 // UV flag is bit 2
                
                log("📊 Authenticator Flags: 0x\(String(format: "%02x", flags))")
                log("  - User Present (UP): \((flags & 0x01) != 0)")
                log("  - User Verified (UV): \(userVerificationRequired)")
                log("  - Backup Eligibility (BE): \((flags & 0x08) != 0)")
                log("  - Backup State (BS): \((flags & 0x10) != 0)")
            }
            
            // Post notification with signature data and metadata
            NotificationCenter.default.post(
                name: Notification.Name("PasskeySignatureCreated"),
                object: nil,
                userInfo: [
                    "signature": credentialAssertion.signature as Data,
                    "authenticatorData": credentialAssertion.rawAuthenticatorData as Data,
                    "clientDataJSON": credentialAssertion.rawClientDataJSON as Data,
                    "credentialID": credentialAssertion.credentialID as Data,
                    "challengeIndex": challengeIndex as Any,
                    "typeIndex": typeIndex as Any,
                    "userVerificationRequired": userVerificationRequired
                ]
            )
            
            log("")
            log("⚠️ NOTE: WebAuthn signatures include authenticatorData + clientDataHash")
            log("⚠️ Not directly compatible with standard ECDSA verification")
            log("===== END AUTHENTICATION =====")
            
        case let passwordCredential as ASPasswordCredential:
            // Handle password credential
            log("✅ Password credential received")
            log("  - User: \(passwordCredential.user)")
            
        default:
            log("⚠️ Unknown credential type received: \(type(of: authorization.credential))")
        }
        
        // Refresh credential list
        listStoredCredentials()
    }
    
    private func extractPublicKeyFromAttestationObject(_ attestationObject: Data) -> Data? {
        // The attestation object is CBOR encoded
        // Structure: map { "fmt": "none", "attStmt": {}, "authData": bytes }
        
        guard attestationObject.count > 37 else { 
            log("❌ Attestation object too small: \(attestationObject.count) bytes")
            return nil 
        }
        
        // Log the attestation object for debugging
        log("")
        log("🔍🔍🔍 PUBLIC KEY EXTRACTION DEBUG 🔍🔍🔍")
        log("📊 Attestation Object Size: \(attestationObject.count) bytes")
        
        // Log the entire attestation object in hex for analysis
        let hexString = attestationObject.map { String(format: "%02x", $0) }.joined()
        log("📝 Full Attestation Object (hex):")
        // Log in chunks of 64 characters for readability
        for i in stride(from: 0, to: hexString.count, by: 64) {
            let endIndex = min(i + 64, hexString.count)
            let startIndex = hexString.index(hexString.startIndex, offsetBy: i)
            let endIdx = hexString.index(hexString.startIndex, offsetBy: endIndex)
            log("    \(String(hexString[startIndex..<endIdx]))")
        }
        
        // Find authData in CBOR structure
        // Look for "authData" key pattern: 0x68617574684461746158 followed by length byte
        let authDataPattern = Data([0x68, 0x61, 0x75, 0x74, 0x68, 0x44, 0x61, 0x74, 0x61, 0x58]) // "authData" + 0x58 (byte string marker)
        
        var authDataStart = -1
        for i in 0..<(attestationObject.count - authDataPattern.count) {
            if attestationObject.subdata(in: i..<(i + authDataPattern.count)) == authDataPattern {
                // Found "authData" key, skip it and the length byte (0x98 = 152 bytes)
                authDataStart = i + authDataPattern.count + 1
                log("📍 Found authData at offset \(authDataStart)")
                break
            }
        }
        
        guard authDataStart >= 0 && authDataStart < attestationObject.count else {
            log("❌ Could not find authData in attestation object")
            return nil
        }
        
        let authData = attestationObject.subdata(in: authDataStart..<attestationObject.count)
        
        // Parse AuthData structure
        log("")
        log("📊 AuthData Structure Analysis:")
        guard authData.count >= 37 else {
            log("❌ AuthData too small")
            return nil
        }
        
        log("  [0-31]  RP ID Hash: \(authData.prefix(32).map { String(format: "%02x", $0) }.joined())")
        log("  [32]    Flags: 0x\(String(format: "%02x", authData[32]))")
        let flags = authData[32]
        log("          - UP (User Present): \((flags & 0x01) != 0)")
        log("          - UV (User Verified): \((flags & 0x04) != 0)")
        log("          - AT (Attested Credential): \((flags & 0x40) != 0)")
        log("          - ED (Extension Data): \((flags & 0x80) != 0)")
        log("  [33-36] Counter: \(authData.subdata(in: 33..<37).map { String(format: "%02x", $0) }.joined())")
        
        // Check if AT flag is set (credential data present)
        if (flags & 0x40) == 0 {
            log("❌ AT flag not set - No attested credential data present")
            return nil
        }
        
        // Parse Attested Credential Data if present
        if authData.count > 37 {
            var offset = 37
            
            // AAGUID (16 bytes)
            if offset + 16 <= authData.count {
                let aaguid = authData.subdata(in: offset..<(offset + 16))
                log("  [37-52] AAGUID: \(aaguid.map { String(format: "%02x", $0) }.joined())")
                offset += 16
            }
            
            // Credential ID Length (2 bytes, big-endian)
            if offset + 2 <= authData.count {
                let credIDLenBytes = authData.subdata(in: offset..<(offset + 2))
                let credIDLen = Int(credIDLenBytes[0]) << 8 | Int(credIDLenBytes[1])
                log("  [\(offset)-\(offset+1)] Credential ID Length: \(credIDLen) bytes")
                offset += 2
                
                // Credential ID
                if offset + credIDLen <= authData.count {
                    let credID = authData.subdata(in: offset..<(offset + credIDLen))
                    log("  [\(offset)-\(offset+credIDLen-1)] Credential ID: \(credID.prefix(32).map { String(format: "%02x", $0) }.joined())...")
                    offset += credIDLen
                    
                    // Public Key in COSE format starts here
                    log("")
                    log("🔑 PUBLIC KEY LOCATION: Starting at byte \(offset)")
                    if offset < authData.count {
                        let remaining = authData.subdata(in: offset..<authData.count)
                        log("📝 Public Key COSE Data (\(remaining.count) bytes):")
                        let pkHex = remaining.prefix(200).map { String(format: "%02x", $0) }.joined()
                        for i in stride(from: 0, to: pkHex.count, by: 64) {
                            let endIndex = min(i + 64, pkHex.count)
                            let startIdx = pkHex.index(pkHex.startIndex, offsetBy: i)
                            let endIdx = pkHex.index(pkHex.startIndex, offsetBy: endIndex)
                            log("    \(String(pkHex[startIdx..<endIdx]))")
                        }
                        
                        // Try to parse COSE key
                        if let publicKey = parseCOSEKey(from: remaining) {
                            log("")
                            log("✅✅✅ SUCCESSFULLY EXTRACTED PUBLIC KEY ✅✅✅")
                            log("🔑 Public Key (65 bytes, hex): \(publicKey.map { String(format: "%02x", $0) }.joined())")
                            log("🔑 Public Key (65 bytes, 0x prefix): 0x\(publicKey.map { String(format: "%02x", $0) }.joined())")
                            log("")
                            return publicKey
                        }
                    }
                }
            }
        }
        
        // Fallback: Look for uncompressed P-256 public key (0x04 followed by 64 bytes)
        log("")
        log("⚠️ Falling back to pattern search for uncompressed key...")
        for i in 0..<(attestationObject.count - 65) {
            if attestationObject[i] == 0x04 {
                // Check if the next 64 bytes could be a valid P-256 public key
                let potentialKey = attestationObject.subdata(in: i..<(i + 65))
                
                // Basic validation: check if it looks like a valid EC point
                if potentialKey.count == 65 {
                    log("✅ Found uncompressed P-256 public key at offset \(i)")
                    log("🔑 Public Key (65 bytes): 0x\(potentialKey.map { String(format: "%02x", $0) }.joined())")
                    return potentialKey
                }
            }
        }
        
        log("")
        log("❌❌❌ FAILED TO EXTRACT PUBLIC KEY ❌❌❌")
        log("💡 Possible reasons:")
        log("   1. Attestation format not recognized")
        log("   2. COSE encoding different than expected")
        log("   3. Key not in uncompressed format")
        log("")
        return nil
    }
    
    private func parseCOSEKey(from data: Data) -> Data? {
        // COSE key is CBOR encoded map
        // For P-256 (ES256), we expect:
        // kty: 2 (EC2)
        // alg: -7 (ES256)
        // crv: 1 (P-256)
        // x: 32 bytes
        // y: 32 bytes
        
        guard data.count >= 77 else { 
            log("⚠️ COSE data too small: \(data.count) bytes")
            return nil 
        }
        
        // Common COSE key patterns for P-256
        // Looking for x and y coordinates (32 bytes each)
        
        var x: Data?
        var y: Data?
        
        // Pattern 1: Look for CBOR byte string markers (0x58 0x20 = byte string of 32 bytes)
        for i in 0..<(data.count - 34) {
            if data[i] == 0x58 && data[i+1] == 0x20 {
                let candidate = data.subdata(in: (i+2)..<(i+34))
                if x == nil {
                    x = candidate
                    log("📍 Found X coordinate at offset \(i): \(candidate.map { String(format: "%02x", $0) }.joined())")
                } else if y == nil {
                    y = candidate
                    log("📍 Found Y coordinate at offset \(i): \(candidate.map { String(format: "%02x", $0) }.joined())")
                    break
                }
            }
        }
        
        // Pattern 2: Look for labeled coordinates (-2 for x, -3 for y in COSE)
        // -2 in CBOR is 0x21, -3 is 0x22
        if x == nil || y == nil {
            for i in 0..<(data.count - 35) {
                // Look for -2 (x coordinate)
                if data[i] == 0x21 && data[i+1] == 0x58 && data[i+2] == 0x20 {
                    x = data.subdata(in: (i+3)..<(i+35))
                    log("📍 Found X with label -2 at offset \(i): \(x!.map { String(format: "%02x", $0) }.joined())")
                }
                // Look for -3 (y coordinate)
                else if data[i] == 0x22 && data[i+1] == 0x58 && data[i+2] == 0x20 {
                    y = data.subdata(in: (i+3)..<(i+35))
                    log("📍 Found Y with label -3 at offset \(i): \(y!.map { String(format: "%02x", $0) }.joined())")
                }
            }
        }
        
        // If we found both coordinates, construct the uncompressed public key
        if let xCoord = x, let yCoord = y {
            var publicKey = Data([0x04]) // Uncompressed format prefix
            publicKey.append(xCoord)
            publicKey.append(yCoord)
            log("✅ Successfully parsed COSE key")
            return publicKey
        }
        
        log("⚠️ Could not parse COSE key - coordinates not found")
        log("  X coordinate: \(x != nil ? "Found" : "Missing")")
        log("  Y coordinate: \(y != nil ? "Found" : "Missing")")
        
        // If we have X but not Y, try to find Y after X
        if let xCoord = x, y == nil {
            log("🔍 Have X, looking for Y after X coordinate...")
            
            // Find where X appears in the data
            for i in 0..<data.count {
                if i + 32 <= data.count {
                    let chunk = data.subdata(in: i..<(i+32))
                    if chunk == xCoord {
                        log("  Found X at offset \(i)")
                        // Look for Y after X (might have 0x22 0x58 0x20 prefix or be direct)
                        let afterX = i + 32
                        
                        // Check for Y with label
                        if afterX + 35 <= data.count && 
                           data[afterX] == 0x22 && 
                           data[afterX+1] == 0x58 && 
                           data[afterX+2] == 0x20 {
                            y = data.subdata(in: (afterX+3)..<(afterX+35))
                            log("  Found Y with label after X: \(y!.map { String(format: "%02x", $0) }.joined())")
                        }
                        // Check for Y without label  
                        else if afterX + 32 <= data.count {
                            // Verify it looks like a coordinate (not metadata)
                            let potentialY = data.subdata(in: afterX..<(afterX+32))
                            // Skip if it starts with CBOR structure bytes
                            if potentialY[0] != 0xa5 && potentialY[0] != 0xa4 && potentialY[0] != 0xa3 {
                                y = potentialY
                                log("  Found Y directly after X: \(y!.map { String(format: "%02x", $0) }.joined())")
                            }
                        }
                        break
                    }
                }
            }
        }
        
        // Try again with found coordinates
        if let xCoord = x, let yCoord = y {
            var publicKey = Data([0x04]) // Uncompressed format prefix
            publicKey.append(xCoord)
            publicKey.append(yCoord)
            log("✅ Successfully parsed COSE key after second attempt")
            return publicKey
        }
        
        log("❌ Failed to extract both X and Y coordinates from COSE key")
        return nil
    }
    
    private func storeCredentialToSwiftData(_ credential: ASAuthorizationPlatformPublicKeyCredentialRegistration) {
        // This is where we actually save to SwiftData after successful creation
        // Extract all available data from the credential
        var userInfo: [String: Any] = [
            "credentialID": credential.credentialID,
            "rpID": rpID,
            "rawClientDataJSON": credential.rawClientDataJSON
        ]
        
        // Add attestation object and extract public key
        if let attestationObject = credential.rawAttestationObject {
            userInfo["attestationObject"] = attestationObject
            log("📝 Attestation object captured (\(attestationObject.count) bytes)")
            
            // Try to extract the public key
            if let publicKey = extractPublicKeyFromAttestationObject(attestationObject) {
                userInfo["publicKey"] = publicKey
                log("")
                log("✅✅✅ PUBLIC KEY EXTRACTION SUCCESS ✅✅✅")
                log("🔑 Extracted Public Key Details:")
                log("   - Format: Uncompressed P-256")
                log("   - Size: \(publicKey.count) bytes")
                log("   - Hex (with 0x): 0x\(publicKey.map { String(format: "%02x", $0) }.joined())")
                log("   - Hex (no prefix): \(publicKey.map { String(format: "%02x", $0) }.joined())")
                log("")
                log("📝 This public key will be saved to iCloud SwiftData")
                log("⚠️ IMPORTANT: Save this public key for verification!")
                log("")
            } else {
                log("")
                log("❌❌❌ PUBLIC KEY EXTRACTION FAILED ❌❌❌")
                log("⚠️ Passkey created but public key could not be extracted")
                log("⚠️ Signature verification will not be possible")
                log("")
            }
            
            log("⚠️ CRITICAL: Saving credential data to iCloud SwiftData")
        } else {
            log("⚠️ WARNING: Attestation object not available in credential response")
        }
        
        NotificationCenter.default.post(
            name: Notification.Name("PasskeyCreatedSuccessfully"),
            object: nil,
            userInfo: userInfo
        )
        
        log("📝 Posted notification for SwiftData storage with public key")
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        log("")
        log("❌❌❌ AUTHORIZATION ERROR CALLBACK ❌❌❌")
        log("Error Type: \(type(of: error))")
        log("Error Domain: \((error as NSError).domain)")
        log("Error Code: \((error as NSError).code)")
        log("Error Description: \(error.localizedDescription)")
        log("")
        log("📱 Configuration Check:")
        log("  Bundle ID: \(Bundle.main.bundleIdentifier ?? "nil")")
        log("  Team ID: F9W689P9NE")
        log("  RP ID: \(rpID)")
        log("  Expected AASA: F9W689P9NE.\(Bundle.main.bundleIdentifier ?? "unknown")")
        
        let userInfo = (error as NSError).userInfo
        log("Error UserInfo: \(userInfo)")
        
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                log("❌ User canceled the operation")
            case .failed:
                log("❌ Authentication failed - Check if Associated Domains is configured")
                log("💡 Verify: https://\(rpID)/.well-known/apple-app-site-association")
            case .invalidResponse:
                log("❌ Invalid response from authenticator")
                log("💡 This might indicate a domain configuration issue")
            case .notHandled:
                log("❌ Request not handled")
                log("💡 The system couldn't process this request")
            case .notInteractive:
                log("❌ Non-interactive request failed")
            case .unknown:
                log("❌ Unknown error occurred")
                log("💡 Check device settings and network connection")
            @unknown default:
                // Code 1004 and other undocumented errors
                if authError.code.rawValue == 1004 {
                    log("⚠️ No passkeys found for domain: \(rpID)")
                    log("💡 This is normal for sign-in if no passkey exists yet")
                } else if authError.code.rawValue == 1001 {
                    log("❌ The operation couldn't be completed")
                    log("💡 Check Associated Domains entitlement")
                } else {
                    log("❌ Unexpected error code \(authError.code.rawValue)")
                    log("Description: \(authError.localizedDescription)")
                }
            }
        } else {
            log("❌ Non-ASAuthorizationError: \(error)")
            
            // Check for common issues
            if error.localizedDescription.contains("interrupted") {
                log("💡 The request was interrupted - try again")
            } else if error.localizedDescription.contains("network") {
                log("💡 Network issue - check internet connection")
            }
        }
        
        log("===== END ERROR DEBUG ======")
    }
    
    private func storeCredential(_ credential: ASAuthorizationPlatformPublicKeyCredentialRegistration) {
        // Here you would typically store the credential in your backend
        // For debugging purposes, we'll just log it
        log("Storing credential in SwiftData...")
        
        // Convert to your data model and save
        // This would interact with your SwiftData model
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension PasskeysManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        #if os(iOS)
        // Return the current window for iOS
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            fatalError("No window found")
        }
        return window
        #else
        // For macOS or other platforms
        if let window = NSApplication.shared.windows.first {
            return window
        } else {
            fatalError("No window found")
        }
        #endif
    }
    
    // MARK: - WebAuthn Signature Verification
    
    func reconstructWebAuthnSignedData(authenticatorData: Data, clientDataJSON: Data) -> Data {
        let clientDataHash = SHA256.hash(data: clientDataJSON)
        return authenticatorData + Data(clientDataHash)
    }
    
    func verifyWebAuthnSignature(
        publicKey: Data,
        signature: Data,
        authenticatorData: Data,
        clientDataJSON: Data
    ) -> Bool {
        do {
            // Reconstruct the actual signed data (authenticatorData || SHA256(clientDataJSON))
            let signedData = reconstructWebAuthnSignedData(
                authenticatorData: authenticatorData,
                clientDataJSON: clientDataJSON
            )
            
            log("🔐 WebAuthn Signature Verification:")
            log("  - Public Key: \(publicKey.map { String(format: "%02x", $0) }.joined().prefix(60))...")
            log("  - Auth Data: \(authenticatorData.map { String(format: "%02x", $0) }.joined().prefix(60))...")
            log("  - Client Data Hash: \(SHA256.hash(data: clientDataJSON).compactMap { String(format: "%02x", $0) }.joined())")
            log("  - Signed Data Length: \(signedData.count) bytes")
            log("  - Signature: \(signature.map { String(format: "%02x", $0) }.joined().prefix(60))...")
            
            // Convert public key to P256 key
            // Try different formats since Passkey public keys can be in various formats
            let p256PublicKey: P256.Signing.PublicKey
            
            if publicKey.count == 65 && publicKey[0] == 0x04 {
                // X9.63 uncompressed format (65 bytes starting with 0x04)
                p256PublicKey = try P256.Signing.PublicKey(x963Representation: publicKey)
            } else if publicKey.count == 64 {
                // Raw format (64 bytes - just x and y coordinates)
                p256PublicKey = try P256.Signing.PublicKey(rawRepresentation: publicKey)
            } else {
                // Try as DER/SPKI format
                p256PublicKey = try P256.Signing.PublicKey(derRepresentation: publicKey)
            }
            
            // Convert signature from DER format to P256 signature
            let ecdsaSignature = try P256.Signing.ECDSASignature(derRepresentation: signature)
            
            // Verify the signature (without additional hashing since data already contains hash)
            let isValid = p256PublicKey.isValidSignature(ecdsaSignature, for: signedData)
            
            log("  ✅ Verification Result: \(isValid ? "VALID" : "INVALID")")
            return isValid
            
        } catch {
            log("  ❌ Verification Error: \(error.localizedDescription)")
            return false
        }
    }
    
    private func dataFromHexString(_ hexString: String) -> Data? {
        let hex = hexString.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "0x", with: "")
        guard hex.count % 2 == 0 else { return nil }
        
        var data = Data()
        var index = hex.startIndex
        
        while index < hex.endIndex {
            let nextIndex = hex.index(index, offsetBy: 2)
            guard let byte = UInt8(hex[index..<nextIndex], radix: 16) else { return nil }
            data.append(byte)
            index = nextIndex
        }
        
        return data
    }
    
    func demonstrateSignatureVerification(
        publicKeyHex: String,
        signatureHex: String,
        authenticatorDataHex: String,
        clientDataJSON: String
    ) -> Bool {
        guard let publicKey = dataFromHexString(publicKeyHex),
              let signature = dataFromHexString(signatureHex),
              let authenticatorData = dataFromHexString(authenticatorDataHex),
              let clientData = clientDataJSON.data(using: .utf8) else {
            log("❌ Failed to parse input data")
            return false
        }
        
        return verifyWebAuthnSignature(
            publicKey: publicKey,
            signature: signature,
            authenticatorData: authenticatorData,
            clientDataJSON: clientData
        )
    }
}