//
//  CreatorSettingsView.swift
//  Brrow
//
//  Creator settings and preferences management
//

import SwiftUI

struct CreatorSettingsView: View {
    @StateObject private var creatorService = CreatorService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var notificationPreferences: NotificationPreferences?
    @State private var profileSettings: CreatorProfileSettings?
    @State private var selectedPayoutFrequency: PayoutFrequency = .weekly
    @State private var showingPaymentMethods = false
    @State private var showingTaxSettings = false
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            Form {
                // Profile Settings Section
                profileSettingsSection

                // Notification Preferences Section
                notificationPreferencesSection

                // Payout Settings Section
                payoutSettingsSection

                // Privacy & Security Section
                privacySecuritySection

                // Tax & Legal Section
                taxLegalSection

                // Account Actions Section
                accountActionsSection
            }
            .navigationTitle("Creator Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSettings()
                    }
                    .disabled(isLoading)
                }
            }
            .sheet(isPresented: $showingPaymentMethods) {
                CreatorPaymentMethodsView()
            }
            .sheet(isPresented: $showingTaxSettings) {
                TaxSettingsView()
            }
            .onAppear {
                loadSettings()
            }
        }
    }

    private var profileSettingsSection: some View {
        Section("Profile Settings") {
            if let settings = profileSettings {
                Toggle("Public Profile", isOn: Binding(
                    get: { settings.isPublic },
                    set: { profileSettings?.isPublic = $0 }
                ))

                Toggle("Show Earnings", isOn: Binding(
                    get: { settings.showEarnings },
                    set: { profileSettings?.showEarnings = $0 }
                ))

                Toggle("Show Badges", isOn: Binding(
                    get: { settings.showBadges },
                    set: { profileSettings?.showBadges = $0 }
                ))

                Toggle("Auto Accept Bookings", isOn: Binding(
                    get: { settings.autoAcceptBookings },
                    set: { profileSettings?.autoAcceptBookings = $0 }
                ))

                HStack {
                    Text("Minimum Notice")
                    Spacer()
                    Picker("Minimum Notice", selection: Binding(
                        get: { settings.minimumNotice },
                        set: { profileSettings?.minimumNotice = $0 }
                    )) {
                        Text("1 hour").tag(1)
                        Text("6 hours").tag(6)
                        Text("12 hours").tag(12)
                        Text("24 hours").tag(24)
                        Text("48 hours").tag(48)
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
        }
    }

    private var notificationPreferencesSection: some View {
        Section("Notifications") {
            if let preferences = notificationPreferences {
                Toggle("New Booking", isOn: Binding(
                    get: { preferences.newBooking },
                    set: { notificationPreferences?.newBooking = $0 }
                ))

                Toggle("Payment Received", isOn: Binding(
                    get: { preferences.paymentReceived },
                    set: { notificationPreferences?.paymentReceived = $0 }
                ))

                Toggle("New Review", isOn: Binding(
                    get: { preferences.newReview },
                    set: { notificationPreferences?.newReview = $0 }
                ))

                Toggle("Weekly Report", isOn: Binding(
                    get: { preferences.weeklyReport },
                    set: { notificationPreferences?.weeklyReport = $0 }
                ))

                Toggle("Monthly Report", isOn: Binding(
                    get: { preferences.monthlyReport },
                    set: { notificationPreferences?.monthlyReport = $0 }
                ))

                Toggle("Marketing Updates", isOn: Binding(
                    get: { preferences.marketingUpdates },
                    set: { notificationPreferences?.marketingUpdates = $0 }
                ))
            }
        }
    }

    private var payoutSettingsSection: some View {
        Section("Payout Settings") {
            HStack {
                Text("Payout Frequency")
                Spacer()
                Picker("Payout Frequency", selection: $selectedPayoutFrequency) {
                    ForEach([PayoutFrequency.weekly, .monthly, .instant], id: \.self) { frequency in
                        Text(frequency.displayName).tag(frequency)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }

            Button("Manage Payment Methods") {
                showingPaymentMethods = true
            }

            if let earnings = creatorService.earningsData {
                HStack {
                    Text("Current Balance")
                    Spacer()
                    Text("$\(Int(earnings.currentBalance))")
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }

                HStack {
                    Text("Pending Earnings")
                    Spacer()
                    Text("$\(Int(earnings.pendingEarnings))")
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }

                if earnings.currentBalance >= 50 {
                    Button("Request Instant Payout") {
                        requestPayout()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }

    private var privacySecuritySection: some View {
        Section("Privacy & Security") {
            NavigationLink("Data & Privacy") {
                CreatorDataPrivacyView()
            }

            NavigationLink("Account Security") {
                AccountSecurityView()
            }

            Button("Download My Data") {
                downloadData()
            }
            .foregroundColor(.blue)
        }
    }

    private var taxLegalSection: some View {
        Section("Tax & Legal") {
            Button("Tax Settings") {
                showingTaxSettings = true
            }
            .foregroundColor(.blue)

            if let earnings = creatorService.earningsData, !earnings.taxDocuments.isEmpty {
                Text("Tax Documents (\(earnings.taxDocuments.count))")
                    .foregroundColor(.blue)
            }

            NavigationLink("Terms of Service") {
                CreatorTermsOfServiceView()
            }

            NavigationLink("Creator Agreement") {
                CreatorAgreementView()
            }
        }
    }

    private var accountActionsSection: some View {
        Section("Account") {
            Button("Creator Support") {
                openSupport()
            }
            .foregroundColor(.blue)

            Button("Deactivate Creator Account") {
                deactivateCreatorAccount()
            }
            .foregroundColor(.red)

            Button("Delete Creator Data") {
                deleteCreatorData()
            }
            .foregroundColor(.red)
        }
    }

    // MARK: - Helper Methods

    private func loadSettings() {
        notificationPreferences = creatorService.notificationPreferences
        profileSettings = creatorService.profileSettings

        if let earnings = creatorService.earningsData {
            selectedPayoutFrequency = earnings.payoutSchedule.frequency
        }
    }

    private func saveSettings() {
        guard let notifPrefs = notificationPreferences,
              let profSettings = profileSettings else { return }

        isLoading = true

        Task {
            do {
                let updateRequest = UpdateCreatorSettingsRequest(
                    payoutFrequency: selectedPayoutFrequency,
                    notificationPreferences: notifPrefs,
                    profileSettings: profSettings
                )

                try await creatorService.updateSettings(updateRequest)

                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    // Handle error
                    print("Failed to save settings: \(error)")
                }
            }
        }
    }

    private func requestPayout() {
        guard let earnings = creatorService.earningsData else { return }

        Task {
            do {
                try await creatorService.requestPayout(amount: earnings.currentBalance)
            } catch {
                print("Failed to request payout: \(error)")
            }
        }
    }

    private func downloadData() {
        // Implementation for downloading user data
        print("Downloading user data...")
    }

    private func openSupport() {
        // Implementation for opening creator support
        print("Opening creator support...")
    }

    private func deactivateCreatorAccount() {
        // Implementation for deactivating creator account
        print("Deactivating creator account...")
    }

    private func deleteCreatorData() {
        // Implementation for deleting creator data
        print("Deleting creator data...")
    }
}

// MARK: - Supporting Views

struct CreatorPaymentMethodsView: View {
    @StateObject private var creatorService = CreatorService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddPaymentMethod = false

    var body: some View {
        NavigationView {
            List {
                if let earnings = creatorService.earningsData {
                    ForEach(earnings.paymentMethods) { method in
                        PaymentMethodRow(method: method)
                    }
                    .onDelete(perform: deletePaymentMethod)
                }

                Button("Add Payment Method") {
                    showingAddPaymentMethod = true
                }
                .foregroundColor(.blue)
            }
            .navigationTitle("Payment Methods")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddPaymentMethod) {
                AddPaymentMethodView()
            }
        }
    }

    private func deletePaymentMethod(at offsets: IndexSet) {
        // Implementation for deleting payment method
    }
}

struct PaymentMethodRow: View {
    let method: PaymentMethod

    var body: some View {
        HStack {
            Image(systemName: method.type.icon)
                .foregroundColor(.blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(method.displayName)
                    .fontWeight(.medium)

                HStack {
                    if method.isDefault {
                        Text("Default")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }

                    if method.isVerified {
                        Text("Verified")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }
            }

            Spacer()

            if let lastFour = method.lastFour {
                Text("••••\(lastFour)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddPaymentMethodView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedType: PaymentMethodType = .bankAccount
    @State private var accountNumber = ""
    @State private var routingNumber = ""
    @State private var accountHolderName = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Payment Method Type") {
                    Picker("Type", selection: $selectedType) {
                        ForEach([PaymentMethodType.bankAccount, .paypal, .stripe], id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                if selectedType == .bankAccount {
                    Section("Bank Account Details") {
                        TextField("Account Holder Name", text: $accountHolderName)
                        TextField("Account Number", text: $accountNumber)
                            .keyboardType(.numberPad)
                        TextField("Routing Number", text: $routingNumber)
                            .keyboardType(.numberPad)
                    }
                } else {
                    Section("\(selectedType.displayName) Details") {
                        Text("You'll be redirected to \(selectedType.displayName) to complete setup")
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    Button("Add Payment Method") {
                        addPaymentMethod()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Add Payment Method")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func addPaymentMethod() {
        // Implementation for adding payment method
        dismiss()
    }
}

struct TaxSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var taxId = ""
    @State private var businessName = ""
    @State private var address = ""
    @State private var isBusinessEntity = false

    var body: some View {
        NavigationView {
            Form {
                Section("Tax Information") {
                    Toggle("Business Entity", isOn: $isBusinessEntity)

                    if isBusinessEntity {
                        TextField("Business Name", text: $businessName)
                        TextField("Business Tax ID", text: $taxId)
                    } else {
                        TextField("Social Security Number", text: $taxId)
                            .keyboardType(.numberPad)
                    }

                    TextField("Address", text: $address)
                }

                Section {
                    Button("Save Tax Settings") {
                        saveTaxSettings()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.blue)
                }

                Section {
                    Text("Tax documents will be generated automatically and available for download each year.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Tax Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func saveTaxSettings() {
        // Implementation for saving tax settings
        dismiss()
    }
}

struct TaxDocumentsView: View {
    @StateObject private var creatorService = CreatorService.shared

    var body: some View {
        List {
            if let earnings = creatorService.earningsData {
                ForEach(earnings.taxDocuments) { document in
                    TaxDocumentRow(document: document)
                }
            }
        }
        .navigationTitle("Tax Documents")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct TaxDocumentRow: View {
    let document: TaxDocument
    @StateObject private var creatorService = CreatorService.shared

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(document.type.displayName)
                    .fontWeight(.medium)

                Text("\(document.year)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("Generated: \(document.generatedAt)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(Int(document.amount))")
                    .fontWeight(.bold)
                    .foregroundColor(.green)

                Button("Download") {
                    downloadDocument()
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(8)
            }
        }
        .padding(.vertical, 4)
    }

    private func downloadDocument() {
        Task {
            do {
                _ = try await creatorService.downloadTaxDocument(document.id)
            } catch {
                print("Failed to download document: \(error)")
            }
        }
    }
}

struct CreatorDataPrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Your Privacy Matters")
                    .font(.title2)
                    .fontWeight(.bold)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Data Collection")
                        .font(.headline)

                    Text("We collect information you provide directly to us, such as when you create an account, list an item, or contact us for support.")
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Data Usage")
                        .font(.headline)

                    Text("We use your information to provide our services, improve user experience, and communicate with you about your account.")
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Controls")
                        .font(.headline)

                    VStack(spacing: 8) {
                        Button("Download My Data") {
                            // Download data
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)

                        Button("Delete My Account") {
                            // Delete account
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(8)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Data & Privacy")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct AccountSecurityView: View {
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var twoFactorEnabled = false

    var body: some View {
        Form {
            Section("Change Password") {
                SecureField("Current Password", text: $currentPassword)
                SecureField("New Password", text: $newPassword)
                SecureField("Confirm New Password", text: $confirmPassword)

                Button("Update Password") {
                    updatePassword()
                }
                .disabled(newPassword != confirmPassword || newPassword.isEmpty)
            }

            Section("Two-Factor Authentication") {
                Toggle("Enable 2FA", isOn: $twoFactorEnabled)

                if twoFactorEnabled {
                    Text("Two-factor authentication adds an extra layer of security to your account.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section("Active Sessions") {
                HStack {
                    VStack(alignment: .leading) {
                        Text("iPhone")
                            .fontWeight(.medium)
                        Text("Current session")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text("Active")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .navigationTitle("Account Security")
        .navigationBarTitleDisplayMode(.large)
    }

    private func updatePassword() {
        // Implementation for updating password
    }
}

struct CreatorTermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Terms of Service")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Last updated: December 2024")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("1. Acceptance of Terms")
                    .font(.headline)

                Text("By using Brrow, you agree to these terms of service.")
                    .foregroundColor(.secondary)

                Text("2. Use of Service")
                    .font(.headline)

                Text("You may use our service to rent and list items in accordance with these terms.")
                    .foregroundColor(.secondary)

                // Add more terms content...
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CreatorAgreementView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Creator Agreement")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Last updated: December 2024")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("1. Creator Responsibilities")
                    .font(.headline)

                Text("As a creator on Brrow, you agree to provide accurate item descriptions and maintain quality standards.")
                    .foregroundColor(.secondary)

                Text("2. Payment Terms")
                    .font(.headline)

                Text("Payments are processed according to your selected payout schedule. Platform fees apply.")
                    .foregroundColor(.secondary)

                // Add more agreement content...
            }
            .padding()
        }
        .navigationTitle("Creator Agreement")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Creator Insights View

struct CreatorInsightsView: View {
    @StateObject private var creatorService = CreatorService.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(creatorService.insights) { insight in
                        InsightCard(insight: insight) {
                            Task {
                                try await creatorService.markInsightAsRead(insight.id)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Creator Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct CreatorSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        CreatorSettingsView()
    }
}