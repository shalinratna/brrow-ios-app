//
//  ModernSettingsView.swift
//  Brrow
//
//  Beautiful modern settings with glassmorphism and animations
//

import SwiftUI

struct ModernSettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = SettingsViewModel()

    @State private var selectedSection: SettingsSection? = nil
    @State private var animateIn = false
    @State private var pulseAnimation = false
    @State private var showEditProfile = false
    @State private var showLinkedAccounts = false

    // User preferences
    @AppStorage("pushNotifications") private var pushNotifications = true
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("textSizeIndex") private var textSizeIndex = 1 // 0=Small, 1=Medium, 2=Large
    @AppStorage("selectedLanguage") private var selectedLanguage = "en"
    @AppStorage("highQualityImages") private var highQualityImages = true

    private let textSizes = ["Small", "Medium", "Large"]
    private let languages = [
        ("en", "English"),
        ("es", "Español"),
        ("fr", "Français"),
        ("de", "Deutsch"),
        ("zh", "中文"),
        ("ja", "日本語")
    ]

    private var currentLanguageName: String {
        languages.first { $0.0 == selectedLanguage }?.1 ?? "English"
    }

    private func itemsForSection(_ section: SettingsSection) -> [SettingsItem] {
        switch section {
        case .account:
            return [
                SettingsItem(icon: "person.circle", title: "Edit Profile", subtitle: "Update your profile info", color: .blue),
                SettingsItem(icon: "at", title: "Username", subtitle: AuthManager.shared.currentUser?.username, color: .purple),
                SettingsItem(icon: "lock.rotation", title: "Change Password", color: .orange),
                SettingsItem(icon: "link", title: "Linked Accounts", subtitle: "Google, Apple, Facebook", color: .indigo)
            ]
        case .privacy:
            return [
                SettingsItem(icon: "hand.raised.shield", title: "Privacy Settings", subtitle: "Control your data", color: .green),
                SettingsItem(icon: "eye.slash", title: "Blocked Users", color: .red),
                SettingsItem(icon: "location.slash", title: "Location Services", toggle: .constant(true), color: .blue)
            ]
        case .notifications:
            return [
                SettingsItem(icon: "bell", title: "Push Notifications", toggle: $pushNotifications, color: .red),
                SettingsItem(icon: "envelope", title: "Email Preferences", color: .blue),
                SettingsItem(icon: "message", title: "SMS Alerts", toggle: .constant(false), color: .green)
            ]
        case .appearance:
            return [
                SettingsItem(icon: "moon.circle", title: "Dark Mode", toggle: $isDarkMode, color: .purple),
                SettingsItem(icon: "textformat", title: "Text Size", value: textSizes[textSizeIndex], color: .orange),
                SettingsItem(icon: "globe", title: "Language", value: currentLanguageName, color: .blue)
            ]
        case .support:
            return [
                SettingsItem(icon: "questionmark.circle", title: "Help Center", color: .blue),
                SettingsItem(icon: "envelope", title: "Contact Support", color: .green),
                SettingsItem(icon: "doc.text", title: "Report a Problem", color: .orange)
            ]
        case .about:
            return [
                SettingsItem(icon: "doc.text", title: "Terms of Service", color: .blue),
                SettingsItem(icon: "hand.raised", title: "Privacy Policy", color: .green),
                SettingsItem(icon: "building.2", title: "Licenses", color: .purple)
            ]
        #if DEBUG
        case .developer:
            return [
                SettingsItem(icon: "ladybug.fill", title: "Test PEST Webhooks", subtitle: "Send test messages to Discord", color: .green, action: {
                    // Test all webhooks
                    PESTWebhooks.testAllWebhooks()

                    // Send a test error
                    PESTControlSystem.shared.captureError(
                        NSError(domain: "TestError", code: 0, userInfo: [
                            NSLocalizedDescriptionKey: "Manual test from Settings"
                        ]),
                        context: "PEST Test Button",
                        severity: .medium,
                        userInfo: [
                            "source": "settings",
                            "test": true
                        ]
                    )
                }),
                SettingsItem(icon: "hammer.fill", title: "Developer Options", color: .orange)
            ]
        #endif
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Animated gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Theme.Colors.primary.opacity(0.1),
                        Theme.Colors.primary.opacity(0.05),
                        Color.clear
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Profile Header
                        profileHeader
                            .padding(.top, 20)
                            .scaleEffect(animateIn ? 1 : 0.8)
                            .opacity(animateIn ? 1 : 0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: animateIn)

                        // Settings Sections
                        ForEach(SettingsSection.allCases, id: \.self) { section in
                            settingsCard(for: section, items: itemsForSection(section))
                                .scaleEffect(animateIn ? 1 : 0.9)
                                .opacity(animateIn ? 1 : 0)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.7)
                                    .delay(Double(section.index) * 0.05),
                                    value: animateIn
                                )
                        }

                        // Sign Out Button
                        signOutButton
                            .padding(.vertical, 20)
                            .scaleEffect(animateIn ? 1 : 0.8)
                            .opacity(animateIn ? 1 : 0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3), value: animateIn)

                        // App Info
                        appInfo
                            .padding(.bottom, 30)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.Colors.text)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(Theme.Colors.text.opacity(0.6))
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 30, height: 30)
                            )
                    }
                }
            }
        }
        .sheet(item: $selectedSection) { section in
            sectionDetailView(for: section)
        }
        .sheet(isPresented: $showEditProfile) {
            if let currentUser = authManager.currentUser {
                EditProfileView(user: currentUser)
                    .environmentObject(authManager)
            }
        }
        .sheet(isPresented: $showLinkedAccounts) {
            LinkedAccountsView()
                .environmentObject(authManager)
        }
        .onAppear {
            withAnimation {
                animateIn = true
            }
            startPulseAnimation()
            viewModel.loadUserData()
        }
    }

    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 15) {
            // Profile Picture with gradient border
            ZStack {
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            gradient: Gradient(colors: [Theme.Colors.primary, Theme.Colors.primary.opacity(0.5)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 90, height: 90)
                    .scaleEffect(pulseAnimation ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseAnimation)

                if let profilePic = authManager.currentUser?.profilePicture {
                    AsyncImage(url: URL(string: profilePic)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    } placeholder: {
                        Circle()
                            .fill(Theme.Colors.secondaryBackground)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(Theme.Colors.secondaryText)
                            )
                    }
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Theme.Colors.primary.opacity(0.3), Theme.Colors.primary.opacity(0.1)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text(authManager.currentUser?.firstName?.prefix(1).uppercased() ?? "U")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.Colors.primary)
                        )
                }
            }

            // User Info - Simple username only
            VStack(spacing: 5) {
                Text("@\(authManager.currentUser?.username ?? "user")")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.Colors.text)

                Text(authManager.currentUser?.email ?? "")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.Colors.secondaryText)

                if authManager.currentUser?.isVerified == true {
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                        Text("Verified Account")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.1))
                    )
                }
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: Theme.Colors.primary.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }

    // MARK: - Settings Card
    private func settingsCard(for section: SettingsSection, items: [SettingsItem]) -> some View {
        VStack(spacing: 0) {
            ForEach(items, id: \.title) { item in
                Button(action: {
                    handleItemTap(item: item, section: section)
                }) {
                    HStack(spacing: 15) {
                        // Icon with gradient background
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [item.color.opacity(0.3), item.color.opacity(0.1)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40, height: 40)

                            Image(systemName: item.icon)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(item.color)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.title)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(Theme.Colors.text)

                            if let subtitle = item.subtitle {
                                Text(subtitle)
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(Theme.Colors.secondaryText)
                            }
                        }

                        Spacer()

                        // Trailing content
                        if let toggle = item.toggle {
                            Toggle("", isOn: toggle)
                                .labelsHidden()
                                .tint(Theme.Colors.primary)
                        } else if let value = item.value {
                            Text(value)
                                .font(.system(size: 14))
                                .foregroundColor(Theme.Colors.secondaryText)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Theme.Colors.secondaryText.opacity(0.5))
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Theme.Colors.secondaryText.opacity(0.5))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
                .buttonStyle(PlainButtonStyle())

                if item != items.last {
                    Divider()
                        .padding(.leading, 71)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.Colors.background)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }

    // MARK: - Sign Out Button
    private var signOutButton: some View {
        Button(action: {
            withAnimation(.spring()) {
                authManager.logout()
                dismiss()
            }
        }) {
            HStack {
                Image(systemName: "arrow.right.square")
                    .font(.system(size: 20, weight: .semibold))

                Text("Sign Out")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.red.opacity(0.8), Color.red]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: Color.red.opacity(0.3), radius: 10, x: 0, y: 5)
        }
    }

    // MARK: - App Info
    private var appInfo: some View {
        VStack(spacing: 8) {
            Image("app-icon")
                .resizable()
                .frame(width: 60, height: 60)
                .cornerRadius(12)

            Text("Brrow")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(Theme.Colors.text)

            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")")
                .font(.system(size: 14))
                .foregroundColor(Theme.Colors.secondaryText)

            Text("Made with ❤️ in California")
                .font(.system(size: 12))
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .padding(.vertical, 20)
    }

    // MARK: - Actions
    private func handleItemTap(item: SettingsItem, section: SettingsSection) {
        // Special handling for Edit Profile
        if item.title == "Edit Profile" {
            showEditProfile = true
            return
        }

        // Special handling for Linked Accounts
        if item.title == "Linked Accounts" {
            showLinkedAccounts = true
            return
        }

        // If item has a custom action, execute it
        if let action = item.action {
            action()
        } else {
            // Otherwise, navigate to section detail
            selectedSection = section
        }
    }

    private func startPulseAnimation() {
        pulseAnimation = true
    }

    // MARK: - Section Detail View
    @ViewBuilder
    private func sectionDetailView(for section: SettingsSection) -> some View {
        switch section {
        case .account:
            SimpleAccountSettingsView()
                .environmentObject(authManager)
        case .privacy:
            PrivacySettingsView()
                .environmentObject(authManager)
        case .notifications:
            NotificationSettingsView()
                .environmentObject(authManager)
        case .appearance:
            AppearanceSettingsView()
                .environmentObject(authManager)
        case .support:
            SupportView()
        case .about:
            AboutView()
        #if DEBUG
        case .developer:
            DeveloperSettingsView()
        #endif
        }
    }
}

