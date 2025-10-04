//
//  EditProfileView.swift
//  Brrow
//
//  Production-ready profile editing with all features
//

import SwiftUI
import PhotosUI

// MARK: - Profile Update Data Model
struct ProfileUpdateData: Codable {
    let username: String
    let displayName: String?
    let email: String
    let phone: String?
    let bio: String?
    let birthdate: String?
    let profilePicture: String?
    let location: String?
    let website: String?

    enum CodingKeys: String, CodingKey {
        case username, displayName, email, phone, bio
        case birthdate, profilePicture, location, website
    }
}

struct EditProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authManager: AuthManager
    let user: User
    
    // Profile Fields
    @State private var username: String
    @State private var displayName: String
    @State private var bio: String
    @State private var email: String
    @State private var phone: String
    @State private var location: String
    @State private var website: String
    @State private var birthdate: Date = Date()
    
    // Profile Image
    @State private var selectedImage: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var showingImagePicker = false
    @State private var currentProfilePictureUrl: String? // Track the most recent profile picture URL
    
    // Navigation states
    @State private var showChangePassword = false
    @State private var showPrivacySettings = false
    @State private var showNotificationSettings = false
    @State private var showLanguageSettings = false
    @State private var showDeleteAccount = false
    @State private var showBusinessAccount = false
    // Username change alert removed - username changes now handled in Settings

    // SMS Verification states
    @State private var showSMSVerification = false
    @State private var pendingPhoneNumber = ""

    // Loading states
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
    // Validation
    @State private var hasChanges = false
    
    init(user: User) {
        self.user = user
        self._username = State(initialValue: user.username)
        self._displayName = State(initialValue: user.displayName ?? user.username)
        self._bio = State(initialValue: user.bio ?? "")
        self._email = State(initialValue: user.email)
        self._phone = State(initialValue: user.phone ?? "")
        self._location = State(initialValue: user.location ?? "")
        self._website = State(initialValue: user.website ?? "")
        self._currentProfilePictureUrl = State(initialValue: user.profilePicture) // Initialize with current profile picture

        // Parse birthdate if available
        if let birthdateString = user.birthdate {
            let formatter = ISO8601DateFormatter()
            self._birthdate = State(initialValue: formatter.date(from: birthdateString) ?? Date())
        }
    }

    // Username change cooldown logic removed - username changes now handled in Settings

    var body: some View {
        mainContent
            .photosPicker(isPresented: $showingImagePicker, selection: $selectedImage, matching: .images)
            .toolbarBackground(Color.white, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        .onChange(of: selectedImage) { newItem in
            handleImageSelection(newItem)
        }
        // Username onChange removed - username is no longer editable in this view
        .onChange(of: displayName) { _ in hasChanges = true }
        .onChange(of: bio) { _ in hasChanges = true }
        .onChange(of: email) { _ in hasChanges = true }
        .onChange(of: phone) { _ in hasChanges = true }
        .onChange(of: location) { _ in hasChanges = true }
        .onChange(of: website) { _ in hasChanges = true }
        .onChange(of: birthdate) { _ in hasChanges = true }
        .alert(getAlertTitle(for: errorMessage), isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        // Username change alert removed - username changes now handled in Settings
        .sheet(isPresented: $showChangePassword) {
            ChangePasswordView()
        }
        .sheet(isPresented: $showPrivacySettings) {
            PrivacySettingsView()
        }
        .sheet(isPresented: $showNotificationSettings) {
            NotificationSettingsView()
        }
        .sheet(isPresented: $showLanguageSettings) {
            ProfileLanguageSettingsView()
        }
        .sheet(isPresented: $showBusinessAccount) {
            BusinessAccountCreationView(showingAccountTypeSelection: .constant(false))
        }
        .sheet(isPresented: $showDeleteAccount) {
            DeleteAccountView()
        }
        .sheet(isPresented: $showSMSVerification) {
            SMSVerificationView(initialPhoneNumber: pendingPhoneNumber) { user in
                // Verification complete - update local state
                Task {
                    await authManager.refreshUserProfile()
                    await MainActor.run {
                        phone = pendingPhoneNumber
                        showSuccess = true
                        showSMSVerification = false
                    }
                }
            }
        }
    }

    // MARK: - Main Content
    private var mainContent: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    profileContent
                }
            }
            .background(Theme.Colors.background)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                toolbarContent
            }
            .toolbarColorScheme(.light, for: .navigationBar)
            .onTapGesture {
                // Dismiss keyboard when tapping outside
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .disabled(isLoading)

            // Loading overlay
            if isLoading {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .overlay(
                        VStack(spacing: Theme.Spacing.md) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)

                            Text("Saving profile...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(Theme.Spacing.xl)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(16)
                    )
            }
        }
    }
    
    // MARK: - Profile Content
    private var profileContent: some View {
        VStack(spacing: 0) {
            // Profile Picture Section
            profilePictureSection
                .padding(.top, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.xl)
            
            // Personal Information Section
            sectionHeader("Personal Information")
            personalInfoFields
                .padding(.bottom, Theme.Spacing.xl)
            
            // About Section
            sectionHeader("About")
            aboutFields
                .padding(.bottom, Theme.Spacing.xl)
            
            // Account Settings Section - Full Width
            accountSettingsSection
                .padding(.bottom, 100) // Bottom padding for tab bar
        }
    }
    
    
    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }
            .foregroundColor(Theme.Colors.primary)
            .disabled(isLoading)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Save") {
                saveProfile()
            }
            .fontWeight(.semibold)
            .foregroundColor(hasChanges ? Theme.Colors.primary : Theme.Colors.secondaryText)
            .disabled(isLoading || !hasChanges)
        }
    }
    
    // MARK: - Profile Picture Section
    private var profilePictureSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            ZStack {
                if let profileImage = profileImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } else {
                    BrrowAsyncImage(url: user.profilePicture ?? "") { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Theme.Colors.primary.opacity(0.1))
                            .overlay(
                                Text(String(user.username.prefix(1)).uppercased())
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(Theme.Colors.primary)
                            )
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                }
                
                // Camera overlay
                Circle()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "camera.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    )
                    .offset(x: 40, y: 40)
            }
            .onTapGesture {
                showingImagePicker = true
            }
            
            Text("Change Photo")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Theme.Colors.primary)
                .onTapGesture {
                    showingImagePicker = true
                }
        }
    }
    
    // MARK: - Section Headers
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(Theme.Colors.text)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.md)
    }
    
    // MARK: - Personal Information Fields
    private var personalInfoFields: some View {
        VStack(spacing: Theme.Spacing.md) {
            displayNameField
            usernameField
            emailField
            phoneField
            birthdateField
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }
    
    private var usernameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Username")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.Colors.text)

            // Non-editable username display
            HStack {
                Text("@\(username)")
                    .foregroundColor(Theme.Colors.secondaryText)

                Spacer()

                Text("Not editable")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            .padding(Theme.Spacing.md)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.Colors.border.opacity(0.5), lineWidth: 1)
            )

            Text("Change your username in Settings")
                .font(.caption)
                .foregroundColor(Theme.Colors.primary)
                .padding(.horizontal, Theme.Spacing.md)
        }
    }
    
    private var displayNameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Display Name")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.Colors.text)

            TextField("Enter display name", text: $displayName)
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.surface)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.Colors.border, lineWidth: 1)
                )

            Text("This is how your name will appear to others")
                .font(.caption)
                .foregroundColor(Theme.Colors.secondaryText)
                .padding(.horizontal, Theme.Spacing.md)
        }
    }

    private var emailField: some View {
        formField(title: "Email", text: $email, placeholder: "Enter email", keyboardType: .emailAddress)
    }
    
    private var phoneField: some View {
        formField(title: "Phone", text: $phone, placeholder: "Enter phone number", keyboardType: .phonePad)
    }
    
    private var birthdateField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Birthday")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.Colors.text)
            
            DatePicker("", selection: $birthdate, displayedComponents: .date)
                .labelsHidden()
                .datePickerStyle(CompactDatePickerStyle())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.surface)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.Colors.border, lineWidth: 1)
                )
        }
    }
    
    // MARK: - About Fields
    private var aboutFields: some View {
        VStack(spacing: Theme.Spacing.md) {
            bioField
            locationField
            websiteField
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }
    
    private var bioField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bio")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.Colors.text)
            
            bioTextEditor
            
            Text("\(bio.count)/250")
                .font(.caption)
                .foregroundColor(bio.count > 250 ? .red : Theme.Colors.secondaryText)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .onChange(of: bio) { newValue in
            if newValue.count > 250 {
                bio = String(newValue.prefix(250))
            }
        }
    }
    
    private var bioTextEditor: some View {
        ZStack(alignment: .topLeading) {
            if bio.isEmpty {
                Text("Tell us about yourself...")
                    .foregroundColor(Theme.Colors.secondaryText)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.top, Theme.Spacing.md + 8)
            }

            TextEditor(text: $bio)
                .frame(minHeight: 100)
                .padding(Theme.Spacing.md)
                .background(Color.clear)
                .scrollContentBackground(.hidden)
        }
        .background(Theme.Colors.surface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
        .onTapGesture {
            // Allow TextEditor to gain focus
        }
    }
    
    private var locationField: some View {
        formField(title: "Location", text: $location, placeholder: "City, State")
    }
    
    private var websiteField: some View {
        formField(title: "Website", text: $website, placeholder: "https://yourwebsite.com", keyboardType: .URL)
    }
    
    // MARK: - Account Settings Section
    private var accountSettingsSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            sectionHeader("Account Settings")
            accountSettingsContent
        }
    }
    
    private var accountSettingsContent: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Security Section
            VStack(spacing: 0) {
                settingsRowModern(
                    title: "Change Password",
                    subtitle: "Update your account password",
                    icon: "lock.fill",
                    iconColor: Theme.Colors.primary,
                    showDivider: false
                ) {
                    showChangePassword = true
                }
            }
            .background(Theme.Colors.surface)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Theme.Colors.border.opacity(0.1), lineWidth: 1)
            )
            
            // Privacy & Notifications
            VStack(spacing: 0) {
                settingsRowModern(
                    title: "Privacy Settings",
                    subtitle: "Control who can see your profile",
                    icon: "eye.slash.fill",
                    iconColor: Color.blue,
                    showDivider: true
                ) {
                    showPrivacySettings = true
                }
                
                settingsRowModern(
                    title: "Notifications",
                    subtitle: "Manage push and email alerts",
                    icon: "bell.fill",
                    iconColor: Color.orange,
                    showDivider: false
                ) {
                    showNotificationSettings = true
                }
            }
            .background(Theme.Colors.surface)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Theme.Colors.border.opacity(0.1), lineWidth: 1)
            )
            
            // Preferences
            VStack(spacing: 0) {
                settingsRowModern(
                    title: "Language",
                    subtitle: LocalizationManager.shared.currentLanguageName,
                    icon: "globe",
                    iconColor: Color.green,
                    showDivider: user.accountType != "business"
                ) {
                    showLanguageSettings = true
                }
                
                if user.accountType != "business" {
                    settingsRowModern(
                        title: "Business Account",
                        subtitle: "List items as a business",
                        icon: "building.2.fill",
                        iconColor: Color.purple,
                        showDivider: false
                    ) {
                        showBusinessAccount = true
                    }
                }
            }
            .background(Theme.Colors.surface)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Theme.Colors.border.opacity(0.1), lineWidth: 1)
            )
            
            // Danger Zone
            VStack(spacing: 0) {
                settingsRowModern(
                    title: "Delete Account",
                    subtitle: "Permanently delete your account",
                    icon: "trash.fill",
                    iconColor: Color.red,
                    showDivider: false,
                    isDestructive: true
                ) {
                    showDeleteAccount = true
                }
            }
            .background(Color.red.opacity(0.05))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.red.opacity(0.2), lineWidth: 1)
            )
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }
    
    private var passwordSettingRow: some View {
        settingsRow(
            title: "Change Password",
            subtitle: "Update your account password",
            systemImage: "lock.fill",
            showDivider: true
        ) {
            showChangePassword = true
        }
    }
    
    private var privacySettingRow: some View {
        settingsRow(
            title: "Privacy Settings",
            subtitle: "Control who can see your profile",
            systemImage: "eye.slash.fill",
            showDivider: true
        ) {
            showPrivacySettings = true
        }
    }
    
    private var notificationSettingRow: some View {
        settingsRow(
            title: "Notification Preferences",
            subtitle: "Manage push and email notifications",
            systemImage: "bell.fill",
            showDivider: true
        ) {
            showNotificationSettings = true
        }
    }
    
    private var languageSettingRow: some View {
        settingsRow(
            title: "Language",
            subtitle: LocalizationManager.shared.currentLanguageName,
            systemImage: "globe",
            showDivider: true
        ) {
            showLanguageSettings = true
        }
    }
    
    @ViewBuilder
    private var businessAccountRow: some View {
        if user.accountType != "business" {
            settingsRow(
                title: "Create Business Account",
                subtitle: "List items as a business",
                systemImage: "building.2.fill",
                showDivider: true
            ) {
                showBusinessAccount = true
            }
        }
    }
    
    private var deleteAccountRow: some View {
        settingsRow(
            title: "Delete Account",
            subtitle: "Permanently delete your account",
            systemImage: "trash.fill",
            showDivider: false,
            isDestructive: true
        ) {
            showDeleteAccount = true
        }
    }
    
    // MARK: - Helper Views
    private func formField(
        title: String,
        text: Binding<String>,
        placeholder: String,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.Colors.text)
            
            TextField(placeholder, text: text)
                .keyboardType(keyboardType)
                .autocapitalization(keyboardType == .emailAddress || keyboardType == .URL ? .none : .sentences)
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.surface)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.Colors.border, lineWidth: 1)
                )
        }
    }
    
    private func settingsRowModern(
        title: String,
        subtitle: String,
        icon: String,
        iconColor: Color,
        showDivider: Bool,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                // Icon with background
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isDestructive ? .red : iconColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isDestructive ? .red : Theme.Colors.text)
                    
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(Theme.Colors.secondaryText)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.secondaryText.opacity(0.5))
            }
            .padding(.vertical, Theme.Spacing.md)
            .padding(.horizontal, Theme.Spacing.md)
            .background(Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
        .overlay(
            Group {
                if showDivider {
                    VStack {
                        Spacer()
                        Divider()
                            .background(Theme.Colors.border.opacity(0.1))
                    }
                    .padding(.leading, 68)
                }
            }
        )
    }
    
    private func settingsRow(
        title: String,
        subtitle: String,
        systemImage: String,
        showDivider: Bool,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 0) {
            Button(action: action) {
                HStack(spacing: Theme.Spacing.md) {
                    Image(systemName: systemImage)
                        .font(.system(size: 20))
                        .foregroundColor(isDestructive ? .red : Theme.Colors.primary)
                        .frame(width: 28)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isDestructive ? .red : Theme.Colors.text)
                        
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                .padding(Theme.Spacing.lg)
            }
            
            if showDivider {
                Divider()
                    .padding(.leading, 60)
            }
        }
    }
    
    // MARK: - Actions
    private func handleImageSelection(_ item: PhotosPickerItem?) {
        Task {
            if let item = item,
               let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                profileImage = image
                hasChanges = true
            }
        }
    }
    
    private func saveProfile() {
        guard hasChanges else {
            // No changes, dismiss immediately
            presentationMode.wrappedValue.dismiss()
            return
        }

        // Username change logic removed - username changes now handled in Settings

        // Check if phone number is being changed
        let phoneChanged = phone != (user.phone ?? "") && !phone.isEmpty
        if phoneChanged {
            // Trigger SMS verification flow
            pendingPhoneNumber = phone
            sendSMSVerificationCode()
            return
        }

        // FIXED: Wait for save to complete before dismissing
        performSave()
    }

    private func performSave() {
        isLoading = true

        Task {
            do {
                // Upload image if changed with NSFW moderation
                var imageUrl: String? = nil
                if let profileImage = profileImage {
                    // Skip NSFW check for profile pictures - it's too aggressive
                    // Profile pictures are reviewed differently than listing images
                    let imageData = profileImage.jpegData(compressionQuality: 0.8) ?? Data()
                    let fileName = "profile_\(UUID().uuidString).jpg"
                    let uploadResponse = try await APIClient.shared.uploadProfilePicture(imageData, fileName: fileName)
                    imageUrl = uploadResponse.data?.url

                    // CRITICAL: Update our tracked profile picture URL immediately
                    if let newUrl = imageUrl {
                        currentProfilePictureUrl = newUrl
                        print("✅ Updated currentProfilePictureUrl to: \(newUrl)")
                    }
                }

                // Username change logic removed - username changes now handled in Settings

                // Prepare update data - CRITICAL: Use currentProfilePictureUrl to preserve the latest profile picture
                let updateData = ProfileUpdateData(
                    username: username, // Keep current username (readonly)
                    displayName: displayName.isEmpty ? nil : displayName,
                    email: email,
                    phone: phone.isEmpty ? nil : phone,
                    bio: bio.isEmpty ? nil : bio,
                    birthdate: ISO8601DateFormatter().string(from: birthdate),
                    profilePicture: currentProfilePictureUrl, // Use tracked URL, not user.profilePicture
                    location: location.isEmpty ? nil : location,
                    website: website.isEmpty ? nil : website
                )

                print("🔄 Saving profile with profilePicture: \(currentProfilePictureUrl ?? "nil")")

                // Update profile via API
                try await APIClient.shared.updateProfile(data: updateData)

                // Handle profile image separately if changed
                if let imageUrl = imageUrl {
                    _ = try await APIClient.shared.updateProfileImage(imageUrl: imageUrl)
                }

                // Refresh auth manager with new data
                await authManager.refreshUserProfile()

                await MainActor.run {
                    isLoading = false

                    // CRITICAL FIX: Notify other views to refresh user data
                    // This ensures conversations, messages, and other views show updated username/profile picture
                    NotificationCenter.default.post(name: .userDidUpdate, object: nil)

                    // FIXED: Dismiss only after successful save
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }

            } catch {
                await MainActor.run {
                    isLoading = false

                    // Since panel is dismissed, show system-level alert
                    var alertMessage = "Failed to update profile. Please check your network connection and try again."

                    if let apiError = error as? BrrowAPIError {
                        switch apiError {
                        case .validationError(let message):
                            alertMessage = message
                        case .serverError(let message):
                            alertMessage = message.isEmpty ? "Server error occurred" : message
                        case .unauthorized:
                            alertMessage = "Authentication error. Please log in again."
                        case .networkError(let message):
                            alertMessage = message.isEmpty ? "Network error. Please check your connection." : message
                        case .addressConflict(let message):
                            alertMessage = message
                        default:
                            alertMessage = "Failed to update profile. Please try again."
                        }
                    }

                    // CRITICAL FIX: Show error to user with alert
                    print("❌ Profile update error: \(alertMessage)")
                    errorMessage = alertMessage
                    showError = true
                }
            }
        }
    }

    // Helper function to determine appropriate alert title
    private func getAlertTitle(for message: String) -> String {
        if message.contains("90 days") || message.contains("once every") {
            return "Unable to Change Username"
        } else if message.contains("Authentication") || message.contains("log in") {
            return "Authentication Required"
        } else if message.contains("Network") || message.contains("connection") {
            return "Connection Issue"
        } else if message.contains("not found") || message.contains("404") {
            return "Feature Unavailable"
        } else {
            return "Notice"
        }
    }

    // MARK: - SMS Verification Methods
    private func sendSMSVerificationCode() {
        // Just show the SMS verification sheet - it handles the rest
        showSMSVerification = true
    }
}

