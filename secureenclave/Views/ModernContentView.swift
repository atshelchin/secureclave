//
//  ModernContentView.swift
//  secureenclave
//
//  Created by shelchin on 2025/9/5.
//

import SwiftUI
import CryptoKit
import LocalAuthentication

struct ModernContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ModernSecureEnclaveView()
                .tabItem {
                    Label("Secure Enclave", systemImage: "lock.circle.fill")
                }
                .tag(0)
            
            ModernPasskeysView()
                .tabItem {
                    Label("Passkeys", systemImage: "person.badge.key.fill")
                }
                .tag(1)
            
            SystemInfoView()
                .tabItem {
                    Label("System", systemImage: "info.circle.fill")
                }
                .tag(2)
            
            PasskeysDebugView()
                .tabItem {
                    Label("Debug", systemImage: "ladybug.fill")
                }
                .tag(3)
        }
        .accentColor(.blue)
    }
}

struct SystemInfoView: View {
    @State private var deviceInfo: [String: String] = [:]
    
    var body: some View {
        NavigationView {
            List {
                Section("Device Information") {
                    InfoRow(label: "Device", value: UIDevice.current.name)
                    InfoRow(label: "Model", value: UIDevice.current.model)
                    InfoRow(label: "iOS Version", value: UIDevice.current.systemVersion)
                    InfoRow(label: "Platform", value: getPlatform())
                }
                
                Section("Security Features") {
                    FeatureRow(
                        name: "Secure Enclave",
                        available: SecureEnclave.isAvailable,
                        icon: "lock.shield.fill"
                    )
                    FeatureRow(
                        name: "Biometric Authentication",
                        available: checkBiometrics(),
                        icon: "faceid"
                    )
                    FeatureRow(
                        name: "Passkeys Support",
                        available: true,
                        icon: "key.fill"
                    )
                }
                
                Section("App Configuration") {
                    InfoRow(label: "Bundle ID", value: Bundle.main.bundleIdentifier ?? "Unknown")
                    InfoRow(label: "Team ID", value: "9RS8E64FWL")
                    InfoRow(label: "Domain", value: "atshelchin.github.io")
                }
            }
            .navigationTitle("System Info")
        }
    }
    
    private func getPlatform() -> String {
        #if targetEnvironment(simulator)
        return "Simulator"
        #else
        return "Physical Device"
        #endif
    }
    
    private func checkBiometrics() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct FeatureRow: View {
    let name: String
    let available: Bool
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(available ? .green : .gray)
                .frame(width: 30)
            Text(name)
            Spacer()
            Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundColor(available ? .green : .red)
        }
    }
}

#Preview {
    ModernContentView()
}