// MARK: - Settings Models
enum SettingsSection: CaseIterable, Identifiable {
    case account
    case privacy
    case notifications
    case appearance
    case support
    case about
    #if DEBUG
    case developer
    #endif

    var id: String { String(describing: self) }

    var index: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }
}

struct SettingsItem: Equatable {
    let icon: String
    let title: String
    let subtitle: String?
    let value: String?
    let toggle: Binding<Bool>?
    let color: Color
    let action: (() -> Void)?

    static func == (lhs: SettingsItem, rhs: SettingsItem) -> Bool {
        lhs.icon == rhs.icon &&
        lhs.title == rhs.title &&
        lhs.subtitle == rhs.subtitle &&
        lhs.value == rhs.value &&
        lhs.color == rhs.color
        // Note: Binding and closures cannot be compared
    }

    init(icon: String, title: String, subtitle: String? = nil, value: String? = nil, toggle: Binding<Bool>? = nil, color: Color, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.toggle = toggle
        self.color = color
        self.action = action
    }
}

// MARK: - Settings View Model
class SettingsViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var successMessage = ""

    func loadUserData() {
        // Load user data if needed
    }

    @MainActor
    func updateUsername(_ newUsername: String) async -> Bool {
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await APIClient.shared.changeUsername(newUsername: newUsername)

            if response.success {
                // Update local user data
                AuthManager.shared.updateCurrentUserUsername(newUsername)
                successMessage = "Username updated successfully!"
                return true
            } else {
                errorMessage = response.message ?? "Failed to update username"
                return false
            }
        } catch {
            // Extract the proper error message from BrrowAPIError
            if let apiError = error as? BrrowAPIError {
                switch apiError {
                case .validationError(let message):
                    errorMessage = message
                case .serverError(let message):
                    errorMessage = message
                case .unauthorized:
                    errorMessage = "Authentication error. Please log in again."
                case .networkError(let message):
                    errorMessage = message
                default:
                    errorMessage = error.localizedDescription
                }
            } else {
                errorMessage = error.localizedDescription
            }
            return false
        }
    }
}