// MARK: - Supporting Views

struct ChangePasswordProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    VStack(spacing: Theme.Spacing.lg) {
                        SecureField("Current Password", text: $currentPassword)
                            .padding(Theme.Spacing.md)
                            .background(Theme.Colors.surface)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Theme.Colors.border, lineWidth: 1)
                            )
                        
                        SecureField("New Password", text: $newPassword)
                            .padding(Theme.Spacing.md)
                            .background(Theme.Colors.surface)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Theme.Colors.border, lineWidth: 1)
                            )
                        
                        SecureField("Confirm New Password", text: $confirmPassword)
                            .padding(Theme.Spacing.md)
                            .background(Theme.Colors.surface)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Theme.Colors.border, lineWidth: 1)
                            )
                        
                        Text("Password must be at least 8 characters long")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Button(action: updatePassword) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Update Password")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.primary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(isLoading || currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty)
                    
                    Spacer()
                }
                .padding(Theme.Spacing.lg)
            }
            .background(Theme.Colors.background)
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(Theme.Colors.primary)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK") {
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("Your password has been updated successfully!")
            }
        }
    }
    
    private func updatePassword() {
        guard newPassword == confirmPassword else {
            errorMessage = "New passwords don't match"
            showError = true
            return
        }
        
        guard newPassword.count >= 8 else {
            errorMessage = "Password must be at least 8 characters long"
            showError = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                _ = try await APIClient.shared.changePassword(
                    currentPassword: currentPassword,
                    newPassword: newPassword
                )
                
                await MainActor.run {
                    isLoading = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

struct LegacyPrivacySettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var profileVisibility = "public"
    @State private var showEmail = false
    @State private var showPhone = false
    @State private var showLocation = true
    @State private var allowMessages = true
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    // Profile Visibility
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        Text("Profile Visibility")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.Colors.text)
                        
                        VStack(spacing: 0) {
                            ProfileRadioButton(title: "Public", subtitle: "Anyone can view your profile", isSelected: profileVisibility == "public") {
                                profileVisibility = "public"
                            }
                            Divider().padding(.leading, 50)
                            ProfileRadioButton(title: "Friends Only", subtitle: "Only friends can view your profile", isSelected: profileVisibility == "friends") {
                                profileVisibility = "friends"
                            }
                            Divider().padding(.leading, 50)
                            ProfileRadioButton(title: "Private", subtitle: "No one can view your profile", isSelected: profileVisibility == "private") {
                                profileVisibility = "private"
                            }
                        }
                        .background(Theme.Colors.surface)
                        .cornerRadius(12)
                    }
                    
                    // Information Visibility
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        Text("Information Visibility")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.Colors.text)
                        
                        VStack(spacing: 0) {
                            ToggleRow(title: "Show Email", isOn: $showEmail)
                            Divider().padding(.leading, 50)
                            ToggleRow(title: "Show Phone Number", isOn: $showPhone)
                            Divider().padding(.leading, 50)
                            ToggleRow(title: "Show Location", isOn: $showLocation)
                        }
                        .background(Theme.Colors.surface)
                        .cornerRadius(12)
                    }
                    
                    // Communication
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        Text("Communication")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.Colors.text)
                        
                        VStack(spacing: 0) {
                            ToggleRow(title: "Allow Messages", isOn: $allowMessages)
                        }
                        .background(Theme.Colors.surface)
                        .cornerRadius(12)
                    }
                    
                    Spacer()
                }
                .padding(Theme.Spacing.lg)
            }
            .background(Theme.Colors.background)
            .navigationTitle("Privacy Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(Theme.Colors.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePrivacySettings()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.primary)
                }
            }
        }
    }
    
    private func savePrivacySettings() {
        // Save privacy settings via API
        presentationMode.wrappedValue.dismiss()
    }
}

