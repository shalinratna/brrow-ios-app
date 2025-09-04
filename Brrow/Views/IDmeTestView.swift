//
//  IDmeTestView.swift
//  Brrow
//
//  Test view for ID.me integration verification
//

import SwiftUI

struct IDmeTestView: View {
    @StateObject private var idmeService = IDmeService.shared
    @State private var showingVerification = false
    @State private var verificationResult: String = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.fill.badge.checkmark")
                        .font(.system(size: 60))
                        .foregroundColor(Theme.Colors.primary)
                    
                    Text("ID.me Integration Test")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Test the complete ID.me verification flow")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Configuration Status
                VStack(alignment: .leading, spacing: 12) {
                    Text("Configuration Status")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 8) {
                        ConfigRow(
                            title: "Client ID",
                            value: IDmeConfig.clientID == "YOUR_IDME_CLIENT_ID" ? "❌ Not Set" : "✅ Configured",
                            isValid: IDmeConfig.clientID != "YOUR_IDME_CLIENT_ID"
                        )
                        
                        ConfigRow(
                            title: "Client Secret",
                            value: IDmeConfig.clientSecret == "YOUR_IDME_CLIENT_SECRET" ? "❌ Not Set" : "✅ Configured",
                            isValid: IDmeConfig.clientSecret != "YOUR_IDME_CLIENT_SECRET"
                        )
                        
                        ConfigRow(
                            title: "Redirect URI",
                            value: IDmeConfig.redirectURI,
                            isValid: IDmeConfig.redirectURI.hasPrefix("https://brrowapp.com")
                        )
                        
                        ConfigRow(
                            title: "Default Scope",
                            value: IDmeConfig.defaultScope,
                            isValid: !IDmeConfig.defaultScope.isEmpty
                        )
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // Verification Status
                if idmeService.isVerified {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.green)
                        
                        Text("Identity Verified!")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                        
                        if let profile = idmeService.userProfile {
                            Text("Verification Level: \(profile.attributes.verificationLevel ?? "Basic")")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Test Result
                if !verificationResult.isEmpty {
                    ScrollView {
                        Text(verificationResult)
                            .font(.system(.caption, design: .monospaced))
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .frame(maxHeight: 150)
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 16) {
                    Button(action: {
                        testConfiguration()
                    }) {
                        HStack {
                            Image(systemName: "gear")
                            Text("Test Configuration")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        startVerificationTest()
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "person.badge.plus")
                            }
                            Text(isLoading ? "Verifying..." : "Start ID.me Verification")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.Colors.primary)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isLoading || idmeService.isVerifying)
                    
                    if idmeService.isVerified {
                        Button(action: {
                            idmeService.logout()
                            verificationResult = "Logged out successfully"
                        }) {
                            HStack {
                                Image(systemName: "arrow.right.square")
                                Text("Logout")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 20)
            .navigationTitle("ID.me Test")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func testConfiguration() {
        let validation = IDmeConfigHelper.validateConfiguration()
        
        if validation.isValid {
            verificationResult = """
            ✅ Configuration Valid!
            
            Client ID: \(IDmeConfig.clientID)
            Redirect URI: \(IDmeConfig.redirectURI)
            Auth URL: \(IDmeConfig.authURL)
            Token URL: \(IDmeConfig.tokenURL)
            User Info URL: \(IDmeConfig.userInfoURL)
            Default Scope: \(IDmeConfig.defaultScope)
            
            Ready for verification testing!
            """
        } else {
            verificationResult = """
            ❌ Configuration Issues:
            
            \(validation.issues.map { "• \($0)" }.joined(separator: "\n"))
            
            Please update IDmeService.swift with your credentials.
            """
        }
    }
    
    private func startVerificationTest() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            verificationResult = "❌ Could not find root view controller"
            return
        }
        
        isLoading = true
        verificationResult = "🔄 Starting ID.me verification flow..."
        
        idmeService.startVerification(from: rootViewController) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let profile):
                    self.verificationResult = """
                    ✅ Verification Successful!
                    
                    Name: \(profile.attributes.firstName ?? "N/A") \(profile.attributes.lastName ?? "N/A")
                    Email: \(profile.attributes.email ?? "N/A")
                    Verified: \(profile.attributes.verified ? "Yes" : "No")
                    Level: \(profile.attributes.verificationLevel ?? "Basic")
                    Phone: \(profile.attributes.phone ?? "N/A")
                    ZIP: \(profile.attributes.zip ?? "N/A")
                    
                    Profile updated successfully!
                    """
                    
                case .failure(let error):
                    self.verificationResult = """
                    ❌ Verification Failed
                    
                    Error: \(error.localizedDescription)
                    
                    This is expected if testing without completing the ID.me flow.
                    """
                }
            }
        }
    }
}

struct ConfigRow: View {
    let title: String
    let value: String
    let isValid: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(isValid ? .green : .red)
                .fontWeight(.medium)
        }
    }
}

// Preview
struct IDmeTestView_Previews: PreviewProvider {
    static var previews: some View {
        IDmeTestView()
    }
}