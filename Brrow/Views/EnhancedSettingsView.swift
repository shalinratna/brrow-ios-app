import SwiftUI
import MessageUI

struct EnhancedSettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var showingEditProfile = false
    @State private var showingChangeUsername = false
    @State private var showingChangePassword = false
    @State private var showingCreatePassword = false
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
    @State private var hasPassword: Bool? = nil
    @State private var isCheckingPassword = false

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
        .sheet(isPresented: $showingCreatePassword) {
            if let user = authManager.currentUser {
                let provider = user.authMethod == "google" ? "Google" : user.authMethod == "apple" ? "Apple" : "OAuth"
                CreatePasswordView(provider: provider)
                    .environmentObject(authManager)
            }
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
        .onAppear {
            checkPasswordStatus()
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

            // Username - with cooldown indicator
            Button(action: { showingChangeUsername = true }) {
                HStack {
                    Image(systemName: "at")
                        .foregroundColor(.blue)
                        .frame(width: 28)

                    VStack(alignment: .leading) {
                        Text("Username")
                            .foregroundColor(.primary)
                        Text("@\(authManager.currentUser?.username ?? "")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Password Management - show based on password existence
            if isCheckingPassword {
                HStack {
                    Image(systemName: "lock.rotation")
                        .foregroundColor(.blue)
                        .frame(width: 28)
                    Text("Checking password status...")
                        .foregroundColor(.secondary)
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                }
            } else if let hasPassword = hasPassword {
                if hasPassword {
                    // User has a password - show Change Password
                    Button(action: { showingChangePassword = true }) {
                        SettingsRow(
                            icon: "lock.rotation",
                            title: "Change Password",
                            subtitle: "Update your password"
                        )
                    }
                } else {
                    // User doesn't have a password - show Create Password
                    Button(action: { showingCreatePassword = true }) {
                        SettingsRow(
                            icon: "lock.shield",
                            title: "Create Password",
                            subtitle: "Enable email login"
                        )
                    }
                }
            }

            // Linked Accounts
            Button(action: { showingLinkedAccounts = true }) {
                SettingsRow(
                    icon: "link",
                    title: "Linked Accounts",
                    subtitle: "Google, Apple"
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
    private func checkPasswordStatus() {
        isCheckingPassword = true

        Task {
            do {
                let response = try await APIClient.shared.checkPasswordExists()

                await MainActor.run {
                    hasPassword = response.hasPassword
                    isCheckingPassword = false
                }
            } catch {
                await MainActor.run {
                    // On error, assume they have a password to be safe
                    // (better to show change password than create password if we're unsure)
                    hasPassword = true
                    isCheckingPassword = false
                    print("Error checking password status: \(error.localizedDescription)")
                }
            }
        }
    }

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

// MARK: - Enhanced Change Username View with Policy Flow
struct ChangeUsernameView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss

    // View state management
    @State private var currentStep: UsernameChangeStep = .policy
    @State private var newUsername = ""
    @State private var isLoading = false
    @State private var isCheckingAvailability = false
    @State private var errorMessage = ""
    @State private var usernameAvailable: Bool? = nil
    @State private var showSuccess = false
    @State private var debouncedUsername = ""

    // Timer for debounced username check
    @State private var debounceTimer: Timer?

    enum UsernameChangeStep {
        case policy
        case entry
        case confirmation
    }

    // Calculate cooldown status
    private var cooldownStatus: (isOnCooldown: Bool, daysRemaining: Int, lastChanged: Date?) {
        guard let lastChange = authManager.currentUser?.lastUsernameChange else {
            return (false, 0, nil)
        }

        let daysSinceChange = Int(Date().timeIntervalSince(lastChange) / (24 * 60 * 60))
        let daysRemaining = max(0, 90 - daysSinceChange)

        return (daysRemaining > 0, daysRemaining, lastChange)
    }

    var body: some View {
        NavigationView {
            ZStack {
                switch currentStep {
                case .policy:
                    policyView
                case .entry:
                    entryView
                case .confirmation:
                    confirmationView
                }

                if isLoading {
                    loadingOverlay
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
            }
            .alert("Success!", isPresented: $showSuccess) {
                Button("Done") {
                    dismiss()
                }
            } message: {
                Text("Your username has been changed to @\(newUsername)")
            }
        }
    }

    // MARK: - Step 1: Policy Explanation
    private var policyView: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                // Header Icon
                ZStack {
                    Circle()
                        .fill(Theme.Colors.primary.opacity(0.1))
                        .frame(width: 80, height: 80)

                    Image(systemName: "at.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Theme.Colors.primary)
                }
                .padding(.top, Theme.Spacing.xl)

                VStack(spacing: Theme.Spacing.md) {
                    Text("Change Username")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Current: @\(authManager.currentUser?.username ?? "")")
                        .font(.subheadline)
                        .foregroundColor(Theme.Colors.secondaryText)
                }

                // Policy Information Card
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("Important Information")
                            .font(.headline)
                    }

                    policyItem(icon: "clock", text: "Can be changed once every 90 days")
                    policyItem(icon: "lock.shield", text: "Old username reserved for 90 days")
                    policyItem(icon: "arrow.triangle.2.circlepath", text: "Changes apply everywhere immediately")
                    policyItem(icon: "exclamationmark.triangle", text: "This action cannot be undone")
                }
                .padding(Theme.Spacing.lg)
                .background(Color.blue.opacity(0.05))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )

                // Cooldown Status
                if cooldownStatus.isOnCooldown {
                    VStack(spacing: Theme.Spacing.sm) {
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.red)
                            Text("Cooldown Active")
                                .font(.headline)
                                .foregroundColor(.red)
                        }

                        Text("\(cooldownStatus.daysRemaining) days remaining")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.red)

                        if let lastChanged = cooldownStatus.lastChanged {
                            Text("Last changed: \(lastChanged, style: .date)")
                                .font(.caption)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(Theme.Spacing.lg)
                    .background(Color.red.opacity(0.05))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.red.opacity(0.2), lineWidth: 1)
                    )
                } else {
                    VStack(spacing: Theme.Spacing.sm) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Ready to Change")
                                .font(.headline)
                                .foregroundColor(.green)
                        }

                        if let lastChanged = cooldownStatus.lastChanged {
                            Text("Last changed: \(lastChanged, style: .date)")
                                .font(.caption)
                                .foregroundColor(Theme.Colors.secondaryText)
                        } else {
                            Text("Never changed before")
                                .font(.caption)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(Theme.Spacing.lg)
                    .background(Color.green.opacity(0.05))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.green.opacity(0.2), lineWidth: 1)
                    )
                }

                Spacer()

                // Action Buttons
                VStack(spacing: Theme.Spacing.md) {
                    if !cooldownStatus.isOnCooldown {
                        Button(action: {
                            withAnimation {
                                currentStep = .entry
                            }
                        }) {
                            Text("Continue")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(Theme.Spacing.md)
                                .background(Theme.Colors.primary)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }

                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(Theme.Spacing.md)
                            .background(Color.gray.opacity(0.1))
                            .foregroundColor(Theme.Colors.text)
                            .cornerRadius(12)
                    }
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.Colors.background)
    }

    // MARK: - Step 2: Username Entry with Validation
    private var entryView: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                // Header
                VStack(spacing: Theme.Spacing.md) {
                    Text("Choose New Username")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Your username must be unique and follow our guidelines")
                        .font(.subheadline)
                        .foregroundColor(Theme.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Theme.Spacing.xl)

                // Username Input
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    HStack(spacing: Theme.Spacing.sm) {
                        Text("@")
                            .font(.title3)
                            .foregroundColor(Theme.Colors.secondaryText)

                        TextField("username", text: $newUsername)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .font(.title3)
                            .onChange(of: newUsername) { newValue in
                                // Debounce availability check
                                debounceTimer?.invalidate()
                                usernameAvailable = nil

                                if newValue.count >= 3 {
                                    debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                                        checkUsernameAvailability(newValue)
                                    }
                                }
                            }

                        if isCheckingAvailability {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else if let available = usernameAvailable {
                            Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(available ? .green : .red)
                        }
                    }
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.surface)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(borderColor, lineWidth: 2)
                    )

                    // Validation Messages
                    if !newUsername.isEmpty {
                        if newUsername.count < 3 {
                            validationMessage("Username must be at least 3 characters", type: .error)
                        } else if newUsername.count > 20 {
                            validationMessage("Username must be 20 characters or less", type: .error)
                        } else if !isValidUsername(newUsername) {
                            validationMessage("Only letters, numbers, and underscores allowed", type: .error)
                        } else if let available = usernameAvailable {
                            if available {
                                validationMessage("Username is available!", type: .success)
                            } else {
                                validationMessage("This username is already taken", type: .error)
                            }
                        }
                    }
                }

                // Requirements Card
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    Text("Requirements")
                        .font(.headline)

                    requirementItem("3-20 characters", met: newUsername.count >= 3 && newUsername.count <= 20)
                    requirementItem("Letters, numbers, underscore only", met: isValidUsername(newUsername) || newUsername.isEmpty)
                    requirementItem("Must be unique", met: usernameAvailable == true)
                }
                .padding(Theme.Spacing.lg)
                .background(Theme.Colors.surface)
                .cornerRadius(16)

                Spacer()

                // Action Buttons
                VStack(spacing: Theme.Spacing.md) {
                    Button(action: {
                        withAnimation {
                            currentStep = .confirmation
                        }
                    }) {
                        Text("Continue")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(Theme.Spacing.md)
                            .background(canProceed ? Theme.Colors.primary : Color.gray.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(!canProceed)

                    Button(action: {
                        withAnimation {
                            currentStep = .policy
                        }
                    }) {
                        Text("Back")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(Theme.Spacing.md)
                            .background(Color.gray.opacity(0.1))
                            .foregroundColor(Theme.Colors.text)
                            .cornerRadius(12)
                    }
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.Colors.background)
    }

    // MARK: - Step 3: Confirmation
    private var confirmationView: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                // Warning Icon
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: 80, height: 80)

                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                }
                .padding(.top, Theme.Spacing.xl)

                VStack(spacing: Theme.Spacing.md) {
                    Text("Confirm Change")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Please review your username change carefully")
                        .font(.subheadline)
                        .foregroundColor(Theme.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }

                // Change Summary
                VStack(spacing: Theme.Spacing.lg) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Username")
                                .font(.caption)
                                .foregroundColor(Theme.Colors.secondaryText)
                            Text("@\(authManager.currentUser?.username ?? "")")
                                .font(.headline)
                        }

                        Spacer()

                        Image(systemName: "arrow.right")
                            .foregroundColor(Theme.Colors.secondaryText)

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("New Username")
                                .font(.caption)
                                .foregroundColor(Theme.Colors.secondaryText)
                            Text("@\(newUsername)")
                                .font(.headline)
                                .foregroundColor(Theme.Colors.primary)
                        }
                    }
                    .padding(Theme.Spacing.lg)
                    .background(Theme.Colors.surface)
                    .cornerRadius(16)
                }

                // Final Warning
                VStack(spacing: Theme.Spacing.md) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Important Reminder")
                            .font(.headline)
                            .foregroundColor(.orange)
                    }

                    Text("You won't be able to change your username again for 90 days")
                        .font(.subheadline)
                        .foregroundColor(Theme.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(Theme.Spacing.lg)
                .background(Color.orange.opacity(0.05))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                )

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                }

                Spacer()

                // Final Action Buttons
                VStack(spacing: Theme.Spacing.md) {
                    Button(action: performUsernameChange) {
                        Text("Confirm Change")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(Theme.Spacing.md)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(isLoading)

                    Button(action: {
                        withAnimation {
                            currentStep = .entry
                        }
                    }) {
                        Text("Back")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(Theme.Spacing.md)
                            .background(Color.gray.opacity(0.1))
                            .foregroundColor(Theme.Colors.text)
                            .cornerRadius(12)
                    }
                    .disabled(isLoading)
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.Colors.background)
    }

    // MARK: - Helper Views
    private func policyItem(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(Theme.Colors.primary)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
                .foregroundColor(Theme.Colors.text)
        }
    }

    private func requirementItem(_ text: String, met: Bool) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .foregroundColor(met ? .green : Theme.Colors.secondaryText)
            Text(text)
                .font(.subheadline)
                .foregroundColor(Theme.Colors.text)
        }
    }

    private func validationMessage(_ text: String, type: MessageType) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: type == .success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(type == .success ? .green : .red)
            Text(text)
                .font(.caption)
                .foregroundColor(type == .success ? .green : .red)
        }
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: Theme.Spacing.md) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text("Changing username...")
                    .foregroundColor(.white)
                    .fontWeight(.medium)
            }
            .padding(Theme.Spacing.xl)
            .background(Color.black.opacity(0.8))
            .cornerRadius(16)
        }
    }

    // MARK: - Computed Properties
    private var navigationTitle: String {
        switch currentStep {
        case .policy: return "Username Policy"
        case .entry: return "New Username"
        case .confirmation: return "Confirm Change"
        }
    }

    private var borderColor: Color {
        if newUsername.isEmpty {
            return Theme.Colors.border
        } else if let available = usernameAvailable {
            return available ? .green : .red
        } else {
            return Theme.Colors.border
        }
    }

    private var canProceed: Bool {
        newUsername.count >= 3 &&
        newUsername.count <= 20 &&
        isValidUsername(newUsername) &&
        usernameAvailable == true
    }

    // MARK: - Helper Methods
    private func isValidUsername(_ username: String) -> Bool {
        let usernameRegex = "^[a-zA-Z0-9_]+$"
        return username.range(of: usernameRegex, options: .regularExpression) != nil
    }

    private func checkUsernameAvailability(_ username: String) {
        guard username.count >= 3 && username.count <= 20 && isValidUsername(username) else {
            return
        }

        // Don't check if it's the same as current username
        if username.lowercased() == authManager.currentUser?.username.lowercased() {
            usernameAvailable = false
            return
        }

        isCheckingAvailability = true

        Task {
            do {
                let response = try await APIClient.shared.checkUsernameAvailability(username: username)

                await MainActor.run {
                    usernameAvailable = response.available
                    isCheckingAvailability = false
                }
            } catch {
                await MainActor.run {
                    // On error, assume not available to be safe
                    usernameAvailable = false
                    isCheckingAvailability = false
                    print("Error checking username availability: \(error.localizedDescription)")
                }
            }
        }
    }

    private func performUsernameChange() {
        isLoading = true
        errorMessage = ""

        Task {
            do {
                let updatedUser = try await APIClient.shared.changeUsername(newUsername)

                await MainActor.run {
                    authManager.currentUser = updatedUser
                    isLoading = false
                    showSuccess = true

                    // Notify other views to refresh
                    NotificationCenter.default.post(name: .userDidUpdate, object: nil)
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    if let apiError = error as? BrrowAPIError {
                        switch apiError {
                        case .serverError(let message):
                            errorMessage = message
                        default:
                            errorMessage = "Failed to change username. Please try again."
                        }
                    } else {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }

    enum MessageType {
        case success
        case error
    }
}

// ChangePasswordView and LinkedAccountsView are defined in separate files

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