struct NotificationSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var pushNotifications = true
    @State private var emailNotifications = true
    @State private var newMessages = true
    @State private var newOffers = true
    @State private var promotions = false
    @State private var updates = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    // General
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        Text("General")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.Colors.text)
                        
                        VStack(spacing: 0) {
                            ToggleRow(title: "Push Notifications", isOn: $pushNotifications)
                            Divider().padding(.leading, 50)
                            ToggleRow(title: "Email Notifications", isOn: $emailNotifications)
                        }
                        .background(Theme.Colors.surface)
                        .cornerRadius(12)
                    }
                    
                    // Activity
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        Text("Activity")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.Colors.text)
                        
                        VStack(spacing: 0) {
                            ToggleRow(title: "New Messages", isOn: $newMessages)
                            Divider().padding(.leading, 50)
                            ToggleRow(title: "New Offers", isOn: $newOffers)
                            Divider().padding(.leading, 50)
                            ToggleRow(title: "Promotions & Deals", isOn: $promotions)
                            Divider().padding(.leading, 50)
                            ToggleRow(title: "App Updates", isOn: $updates)
                        }
                        .background(Theme.Colors.surface)
                        .cornerRadius(12)
                    }
                    
                    Spacer()
                }
                .padding(Theme.Spacing.lg)
            }
            .background(Theme.Colors.background)
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(Theme.Colors.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveNotificationSettings()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.primary)
                }
            }
        }
    }
    
    private func saveNotificationSettings() {
        // Save notification settings via API
        presentationMode.wrappedValue.dismiss()
    }
}

