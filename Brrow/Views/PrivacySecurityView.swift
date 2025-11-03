//
//  PrivacySecurityView.swift
//  Brrow
//
//  Privacy and security settings
//

import SwiftUI

struct PrivacySecurityView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var authManager = AuthManager.shared

    @State private var faceIDEnabled = true
    @State private var autoLockEnabled = true
    @State private var showLocationToContacts = true
    @State private var allowDataSharing = false
    @State private var personalizationEnabled = true
    @State private var isUpdatingPersonalization = false

    @State private var showingChangePassword = false
    @State private var showingCreatePassword = false
    @State private var hasPassword = false
    @State private var authProvider = "LOCAL"
    @State private var isCheckingPassword = true
    
    var body: some View {
        List {
            Section("Security") {
                Toggle(isOn: $faceIDEnabled) {
                    HStack {
                        Image(systemName: "faceid")
                            .foregroundColor(Theme.Colors.primary)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading) {
                            Text("Face ID / Touch ID")
                                .foregroundColor(Theme.Colors.text)
                            Text("Use biometrics to unlock app")
                                .font(.caption)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                    }
                }
                
                Toggle(isOn: $autoLockEnabled) {
                    HStack {
                        Image(systemName: "lock.rotation")
                            .foregroundColor(Theme.Colors.primary)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading) {
                            Text("Auto-Lock")
                                .foregroundColor(Theme.Colors.text)
                            Text("Lock app when in background")
                                .font(.caption)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                    }
                }
            }
            
            Section("Privacy") {
                Toggle(isOn: $showLocationToContacts) {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(Theme.Colors.primary)
                            .frame(width: 24)

                        VStack(alignment: .leading) {
                            Text("Share Location")
                                .foregroundColor(Theme.Colors.text)
                            Text("Show approximate distance to other users")
                                .font(.caption)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                    }
                }

                Toggle(isOn: $allowDataSharing) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(Theme.Colors.primary)
                            .frame(width: 24)

                        VStack(alignment: .leading) {
                            Text("Analytics")
                                .foregroundColor(Theme.Colors.text)
                            Text("Help improve Brrow with anonymous data")
                                .font(.caption)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                    }
                }

                Toggle(isOn: $personalizationEnabled) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(Theme.Colors.primary)
                            .frame(width: 24)

                        VStack(alignment: .leading) {
                            Text("Personalized Recommendations")
                                .foregroundColor(Theme.Colors.text)
                            Text("Smart feed based on your interests and behavior")
                                .font(.caption)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }

                        if isUpdatingPersonalization {
                            ProgressView()
                                .scaleEffect(0.8)
                                .padding(.leading, 8)
                        }
                    }
                }
                .disabled(isUpdatingPersonalization)
                .onChange(of: personalizationEnabled) { newValue in
                    updatePersonalizationSetting(newValue)
                }
            }
            
            Section("Account Security") {
                // Password Management Button
                if isCheckingPassword {
                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundColor(Theme.Colors.primary)
                            .frame(width: 24)

                        Text("Loading...")
                            .foregroundColor(Theme.Colors.secondaryText)

                        Spacer()

                        ProgressView()
                    }
                } else {
                    Button(action: {
                        if hasPassword {
                            showingChangePassword = true
                        } else {
                            showingCreatePassword = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "key.fill")
                                .foregroundColor(Theme.Colors.primary)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(hasPassword ? "Change Password" : "Create Password")
                                    .foregroundColor(Theme.Colors.text)

                                if !hasPassword && authProvider != "LOCAL" {
                                    Text("Add password for email login")
                                        .font(.caption)
                                        .foregroundColor(Theme.Colors.secondaryText)
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                    }
                }

                Button(action: {}) {
                    HStack {
                        Image(systemName: "iphone.and.arrow.forward")
                            .foregroundColor(Theme.Colors.primary)
                            .frame(width: 24)

                        Text("Active Sessions")
                            .foregroundColor(Theme.Colors.text)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Privacy & Security")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .sheet(isPresented: $showingChangePassword) {
            NavigationView {
                ChangePasswordView()
            }
        }
        .sheet(isPresented: $showingCreatePassword) {
            NavigationView {
                CreatePasswordView(provider: getProviderName())
            }
        }
        .onAppear {
            checkPasswordStatus()
            loadPersonalizationSetting()
        }
    }

    private func loadPersonalizationSetting() {
        // Load from user profile
        if let user = authManager.currentUser {
            personalizationEnabled = user.personalizationEnabled ?? true
        }
    }

    private func updatePersonalizationSetting(_ enabled: Bool) {
        guard !isUpdatingPersonalization else { return }

        isUpdatingPersonalization = true

        Task {
            do {
                let baseURL = await APIClient.shared.getBaseURL()
                guard let url = URL(string: "\(baseURL)/api/auth/update-personalization"),
                      let authToken = authManager.authToken else {
                    await MainActor.run {
                        isUpdatingPersonalization = false
                    }
                    return
                }

                var request = URLRequest(url: url)
                request.httpMethod = "PUT"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

                let payload: [String: Any] = ["personalizationEnabled": enabled]
                request.httpBody = try JSONSerialization.data(withJSONObject: payload)

                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    print("❌ Failed to update personalization setting")
                    await MainActor.run {
                        // Revert toggle on failure
                        personalizationEnabled = !enabled
                        isUpdatingPersonalization = false
                    }
                    return
                }

                struct PersonalizationResponse: Codable {
                    let success: Bool
                    let message: String
                }

                let result = try JSONDecoder().decode(PersonalizationResponse.self, from: data)

                await MainActor.run {
                    if result.success {
                        print("✅ Personalization updated: \(enabled ? "enabled" : "disabled")")
                        // Setting is saved on server and will be reflected on next user refresh
                    } else {
                        // Revert toggle on failure
                        personalizationEnabled = !enabled
                    }
                    isUpdatingPersonalization = false
                }
            } catch {
                print("❌ Error updating personalization: \(error)")
                await MainActor.run {
                    // Revert toggle on failure
                    personalizationEnabled = !enabled
                    isUpdatingPersonalization = false
                }
            }
        }
    }

    private func getProviderName() -> String {
        switch authProvider {
        case "GOOGLE":
            return "Google"
        case "APPLE":
            return "Apple"
        case "FACEBOOK":
            return "Facebook"
        default:
            return "social login"
        }
    }

    private func checkPasswordStatus() {
        guard let authToken = authManager.authToken else {
            isCheckingPassword = false
            return
        }

        Task {
            do {
                let baseURL = await APIClient.shared.getBaseURL()
                guard let url = URL(string: "\(baseURL)/api/auth/check-password-exists") else {
                    await MainActor.run {
                        isCheckingPassword = false
                    }
                    return
                }

                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    await MainActor.run {
                        isCheckingPassword = false
                    }
                    return
                }

                struct PasswordStatusResponse: Codable {
                    let success: Bool
                    let hasPassword: Bool
                    let authProvider: String
                    let canCreatePassword: Bool
                }

                let statusResponse = try JSONDecoder().decode(PasswordStatusResponse.self, from: data)

                await MainActor.run {
                    hasPassword = statusResponse.hasPassword
                    authProvider = statusResponse.authProvider
                    isCheckingPassword = false
                }
            } catch {
                print("Error checking password status: \(error)")
                await MainActor.run {
                    isCheckingPassword = false
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        PrivacySecurityView()
    }
}