//
//  SettingsView.swift
//  Brrow
//
//  App settings and preferences
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var authManager = AuthManager.shared
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfService = false
    @State private var showingDataPrivacy = false
    @State private var showingProfileSettings = false
    @State private var showingPrivacySecurity = false
    @State private var showingPaymentMethods = false
    @State private var showingNotificationSettings = false
    @State private var showingEmailPreferences = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Account") {
                    settingsRow(
                        title: "Profile Settings",
                        icon: "person.circle",
                        action: { showingProfileSettings = true }
                    )
                    
                    settingsRow(
                        title: "Privacy & Security",
                        icon: "lock.shield",
                        action: { showingPrivacySecurity = true }
                    )
                    
                    settingsRow(
                        title: "Data & Privacy",
                        icon: "hand.raised.shield",
                        action: { showingDataPrivacy = true }
                    )
                    
                    settingsRow(
                        title: "Payment Methods",
                        icon: "creditcard",
                        action: { showingPaymentMethods = true }
                    )
                }
                
                Section("Notifications") {
                    settingsRow(
                        title: "Push Notifications",
                        icon: "bell",
                        action: { showingNotificationSettings = true }
                    )
                    
                    settingsRow(
                        title: "Email Preferences",
                        icon: "envelope",
                        action: { showingEmailPreferences = true }
                    )
                }
                
                Section("App") {
                    settingsRow(
                        title: "App Version",
                        icon: "info.circle",
                        action: {},
                        showChevron: false,
                        subtitle: "1.0.0"
                    )
                    
                    settingsRow(
                        title: "Terms of Service",
                        icon: "doc.text",
                        action: { showingTermsOfService = true }
                    )
                    
                    settingsRow(
                        title: "Privacy Policy",
                        icon: "hand.raised",
                        action: { showingPrivacyPolicy = true }
                    )
                }
                
                Section {
                    Button(action: {
                        Task {
                            await authManager.logout()
                            presentationMode.wrappedValue.dismiss()
                        }
                    }) {
                        HStack {
                            Image(systemName: "power")
                                .foregroundColor(.red)
                            Text("Sign Out")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingPrivacyPolicy) {
                PrivacyPolicyView()
            }
            .sheet(isPresented: $showingTermsOfService) {
                TermsOfServiceView()
            }
            .sheet(isPresented: $showingDataPrivacy) {
                DataPrivacyView()
            }
            .sheet(isPresented: $showingProfileSettings) {
                if let user = authManager.currentUser {
                    NavigationView {
                        EditProfileView(user: user)
                    }
                }
            }
            .sheet(isPresented: $showingPrivacySecurity) {
                NavigationView {
                    PrivacySecurityView()
                }
            }
            .sheet(isPresented: $showingPaymentMethods) {
                NavigationView {
                    PaymentMethodsView()
                }
            }
            .sheet(isPresented: $showingNotificationSettings) {
                NavigationView {
                    ModernNotificationSettingsView()
                }
            }
            .sheet(isPresented: $showingEmailPreferences) {
                NavigationView {
                    EmailPreferencesView()
                }
            }
        }
    }
    
    private func settingsRow(
        title: String,
        icon: String,
        action: @escaping () -> Void,
        showChevron: Bool = true,
        subtitle: String? = nil
    ) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Theme.Colors.primary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundColor(Theme.Colors.text)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
                
                Spacer()
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    SettingsView()
}