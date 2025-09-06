//
//  KeychainItem.swift
//  secureenclave
//
//  Created by shelchin on 2025/9/5.
//

import Foundation
import SwiftData
import CryptoKit

enum KeyType: String, Codable, CaseIterable {
    case secureEnclaveKey = "Secure Enclave Key"
    case passkey = "Passkey"
    case regularKey = "Regular Key"
}

@Model
final class KeychainItem {
    // All properties must be optional or have default values for CloudKit
    var id: UUID = UUID()
    var label: String = ""
    var keyTag: String = ""
    var publicKeyData: Data?
    var algorithm: String = "EC256"
    var createdAt: Date = Date()
    var lastUsedAt: Date?
    var keyTypeRawValue: String = KeyType.regularKey.rawValue
    var accessControl: String = "biometryAny"
    var isHardwareBacked: Bool = false
    
    // Passkey specific
    var relyingParty: String?
    var userHandle: Data?
    var credentialID: Data?
    var attestationObject: Data?
    var rawClientData: Data?
    var requiresBiometry: Bool = false
    
    // Relationship with inverse for CloudKit
    @Relationship(deleteRule: .cascade, inverse: \OperationLog.keychainItem)
    var operationLogs: [OperationLog]? = []
    
    var keyType: KeyType {
        get { KeyType(rawValue: keyTypeRawValue) ?? .regularKey }
        set { keyTypeRawValue = newValue.rawValue }
    }
    
    init(label: String, keyTag: String, keyType: KeyType, algorithm: String = "EC256", accessControl: String = "biometryAny") {
        self.id = UUID()
        self.label = label
        self.keyTag = keyTag
        self.keyTypeRawValue = keyType.rawValue
        self.algorithm = algorithm
        self.accessControl = accessControl
        self.createdAt = Date()
        self.isHardwareBacked = false
        self.operationLogs = []
    }
}

@Model
final class OperationLog {
    var id: UUID = UUID()
    var timestamp: Date = Date()
    var operation: String = ""
    var success: Bool = false
    var errorMessage: String?
    var details: String?
    
    // Inverse relationship for CloudKit
    var keychainItem: KeychainItem?
    
    init(operation: String, success: Bool, errorMessage: String? = nil, details: String? = nil) {
        self.id = UUID()
        self.timestamp = Date()
        self.operation = operation
        self.success = success
        self.errorMessage = errorMessage
        self.details = details
    }
}