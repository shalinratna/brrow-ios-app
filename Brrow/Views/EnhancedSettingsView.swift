import SwiftUI
import MessageUI

struct EnhancedSettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var showingEditProfile = false
    @State private var showingChangeUsername = false
    @State private var showingChangePassword = false
    @State private var showingDeleteAccount = false
    @State private var showingPrivacySettings = false
    @State private var showingNotificationSettings = false
    @State private var showingLinkedAccounts = false
    @State private var showingAbout = false
    @State private var showingSupport = false
    @State private var showingTerms = false
    @State private var showingPrivacy = false
    @State private var showingPrivacyPolicy = false
    @State private var showingNotifications = false
    @State private var showingAppearance = false
    @State private var showingLanguage = false
    @State private var showingHelp = false
    @State private var showingWidgetTest = false
    @State private var newUsername = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var successMessage = ""

    // User preferences
    @AppStorage("pushNotifications") private var pushNotifications = true
    @AppStorage("emailNotifications") private var emailNotifications = true
    @AppStorage("smsNotifications") private var smsNotifications = false
    @AppStorage("marketingEmails") private var marketingEmails = false
    @AppStorage("darkMode") private var darkMode = false
    @AppStorage("autoPlayVideos") private var autoPlayVideos = true
    @AppStorage("highQualityImages") private var highQualityImages = true

    var body: some View {
        List {
            // Profile Section
            profileSection

            // Account Settings
            accountSection

            // Privacy & Security
            privacySection

            // Notifications
            notificationSection

            // App Settings
            appSettingsSection

            // Support & About
            supportSection

            // Legal
            legalSection

            // Sign Out
            signOutSection
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            EditPersonalInfoView()
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showingChangeUsername) {
            ChangeUsernameView()
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showingChangePassword) {
            ChangePasswordView()
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showingLinkedAccounts) {
            LinkedAccountsView()
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showingPrivacy) {
            PrivacySettingsView()
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showingNotifications) {
            NotificationPreferencesView()
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showingAppearance) {
            AppearanceSettingsView()
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showingLanguage) {
            LanguageSettingsView()
        }
        .sheet(isPresented: $showingHelp) {
            HelpCenterView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .sheet(isPresented: $showingTerms) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showingWidgetTest) {
            WidgetTestView()
        }
        .alert("Error", isPresented: .constant(!errorMessage.isEmpty)) {
            Button("OK") {
                errorMessage = ""
            }
        } message: {
            Text(errorMessage)
        }
        .alert("Success", isPresented: .constant(!successMessage.isEmpty)) {
            Button("OK") {
                successMessage = ""
            }
        } message: {
            Text(successMessage)
        }
    }

    // MARK: - Profile Section
    private var profileSection: some View {
        Section {
            HStack {
                // Profile Image
                if let user = authManager.currentUser {
                    BrrowAsyncImage.profileImage(url: user.profilePicture, size: 60)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.displayName ?? user.username ?? "User")
                            .font(.headline)
                        Text("@\(user.username ?? "")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(user.email ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .onTapGesture {
                showingEditProfile = true
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            EditPersonalInfoView()
        }
    }

    // MARK: - Account Section
    private var accountSection: some View {
        Section("Account") {
            // Personal Information
            Button(action: { showingEditProfile = true }) {
                SettingsRow(
                    icon: "person.text.rectangle",
                    title: "Personal Information",
                    subtitle: "Name, email, phone, birthdate"
                )
            }

            // Username
            Button(action: { showingChangeUsername = true }) {
                SettingsRow(
                    icon: "at",
                    title: "Username",
                    subtitle: "@\(authManager.currentUser?.username ?? "")"
                )
            }

            // Change Password - only show if not using social login
            if authManager.currentUser?.appleUserId == nil {
                Button(action: { showingChangePassword = true }) {
                    SettingsRow(
                        icon: "lock.rotation",
                        title: "Change Password",
                        subtitle: nil
                    )
                }
            }

            // Linked Accounts
            Button(action: { showingLinkedAccounts = true }) {
                SettingsRow(
                    icon: "link",
                    title: "Linked Accounts",
                    subtitle: "Google, Apple, Facebook"
                )
            }

            // Verification Status
            HStack {
                Image(systemName: authManager.currentUser?.isVerified == true ? "checkmark.seal.fill" : "xmark.seal")
                    .foregroundColor(authManager.currentUser?.isVerified == true ? .green : .orange)
                Text("Account Verification")
                Spacer()
                Text(authManager.currentUser?.isVerified == true ? "Verified" : "Pending")
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Privacy Section
    private var privacySection: some View {
        Section("Privacy & Security") {
            Button(action: { showingPrivacySettings = true }) {
                SettingsRow(
                    icon: "hand.raised.shield",
                    title: "Privacy Settings",
                    subtitle: "Control who can see your activity"
                )
            }

            Toggle(isOn: .constant(true)) {
                HStack {
                    Image(systemName: "faceid")
                        .foregroundColor(.blue)
                    Text("Face ID / Touch ID")
                }
            }

            Button(action: {}) {
                SettingsRow(
                    icon: "key",
                    title: "Two-Factor Authentication",
                    subtitle: "Not enabled"
                )
            }

            Button(action: {}) {
                SettingsRow(
                    icon: "clock.arrow.circlepath",
                    title: "Login History",
                    subtitle: nil
                )
            }
        }
        .sheet(isPresented: $showingPrivacySettings) {
            PrivacySettingsView()
        }
    }

    // MARK: - Notification Section
    private var notificationSection: some View {
        Section("Notifications") {
            Toggle(isOn: $pushNotifications) {
                HStack {
                    Image(systemName: "bell")
                        .foregroundColor(.red)
                    Text("Push Notifications")
                }
            }

            Toggle(isOn: $emailNotifications) {
                HStack {
                    Image(systemName: "envelope")
                        .foregroundColor(.blue)
                    Text("Email Notifications")
                }
            }

            Toggle(isOn: $smsNotifications) {
                HStack {
                    Image(systemName: "message")
                        .foregroundColor(.green)
                    Text("SMS Notifications")
                }
            }

            Toggle(isOn: $marketingEmails) {
                HStack {
                    Image(systemName: "megaphone")
                        .foregroundColor(.orange)
                    Text("Marketing & Promotions")
                }
            }
        }
    }

    // MARK: - App Settings Section
    private var appSettingsSection: some View {
        Section("App Settings") {
            Toggle(isOn: $darkMode) {
                HStack {
                    Image(systemName: "moon")
                        .foregroundColor(.indigo)
                    Text("Dark Mode")
                }
            }

            Toggle(isOn: $autoPlayVideos) {
                HStack {
                    Image(systemName: "play.rectangle")
                        .foregroundColor(.purple)
                    Text("Auto-Play Videos")
                }
            }

            Toggle(isOn: $highQualityImages) {
                HStack {
                    Image(systemName: "photo")
                        .foregroundColor(.green)
                    Text("High Quality Images")
                }
            }

            Button(action: {}) {
                SettingsRow(
                    icon: "arrow.clockwise",
                    title: "Clear Cache",
                    subtitle: "Free up storage space"
                )
            }
        }
    }

    // MARK: - Support Section
    private var supportSection: some View {
        Section("Help & Support") {
            Button(action: { showingSupport = true }) {
                SettingsRow(
                    icon: "questionmark.circle",
                    title: "Help Center",
                    subtitle: nil
                )
            }

            Button(action: { sendEmail() }) {
                SettingsRow(
                    icon: "envelope",
                    title: "Contact Support",
                    subtitle: nil
                )
            }

            Button(action: {}) {
                SettingsRow(
                    icon: "exclamationmark.triangle",
                    title: "Report a Problem",
                    subtitle: nil
                )
            }

            #if DEBUG
            Button(action: { showingWidgetTest = true }) {
                SettingsRow(
                    icon: "waveform.badge.plus",
                    title: "Widget Tests",
                    subtitle: "Test widget integration"
                )
            }
            #endif

            Button(action: { showingAbout = true }) {
                SettingsRow(
                    icon: "info.circle",
                    title: "About",
                    subtitle: nil
                )
            }
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }

    // MARK: - Legal Section
    private var legalSection: some View {
        Section("Legal") {
            Button(action: { showingTerms = true }) {
                SettingsRow(
                    icon: "doc.text",
                    title: "Terms of Service",
                    subtitle: nil
                )
            }

            Button(action: { showingPrivacy = true }) {
                SettingsRow(
                    icon: "lock.doc",
                    title: "Privacy Policy",
                    subtitle: nil
                )
            }

            Button(action: {}) {
                SettingsRow(
                    icon: "building.2",
                    title: "Licenses",
                    subtitle: nil
                )
            }
        }
    }

    // MARK: - Sign Out Section
    private var signOutSection: some View {
        Section {
            Button(action: signOut) {
                HStack {
                    Spacer()
                    Text("Sign Out")
                        .foregroundColor(.red)
                    Spacer()
                }
            }

            Button(action: { showingDeleteAccount = true }) {
                HStack {
                    Spacer()
                    Text("Delete Account")
                        .foregroundColor(.red)
                        .fontWeight(.semibold)
                    Spacer()
                }
            }
        }
        .confirmationDialog("Delete Account", isPresented: $showingDeleteAccount) {
            Button("Delete Account", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
    }

    // MARK: - Helper Methods
    private func signOut() {
        authManager.logout()
        dismiss()
    }

    private func deleteAccount() {
        // Implement account deletion
    }

    private func sendEmail() {
        if MFMailComposeViewController.canSendMail() {
            // Open mail composer
        }
    }
}

// MARK: - Settings Row Component
struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String?

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 28)

            VStack(alignment: .leading) {
                Text(title)
                    .foregroundColor(.primary)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Supporting Views
struct EditPersonalInfoView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var birthdate = Date()
    @State private var bio = ""
    @State private var isLoading = false

    var body: some View {
        Form {
            Section("Personal Information") {
                TextField("First Name", text: $firstName)
                TextField("Last Name", text: $lastName)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                TextField("Phone", text: $phone)
                    .keyboardType(.phonePad)
                DatePicker("Birthdate", selection: $birthdate, displayedComponents: .date)
            }

            Section("Bio") {
                TextEditor(text: $bio)
                    .frame(minHeight: 100)
            }

            Section("Display Name") {
                TextField("Display Name", text: .constant(authManager.currentUser?.displayName ?? ""))
                Text("This is how your name appears on your profile")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveProfile()
                }
                .disabled(isLoading)
            }
        }
        .onAppear {
            loadUserData()
        }
    }

    private func loadUserData() {
        if let user = authManager.currentUser {
            firstName = user.firstName ?? ""
            lastName = user.lastName ?? ""
            email = user.email
            phone = user.phone ?? ""
            bio = user.bio ?? ""
        }
    }

    private func saveProfile() {
        // Implement save profile
        dismiss()
    }
}

struct ChangeUsernameView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var newUsername = ""
    @State private var isLoading = false
    @State private var errorMessage = ""

    var body: some View {
        Form {
            Section {
                TextField("New Username", text: $newUsername)
                    .autocapitalization(.none)
            } header: {
                Text("Choose a new username")
            } footer: {
                Text("You can only change your username once every 90 days")
                    .foregroundColor(.secondary)
            }

            if !errorMessage.isEmpty {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Change Username")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    changeUsername()
                }
                .disabled(isLoading || newUsername.isEmpty)
            }
        }
    }

    private func changeUsername() {
        // Implement username change
        Task {
            isLoading = true
            // Call API to change username
            isLoading = false
            dismiss()
        }
    }
}

struct ChangePasswordView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false

    var body: some View {
        Form {
            Section("Current Password") {
                SecureField("Current Password", text: $currentPassword)
            }

            Section("New Password") {
                SecureField("New Password", text: $newPassword)
                SecureField("Confirm New Password", text: $confirmPassword)
            }
        }
        .navigationTitle("Change Password")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    changePassword()
                }
                .disabled(isLoading || currentPassword.isEmpty || newPassword.isEmpty)
            }
        }
    }

    private func changePassword() {
        // Implement password change
        dismiss()
    }
}

