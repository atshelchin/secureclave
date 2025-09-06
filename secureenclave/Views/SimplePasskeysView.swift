//
//  SimplePasskeysView.swift
//  secureenclave
//
//  Created by shelchin on 2025/9/5.
//

import SwiftUI

struct SimplePasskeysView: View {
    @StateObject private var manager = SimplePasskeysManager()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Passkeys Test")
                .font(.title)
                .padding()
            
            if manager.isWorking {
                ProgressView()
                    .scaleEffect(1.5)
            } else {
                Button(action: {
                    manager.testPasskeyCreation()
                }) {
                    Label("Test Passkey System", systemImage: "person.badge.key")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(Array(manager.logs.enumerated()), id: \.offset) { _, log in
                        Text(log)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(logColor(for: log))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .padding()
            
            Spacer()
        }
        .navigationTitle("Passkeys")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func logColor(for log: String) -> Color {
        if log.contains("✅") {
            return .green
        } else if log.contains("❌") {
            return .red
        } else if log.contains("⚠️") {
            return .orange
        } else {
            return .primary
        }
    }
}