//
//  SecureEnclaveManager.swift
//  secureenclave
//
//  Created by shelchin on 2025/9/5.
//

import Foundation
import LocalAuthentication
import CryptoKit
import Security

class SecureEnclaveManager: ObservableObject {
    @Published var isSecureEnclaveAvailable: Bool = false
    @Published var logs: [String] = []
    
    init() {
        checkSecureEnclaveAvailability()
        performPrerequisitesCheck()
    }
    
    func checkSecureEnclaveAvailability() {
        isSecureEnclaveAvailable = SecureEnclave.isAvailable
        log("Secure Enclave available: \(isSecureEnclaveAvailable)")
    }
    
    // MARK: - Prerequisites Check
    
    func performPrerequisitesCheck() {
        log("")
        log("===== SECURE ENCLAVE PREREQUISITES CHECK =====")
        
        var allChecksPassed = true
        
        // 1. Hardware Check - Secure Enclave Availability
        if SecureEnclave.isAvailable {
            log("✅ Secure Enclave hardware present")
        } else {
            log("❌ Secure Enclave NOT available")
            log("   Secure Enclave requires:")
            log("   - Physical device (not simulator)")
            log("   - A-series chip (iPhone 5s or later)")
            log("   - T1/T2 chip (Mac with TouchBar or T2)")
            allChecksPassed = false
        }
        
        // 2. Physical Device Check
        #if targetEnvironment(simulator)
        log("❌ Running on Simulator - Secure Enclave NOT available")
        log("   Requirement: Use physical device for testing")
        allChecksPassed = false
        #else
        log("✅ Running on physical device")
        #endif
        
        // 3. iOS Version Check
        if #available(iOS 11.0, *) {
            log("✅ iOS 11.0+ detected - CryptoKit available")
        } else {
            log("⚠️ iOS 10 or lower - Limited Secure Enclave features")
        }
        
        // 4. Biometric Enrollment Check
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            log("✅ Biometric authentication enrolled")
            
