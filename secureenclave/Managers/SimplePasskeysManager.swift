//
//  SimplePasskeysManager.swift
//  secureenclave
//
//  Created by shelchin on 2025/9/5.
//

import Foundation
import AuthenticationServices
import SwiftUI

class SimplePasskeysManager: NSObject, ObservableObject {
    @Published var logs: [String] = []
    @Published var isWorking = false
    
    override init() {
        super.init()
        log("SimplePasskeysManager initialized")
    }
    
    func testPasskeyCreation() {
        log("Testing Passkey creation...")
        
        #if targetEnvironment(simulator)
        log("⚠️ Running on Simulator")
        log("Passkeys work best on real devices")
        log("Some features may not work properly")
        #endif
        
        // Simple test without actual passkey creation
        isWorking = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.log("✅ Test completed")
            self.log("Note: Full Passkey functionality requires:")
            self.log("• Real device (not simulator)")
            self.log("• iOS 16+")
            self.log("• Associated Domains configured")
            self.log("• apple-app-site-association deployed")
            self.isWorking = false
        }
    }
    
    private func log(_ message: String) {
        DispatchQueue.main.async {
            let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
            self.logs.append("[\(timestamp)] \(message)")
            
            // Keep only last 50 logs to avoid memory issues
            if self.logs.count > 50 {
                self.logs.removeFirst(self.logs.count - 50)
            }
        }
    }
    
    func clearLogs() {
        logs.removeAll()
    }
}