// MARK: - Simple Account Settings View
struct SimpleAccountSettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var showingChangeUsername = false
    @State private var showingChangePassword = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            List {
                // Current Account Info
                Section("Account Information") {
                    HStack {
                        Text("Username")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("@\(authManager.currentUser?.username ?? "")")
                            .foregroundColor(Theme.Colors.text)
                    }

                    HStack {
                        Text("Email")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(authManager.currentUser?.email ?? "")
                            .foregroundColor(Theme.Colors.text)
                    }
                }

                // Actions
                Section("Account Actions") {
                    Button(action: { showingChangeUsername = true }) {
                        Label("Change Username", systemImage: "at")
                            .foregroundColor(Theme.Colors.primary)
                    }

                    if authManager.currentUser?.appleUserId == nil {
                        Button(action: { showingChangePassword = true }) {
                            Label("Change Password", systemImage: "lock.rotation")
                                .foregroundColor(Theme.Colors.primary)
                        }
                    }
                }

                // Danger Zone
                Section {
                    Button(action: {
                        authManager.logout()
                        dismiss()
                    }) {
                        Label("Sign Out", systemImage: "arrow.right.square")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingChangeUsername) {
                SimpleUsernameChangeView()
                    .environmentObject(authManager)
            }
            .sheet(isPresented: $showingChangePassword) {
                ChangePasswordView()
                    .environmentObject(authManager)
            }
        }
    }
}

