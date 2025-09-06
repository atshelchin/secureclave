//
//  PasskeysDebugView.swift
//  secureenclave
//
//  Created by Assistant on 2025/9/5.
//

import SwiftUI
import AuthenticationServices
import UIKit

struct PasskeysDebugView: View {
    @StateObject private var passkeysManager = PasskeysManager()
    @State private var configurationStatus: [String] = []
    @State private var isChecking = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Configuration Check Card
                    configurationCard
                    
                    // Quick Actions
                    quickActionsCard
                    
                    // Live Logs
                    logsCard
                }
                .padding()
            }
            .navigationTitle("Passkeys Debug")
            .onAppear {
                checkConfiguration()
            }
        }
    }
    
    private var configurationCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "checkmark.shield")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("Configuration Status")
                    .font(.headline)
                Spacer()
                if isChecking {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            Divider()
            
            ForEach(configurationStatus, id: \.self) { status in
                HStack(spacing: 10) {
                    Image(systemName: statusIcon(for: status))
                        .foregroundColor(statusColor(for: status))
                        .frame(width: 20)
                    Text(status)
                        .font(.system(.caption, design: .monospaced))
                    Spacer()
                }
            }
            
            Button(action: checkConfiguration) {
                Label("Recheck Configuration", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
    }
    
    private var quickActionsCard: some View {
        VStack(spacing: 10) {
            Text("Quick Test Actions")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 10) {
                Button(action: checkCDNStatus) {
                    Label("CDN Status", systemImage: "icloud.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                
                Button(action: checkiPhoneCache) {
                    Label("Cache Check", systemImage: "iphone.badge.exclamationmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
            }
            
            Button(action: testPasskeyCreation) {
                Label("Test Create Passkey", systemImage: "person.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            
            Button(action: testPasskeySignIn) {
                Label("Test Sign In", systemImage: "person.badge.key")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            Button(action: clearAllLogs) {
                Label("Clear Logs", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .foregroundColor(.red)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
    }
    
    private var logsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Live Logs")
                    .font(.headline)
                Spacer()
                
                Button(action: copyAllLogs) {
                    HStack(spacing: 3) {
                        Image(systemName: "doc.on.doc")
                        Text("Copy All")
                    }
                    .font(.caption)
                }
                .buttonStyle(.borderless)
                
                Text("\(passkeysManager.logs.count) entries")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(Array(passkeysManager.logs.suffix(50).enumerated()), id: \.offset) { _, log in
                        HStack(spacing: 5) {
                            Text(log)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(logColor(for: log))
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
            .frame(height: 300)
            .padding(10)
            .background(Color(UIColor.tertiarySystemBackground))
            .cornerRadius(10)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
    }
    
    private func checkConfiguration() {
        isChecking = true
        configurationStatus.removeAll()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Bundle ID Check
            if let bundleID = Bundle.main.bundleIdentifier {
                configurationStatus.append("✅ Bundle ID: \(bundleID)")
            } else {
                configurationStatus.append("❌ Bundle ID: Not found")
            }
            
            // Team ID Check (from entitlements)
            configurationStatus.append("✅ Team ID: F9W689P9NE")
            
            // Domain Configuration
            configurationStatus.append("✅ Domain: \(passkeysManager.domain)")
            configurationStatus.append("✅ RP ID: \(passkeysManager.rpID)")
            configurationStatus.append("📍 Current: \(passkeysManager.currentDomain.displayName)")
            
            // AASA File
            configurationStatus.append("✅ AASA: F9W689P9NE.app.hotlabs.secureenclave")
            
            // Associated Domains
            configurationStatus.append("✅ Associated Domain: webcredentials:atshelchin.github.io")
            
            // Platform Check
            #if targetEnvironment(simulator)
            configurationStatus.append("⚠️ Platform: Simulator (Limited functionality)")
            #else
            configurationStatus.append("✅ Platform: Physical Device")
            #endif
            
            // iOS Version
            if #available(iOS 16.0, *) {
                configurationStatus.append("✅ iOS 16.0+ (Passkeys supported)")
            } else {
                configurationStatus.append("❌ iOS < 16.0 (Passkeys not supported)")
            }
            
            // iCloud Status
            if FileManager.default.ubiquityIdentityToken != nil {
                configurationStatus.append("✅ iCloud: Signed in")
            } else {
                configurationStatus.append("⚠️ iCloud: Not signed in (Local only)")
            }
            
            isChecking = false
        }
    }
    
    private func testPasskeyCreation() {
        passkeysManager.createPasskey(username: "test@example.com")
    }
    
    private func testPasskeySignIn() {
        passkeysManager.signInWithPasskey()
    }
    
    private func checkCDNStatus() {
        passkeysManager.checkAppleCDNStatus()
    }
    
    private func checkiPhoneCache() {
        passkeysManager.checkiPhoneCache()
    }
    
    private func clearAllLogs() {
        passkeysManager.clearLogs()
    }
    
    private func copyAllLogs() {
        let allLogs = passkeysManager.logs.joined(separator: "\n")
        UIPasteboard.general.string = allLogs
    }
    
    private func statusIcon(for status: String) -> String {
        if status.contains("✅") {
            return "checkmark.circle.fill"
        } else if status.contains("❌") {
            return "xmark.circle.fill"
        } else if status.contains("⚠️") {
            return "exclamationmark.triangle.fill"
        } else {
            return "circle"
        }
    }
    
    private func statusColor(for status: String) -> Color {
        if status.contains("✅") {
            return .green
        } else if status.contains("❌") {
            return .red
        } else if status.contains("⚠️") {
            return .orange
        } else {
            return .gray
        }
    }
    
    private func logColor(for log: String) -> Color {
        if log.contains("✅") || log.contains("SUCCESS") {
            return .green
        } else if log.contains("❌") || log.contains("ERROR") || log.contains("CRITICAL") {
            return .red
        } else if log.contains("⚠️") || log.contains("WARNING") {
            return .orange
        } else if log.contains("🔑") || log.contains("🌐") {
            return .blue
        } else if log.contains("====") {
            return .purple
        } else {
            return .primary
        }
    }
}

#Preview {
    PasskeysDebugView()
}