            // Check biometry type
            if #available(iOS 11.0, *) {
                switch context.biometryType {
                case .none:
                    log("   Type: None")
                case .touchID:
                    log("   Type: Touch ID")
                case .faceID:
                    log("   Type: Face ID")
                @unknown default:
                    log("   Type: Unknown")
                }
            }
        } else {
            log("⚠️ Biometric authentication not available: \(error?.localizedDescription ?? "Unknown")")
            log("   Note: Keys can still be protected with device passcode")
        }
        
        // 5. Device Passcode Check
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            log("✅ Device passcode set")
        } else {
            log("⚠️ No device passcode - Some features limited")
        }
        
        // 6. Key Algorithm Support
        log("📐 Supported Algorithms:")
        log("   - EC P-256 (EC256/secp256r1): ✅ Supported")
        log("   - EC P-384: ❌ Not supported")
        log("   - EC P-521: ❌ Not supported")
        log("   - RSA: ❌ Not supported in Secure Enclave")
        log("   - Ed25519: ❌ Not supported")
        
        // 7. Key Storage Capacity
        log("💾 Key Storage:")
        log("   - Maximum keys: Practically unlimited")
        log("   - Key persistence: Survives app deletion")
        log("   - Key backup: NOT included in iCloud backup")
        log("   - Key export: Private keys CANNOT be exported")
        
        // 8. Access Control Options
        log("🔐 Access Control Options Available:")
        log("   - .privateKeyUsage: Basic access control")
        log("   - .biometryCurrentSet: Requires current biometry")
        log("   - .biometryAny: Any enrolled biometry")
        log("   - .devicePasscode: Requires device passcode")
        log("   - .userPresence: Requires user presence")
        
        // Summary
        log("")
        if allChecksPassed {
            log("✅ ALL PREREQUISITES MET - Secure Enclave ready")
        } else {
            log("❌ Prerequisites NOT met - Secure Enclave unavailable")
            log("   Solution: Test on physical iPhone/iPad device")
        }
        log("===== END PREREQUISITES CHECK =====")
        log("")
    }
    
    // MARK: - Key Generation
    
    func generateSecureEnclaveKey(tag: String, requireBiometry: Bool = false) -> (SecKey?, Data?) {
        log("Generating Secure Enclave key with tag: \(tag)")
        
        let flags: SecAccessControlCreateFlags
        if requireBiometry {
            flags = [.privateKeyUsage, .biometryCurrentSet]
        } else {
            flags = .privateKeyUsage
        }
        
        guard let accessControl = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            flags,
            nil
        ) else {
            log("❌ Failed to create access control")
            return (nil, nil)
        }
        
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,  // This is P-256/secp256r1
            kSecAttrKeySizeInBits as String: 256,  // 256-bit key size
            kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: true,
                kSecAttrApplicationTag as String: tag.data(using: .utf8)!,
                kSecAttrAccessControl as String: accessControl
            ]
        ]
        
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            log("❌ Key generation failed: \(error?.takeRetainedValue() as Error? ?? NSError())")
            return (nil, nil)
        }
        
        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            log("❌ Failed to extract public key")
            return (nil, nil)
        }
        
        var publicKeyError: Unmanaged<CFError>?
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &publicKeyError) as Data? else {
            log("❌ Failed to export public key: \(publicKeyError?.takeRetainedValue() as Error? ?? NSError())")
            return (nil, nil)
        }
        
        log("✅ Successfully generated key pair")
        return (privateKey, publicKeyData)
    }
    
    // MARK: - Key Operations
    
    func signData(_ data: Data, with privateKey: SecKey) -> Data? {
        log("Signing data...")
        log("📊 Input data size: \(data.count) bytes")
        
        var error: Unmanaged<CFError>?
        guard let signature = SecKeyCreateSignature(
            privateKey,
            .ecdsaSignatureMessageX962SHA256,  // X9.62 format (DER encoded)
            data as CFData,
            &error
        ) as Data? else {
            log("❌ Signing failed: \(error?.takeRetainedValue() as Error? ?? NSError())")
            return nil
        }
        
        log("✅ Data signed successfully")
        log("📊 Signature format: X9.62 (DER encoded)")
        log("📊 Signature size: \(signature.count) bytes")
        log("📊 Expected: ~70-72 bytes for P-256")
        log("📊 Hex length: \(signature.count * 2) characters")
        
        // Note: X9.62 format includes DER encoding overhead
        // Raw signature would be exactly 64 bytes (32 bytes r + 32 bytes s)
        
        return signature
    }
    
    func verifySignature(_ signature: Data, for data: Data, with publicKey: SecKey) -> Bool {
        log("Verifying signature...")
        
        var error: Unmanaged<CFError>?
        let result = SecKeyVerifySignature(
            publicKey,
            .ecdsaSignatureMessageX962SHA256,
            data as CFData,
            signature as CFData,
            &error
        )
        
        if result {
            log("✅ Signature verified successfully")
        } else {
            log("❌ Signature verification failed: \(error?.takeRetainedValue() as Error? ?? NSError())")
        }
        
        return result
    }
    
    // MARK: - Key Retrieval
    
    func retrieveKey(tag: String) -> SecKey? {
        log("Retrieving key with tag: \(tag)")
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tag.data(using: .utf8)!,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecReturnRef as String: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecSuccess {
            log("✅ Key retrieved successfully")
            return (item as! SecKey)
        } else {
            log("❌ Failed to retrieve key: \(status)")
            return nil
        }
    }
    
    // MARK: - Key Deletion
    
    func deleteKey(tag: String) -> Bool {
        log("Deleting key with tag: \(tag)")
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tag.data(using: .utf8)!,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess || status == errSecItemNotFound {
            log("✅ Key deleted successfully")
            return true
        } else {
            log("❌ Failed to delete key: \(status)")
            return false
        }
    }
    
    // MARK: - List All Keys
    
    func listAllKeys() -> [[String: Any]] {
        log("Listing all keys...")
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecReturnAttributes as String: true,
            kSecReturnRef as String: true
        ]
        
        var items: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &items)
        
        if status == errSecSuccess {
            if let array = items as? [[String: Any]] {
                log("✅ Found \(array.count) keys")
                return array
            }
        }
        
        log("❌ No keys found or error: \(status)")
        return []
    }
    
    // MARK: - Biometric Authentication
    
    func authenticateWithBiometrics(completion: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Authenticate to access Secure Enclave"
            ) { success, authError in
                DispatchQueue.main.async {
                    if success {
                        self.log("✅ Biometric authentication successful")
                    } else {
                        self.log("❌ Biometric authentication failed: \(authError?.localizedDescription ?? "Unknown error")")
                    }
                    completion(success, authError)
                }
            }
        } else {
            log("❌ Biometric authentication not available: \(error?.localizedDescription ?? "Unknown error")")
            completion(false, error)
        }
    }
    
    // MARK: - Helper Methods
    
    func log(_ message: String) {
        DispatchQueue.main.async {
            let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
            self.logs.append("[\(timestamp)] \(message)")
        }
    }
    
    func clearLogs() {
        logs.removeAll()
    }
}