struct LinkedAccountsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    @State private var googleLinked = false
    @State private var appleLinked = false
    @State private var facebookLinked = false

    var body: some View {
        List {
            Section("Linked Accounts") {
                LinkedAccountRow(
                    provider: "Google",
                    icon: "G",
                    iconColor: .red,
                    isLinked: $googleLinked
                )

                LinkedAccountRow(
                    provider: "Apple",
                    icon: "applelogo",
                    iconColor: .black,
                    isLinked: $appleLinked
                )

                LinkedAccountRow(
                    provider: "Facebook",
                    icon: "f.circle.fill",
                    iconColor: .blue,
                    isLinked: $facebookLinked
                )
            }

            Section {
                Text("Link your social accounts to sign in faster and recover your account more easily")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Linked Accounts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .onAppear {
            loadLinkedAccountStatus()
        }
    }

    private func loadLinkedAccountStatus() {
        // Check auth method to determine which accounts are linked
        if let authMethod = authManager.currentUser?.authMethod {
            switch authMethod {
            case "GOOGLE":
                googleLinked = true
            case "APPLE":
                appleLinked = true
            default:
                break
            }
        }

        // Check if user has Apple ID (for users who have linked Apple)
        if let user = authManager.currentUser {
            if let appleId = user.appleUserId, !appleId.isEmpty {
                appleLinked = true
            }
        }
    }
}

struct LinkedAccountRow: View {
    let provider: String
    let icon: String
    let iconColor: Color
    @Binding var isLinked: Bool

    var body: some View {
        HStack {
            if icon == "G" {
                Text("G")
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundColor(iconColor)
                    .frame(width: 30, height: 30)
            } else {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .frame(width: 30, height: 30)
            }

            Text(provider)

            Spacer()

            Button(isLinked ? "Unlink" : "Link") {
                isLinked.toggle()
            }
            .foregroundColor(isLinked ? .red : .blue)
        }
    }
}

struct PrivacySettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var profileVisibility = "Everyone"
    @State private var showActivity = true
    @State private var showListings = true
    @State private var allowMessages = true

    var body: some View {
        Form {
            Section("Profile Visibility") {
                Picker("Who can see your profile", selection: $profileVisibility) {
                    Text("Everyone").tag("Everyone")
                    Text("Registered Users").tag("Registered")
                    Text("Nobody").tag("Nobody")
                }
            }

            Section("Activity") {
                Toggle("Show my activity", isOn: $showActivity)
                Toggle("Show my listings", isOn: $showListings)
                Toggle("Allow messages", isOn: $allowMessages)
            }
        }
        .navigationTitle("Privacy Settings")
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

struct AboutView: View {
    @Environment(\.dismiss) var dismiss

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("\(appVersion) (\(buildNumber))")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Developer")
                    Spacer()
                    Text("Brrow Inc.")
                        .foregroundColor(.secondary)
                }
            }

            Section("Connect") {
                Link(destination: URL(string: "https://brrowapp.com")!) {
                    HStack {
                        Text("Website")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundColor(.secondary)
                    }
                }

                Link(destination: URL(string: "https://twitter.com/brrowapp")!) {
                    HStack {
                        Text("Twitter")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("About Brrow")
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

// MARK: - Additional Settings Views

struct NotificationPreferencesView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    @AppStorage("pushNotifications") private var pushNotifications = true
    @AppStorage("emailNotifications") private var emailNotifications = true
    @AppStorage("smsNotifications") private var smsNotifications = false

    var body: some View {
        Form {
            Section("Push Notifications") {
                Toggle("Enable Push Notifications", isOn: $pushNotifications)
                Toggle("New Messages", isOn: $pushNotifications)
                Toggle("New Offers", isOn: $pushNotifications)
                Toggle("Rental Reminders", isOn: $pushNotifications)
            }

            Section("Email Preferences") {
                Toggle("Email Notifications", isOn: $emailNotifications)
                Toggle("Weekly Digest", isOn: $emailNotifications)
                Toggle("Marketing Emails", isOn: $emailNotifications)
            }

            Section("SMS") {
                Toggle("SMS Notifications", isOn: $smsNotifications)
            }
        }
        .navigationTitle("Notifications")
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


struct HelpCenterView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        List {
            Section("Quick Help") {
                NavigationLink("How to Create a Listing", destination: Text("Help content"))
                NavigationLink("How to Rent an Item", destination: Text("Help content"))
                NavigationLink("Payment & Fees", destination: Text("Help content"))
                NavigationLink("Safety Tips", destination: Text("Help content"))
            }

            Section("Contact Support") {
                Link("Email Support", destination: URL(string: "mailto:support@brrowapp.com")!)
                Link("Visit Help Center", destination: URL(string: "https://brrowapp.com/help")!)
            }
        }
        .navigationTitle("Help Center")
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

struct EnhancedSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        EnhancedSettingsView()
            .environmentObject(AuthManager.shared)
    }
}