//
//  DataPrivacyView.swift
//  Brrow
//
//  Data & Privacy settings for GDPR compliance
//

import SwiftUI

struct DataPrivacyView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false
    @State private var isExportingData = false
    @State private var exportProgress = 0.0
    
    var body: some View {
        NavigationView {
            List {
                // Data Collection
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Data We Collect", systemImage: "doc.text.magnifyingglass")
                            .font(.headline)
                        
                        Text("• Profile information (name, email, photo)")
                        Text("• Location data (for nearby listings)")
                        Text("• Transaction history")
                        Text("• Messages between users")
                        Text("• App usage analytics")
                    }
                    .font(.caption)
                    .padding(.vertical, 5)
                } header: {
                    Text("Data Collection")
                }
                
                // Data Usage
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("How We Use Your Data", systemImage: "shield.checkered")
                            .font(.headline)
                        
                        Text("• Facilitate rentals between users")
                        Text("• Process payments securely")
                        Text("• Send important notifications")
                        Text("• Improve app experience")
                        Text("• Ensure platform safety")
                    }
                    .font(.caption)
                    .padding(.vertical, 5)
                } header: {
                    Text("Data Usage")
                }
                
                // Data Rights
                Section {
                    // Export Data
                    Button(action: exportUserData) {
                        HStack {
                            Label("Export My Data", systemImage: "square.and.arrow.up")
                            Spacer()
                            if isExportingData {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(isExportingData)
                    
                    // Download Data
                    NavigationLink(destination: DataDownloadView()) {
                        Label("View Downloaded Data", systemImage: "folder")
                    }
                    
                    // Delete Account
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        Label("Delete My Account", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                } header: {
                    Text("Your Data Rights")
                } footer: {
                    Text("You can request a copy of your data or permanently delete your account at any time.")
                }
                
                // Third Party Services
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "creditcard.circle")
                            Text("Stripe")
                            Spacer()
                            Text("Payment Processing")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Image(systemName: "bell.circle")
                            Text("OneSignal")
                            Spacer()
                            Text("Push Notifications")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis.circle")
                            Text("Analytics")
                            Spacer()
                            Text("App Usage Tracking")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Third Party Services")
                } footer: {
                    Text("We use trusted third-party services to provide features. Each service has its own privacy policy.")
                }
                
                // Contact
                Section {
                    Link(destination: URL(string: "mailto:privacy@brrowapp.com")!) {
                        Label("Contact Privacy Team", systemImage: "envelope")
                    }
                } header: {
                    Text("Privacy Support")
                }
            }
            .navigationTitle("Data & Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Delete Account", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteAccount()
                }
            } message: {
                Text("This will permanently delete your account and all associated data. This action cannot be undone.")
            }
        }
    }
    
    private func exportUserData() {
        isExportingData = true
        
        // Simulate data export
        Task {
            for i in 1...10 {
                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                await MainActor.run {
                    exportProgress = Double(i) / 10.0
                }
            }
            
            await MainActor.run {
                isExportingData = false
                exportProgress = 0.0
                // In real app, would trigger download or email
            }
        }
    }
    
    private func deleteAccount() {
        // In real app, would call API to delete account
        Task {
            await AuthManager.shared.logout()
        }
    }
}

// Data Download View
struct DataDownloadView: View {
    var body: some View {
        List {
            Section("Available Downloads") {
                ForEach(["Profile Data", "Transaction History", "Messages", "Listings"], id: \.self) { dataType in
                    HStack {
                        Text(dataType)
                        Spacer()
                        Button(action: {}) {
                            Image(systemName: "arrow.down.circle")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            
            Section {
                Text("Data exports are available for 30 days after request.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Download Data")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DataPrivacyView_Previews: PreviewProvider {
    static var previews: some View {
        DataPrivacyView()
    }
}