// MARK: - Account Settings View (Deprecated)
struct AccountSettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var showingEditProfile = false
    @State private var showingChangeUsername = false
    @State private var showingChangePassword = false

    var body: some View {
        NavigationView {
            List {
                Section {
                    Button(action: { showingEditProfile = true }) {
                        Label("Edit Profile", systemImage: "person.circle")
                    }

                    Button(action: { showingChangeUsername = true }) {
                        Label("Change Username", systemImage: "at")
                    }

                    if authManager.currentUser?.appleUserId == nil {
                        Button(action: { showingChangePassword = true }) {
                            Label("Change Password", systemImage: "lock.rotation")
                        }
                    }
                }
            }
            .navigationTitle("Account Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingEditProfile) {
                if let currentUser = authManager.currentUser {
                    EditProfileView(user: currentUser)
                        .environmentObject(authManager)
                }
            }
            .sheet(isPresented: $showingChangeUsername) {
                ModernUsernameChangeView()
                    .environmentObject(authManager)
            }
            .sheet(isPresented: $showingChangePassword) {
                ChangePasswordView()
                    .environmentObject(authManager)
            }
        }
    }
}

// MARK: - Support View
struct SupportView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text("Help Center")
                            Text("Browse FAQs and guides")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(.green)
                        VStack(alignment: .leading) {
                            Text("Contact Support")
                            Text("support@brrow.com")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading) {
                            Text("Report a Problem")
                            Text("Let us know about issues")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Support")
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

// MARK: - Simple Username Change View
struct SimpleUsernameChangeView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var newUsername = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var successMessage = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Current Username") {
                    Text("@\(authManager.currentUser?.username ?? "")")
                        .foregroundColor(.secondary)
                }

                Section("New Username") {
                    TextField("Enter new username", text: $newUsername)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }

                if !successMessage.isEmpty {
                    Section {
                        Text(successMessage)
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }

                Section {
                    Button(action: changeUsername) {
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Change Username")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(newUsername.isEmpty || isLoading)
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(newUsername.isEmpty ? Color.gray : Theme.Colors.primary)
                    )
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
            }
        }
    }

    private func changeUsername() {
        guard !newUsername.isEmpty else { return }

        isLoading = true
        errorMessage = ""
        successMessage = ""

        Task {
            do {
                // Use the function that properly handles the 90-day policy error
                let updatedUser = try await APIClient.shared.changeUsername(newUsername)

                await MainActor.run {
                    // Update local user data with the returned user
                    authManager.updateUser(updatedUser)
                    successMessage = "Username changed successfully!"

                    // Dismiss after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    // Extract the proper error message
                    if let apiError = error as? BrrowAPIError {
                        switch apiError {
                        case .validationError(let message):
                            errorMessage = message
                        case .serverError(let message):
                            errorMessage = message
                        default:
                            errorMessage = error.localizedDescription
                        }
                    } else {
                        errorMessage = error.localizedDescription
                    }
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Modern Username Change View (Deprecated)
struct ModernUsernameChangeView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = SettingsViewModel()
    @State private var newUsername = ""
    @State private var isChecking = false
    @State private var isAvailable = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Theme.Colors.primary.opacity(0.05), Color.clear]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 30) {
                    // Current Username Display
                    VStack(spacing: 10) {
                        Text("Current Username")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.Colors.secondaryText)

                        Text("@\(authManager.currentUser?.username ?? "")")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.Colors.primary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Theme.Colors.primary.opacity(0.1))
                    )

                    // New Username Input
                    VStack(alignment: .leading, spacing: 10) {
                        Text("New Username")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Theme.Colors.text)

                        HStack {
                            Text("@")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(Theme.Colors.secondaryText)

                            TextField("username", text: $newUsername)
                                .font(.system(size: 18, weight: .medium))
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .onChange(of: newUsername) { _ in
                                    checkAvailability()
                                }

                            if isChecking {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else if !newUsername.isEmpty {
                                Image(systemName: isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(isAvailable ? .green : .red)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(
                                    newUsername.isEmpty ? Color.gray.opacity(0.3) :
                                    isAvailable ? Color.green : Color.red,
                                    lineWidth: 2
                                )
                        )

                        if !newUsername.isEmpty && !isAvailable {
                            Text("This username is already taken")
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                        }
                    }

                    // Info Box
                    HStack(spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.orange)

                        Text("You can only change your username once every 90 days")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.orange.opacity(0.1))
                    )

                    Spacer()

                    // Save Button
                    Button(action: saveUsername) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Save Username")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Theme.Colors.primary, Theme.Colors.primary.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .disabled(!isAvailable || viewModel.isLoading || newUsername.isEmpty)
                        .opacity((!isAvailable || newUsername.isEmpty) ? 0.5 : 1.0)
                    }
                }
                .padding()
            }
            .navigationTitle("Change Username")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Success!", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your username has been updated to @\(newUsername)")
            }
            .alert("Unable to Change Username", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func checkAvailability() {
        guard !newUsername.isEmpty else { return }

        isChecking = true

        // Simulate API check
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isAvailable = !["admin", "user", "test", "brrow"].contains(newUsername.lowercased())
            isChecking = false
        }
    }

    private func saveUsername() {
        Task {
            let success = await viewModel.updateUsername(newUsername)
            if success {
                await MainActor.run {
                    showSuccess = true
                }
            } else {
                // Show error message in an alert
                await MainActor.run {
                    errorMessage = viewModel.errorMessage
                    showError = true
                }
            }
        }
    }
}

// MARK: - Preview
struct ModernSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ModernSettingsView()
            .environmentObject(AuthManager.shared)
    }
}