struct DeleteAccountView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authManager: AuthManager
    @State private var password = ""
    @State private var confirmText = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    // Warning
                    VStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                        
                        Text("Delete Account")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Theme.Colors.text)
                        
                        Text("This action cannot be undone. All your data will be permanently deleted.")
                            .font(.system(size: 15))
                            .foregroundColor(Theme.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(Theme.Spacing.xl)
                    
                    VStack(spacing: Theme.Spacing.lg) {
                        SecureField("Enter your password", text: $password)
                            .padding(Theme.Spacing.md)
                            .background(Theme.Colors.surface)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Theme.Colors.border, lineWidth: 1)
                            )
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Type \"DELETE\" to confirm")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Theme.Colors.text)
                            
                            TextField("", text: $confirmText)
                                .padding(Theme.Spacing.md)
                                .background(Theme.Colors.surface)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Theme.Colors.border, lineWidth: 1)
                                )
                        }
                    }
                    
                    Button(action: deleteAccount) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Delete Account")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(Theme.Spacing.md)
                    .background(confirmText == "DELETE" && !password.isEmpty ? Color.red : Color.red.opacity(0.5))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(isLoading || confirmText != "DELETE" || password.isEmpty)
                    
                    Spacer()
                }
                .padding(Theme.Spacing.lg)
            }
            .background(Theme.Colors.background)
            .navigationTitle("Delete Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(Theme.Colors.primary)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func deleteAccount() {
        isLoading = true
        
        Task {
            do {
                try await APIClient.shared.deleteAccount(password: password)
                
                await MainActor.run {
                    authManager.logout()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Helper Views

struct ProfileRadioButton: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? Theme.Colors.primary : Theme.Colors.secondaryText)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.Colors.text)
                    
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                
                Spacer()
            }
            .padding(Theme.Spacing.md)
        }
    }
}

struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(Theme.Colors.text)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Theme.Colors.primary)
        }
        .padding(Theme.Spacing.md)
    }
}

struct ProfileLanguageSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var localizationManager = LocalizationManager.shared

    var body: some View {
        NavigationView {
            List(localizationManager.availableLanguages, id: \.self) { languageCode in
                HStack {
                    Text(localizationManager.languageName(for: languageCode))
                        .font(.system(size: 16))
                        .foregroundColor(Theme.Colors.text)

                    Spacer()

                    if languageCode == localizationManager.currentLanguage.code {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Theme.Colors.primary)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    localizationManager.setLanguage(languageCode)
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Language")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(Theme.Colors.primary)
                }
            }
        }
    }
}

