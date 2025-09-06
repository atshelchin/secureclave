//
//  SimpleContentView.swift
//  secureenclave
//
//  Created by shelchin on 2025/9/5.
//

import SwiftUI
import SwiftData

struct SimpleContentView: View {
    @State private var isLoaded = false
    
    var body: some View {
        Group {
            if !isLoaded {
                // Simple loading view
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading...")
                        .padding(.top)
                }
                .onAppear {
                    // Delay loading complex views
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            isLoaded = true
                        }
                    }
                }
            } else {
                // Load the full interface
                MainNavigationView()
            }
        }
    }
}

struct MainNavigationView: View {
    var body: some View {
        NavigationView {
            List {
                Section("Security Features") {
                    NavigationLink(destination: Text("Secure Enclave Test").padding()) {
                        Label("Secure Enclave", systemImage: "lock.circle.fill")
                    }
                    
                    NavigationLink(destination: SimplePasskeysView()) {
                        Label("Passkeys", systemImage: "person.badge.key.fill")
                    }
                    
                    NavigationLink(destination: Text("iCloud Debug").padding()) {
                        Label("iCloud Sync Debug", systemImage: "icloud.circle.fill")
                    }
                }
                
                Section("Info") {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text("Ready")
                            .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("Secure Enclave Debug")
        }
    }
}