//
//  EnhancedEditProfileView.swift
//  Brrow
//
//  Enhanced profile editing with username change rules
//

import SwiftUI
import PhotosUI
import Combine

struct EnhancedEditProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = EditProfileViewModel()
    
    // Profile Fields
    @State private var username: String = ""
    @State private var displayName: String = ""
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var bio: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var location: String = ""
    @State private var website: String = ""
    @State private var birthdate = Date()
    
    // Username validation
    @State private var isCheckingUsername = false
    @State private var usernameAvailable = true
    @State private var usernameMessage = ""
    @State private var canChangeUsername = true
    @State private var daysUntilUsernameChange = 0
    @State private var showUsernameWarning = false
    
    // Profile Image
    @State private var selectedImage: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var showingImagePicker = false
    
    // Loading states
    @State private var isLoading = false
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false

    // SMS Verification
    @State private var showingSMSVerification = false

    // Debounce timer for username checking
    @State private var usernameCheckTimer: Timer?
    
    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Navigation Bar
                customNavigationBar
                
                // Main Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Picture Section
                        profilePictureSection
                        
                        // Username Section with validation
                        usernameSection
                        
                        // Display Name Section
                        displayNameSection
                        
                        // Personal Information
                        personalInfoSection
                        
                        // Bio Section
                        bioSection
                        
                        // Contact Information
                        contactInfoSection
                        
                        // Save Button
                        saveButton
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            loadUserData()
        }
        .photosPicker(isPresented: $showingImagePicker, selection: $selectedImage, matching: .images)
        .onChange(of: selectedImage) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    profileImage = UIImage(data: data)
                }
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
            Text("Your profile has been updated successfully!")
        }
        .alert("Username Change Warning", isPresented: $showUsernameWarning) {
            Button("Cancel", role: .cancel) {
                // Reset username to original
                username = authManager.currentUser?.username ?? ""
            }
            Button("Continue") {
                // User confirmed the change
            }
        } message: {
            Text("You can only change your username once every 90 days. Your current username will be reserved for you for 90 days. Are you sure you want to change it?")
        }
        .sheet(isPresented: $showingSMSVerification) {
            SMSVerificationView(initialPhoneNumber: phone) { updatedUser in
                // Update the local state when verification completes
                loadUserData()
            }
        }
    }
    
    // MARK: - Custom Navigation Bar
    private var customNavigationBar: some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Theme.Colors.text)
                    .frame(width: 36, height: 36)
                    .background(Theme.Colors.secondaryBackground)
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Text("Edit Profile")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Theme.Colors.text)
            
            Spacer()
            
            // Balance the layout
            Color.clear
                .frame(width: 36, height: 36)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Theme.Colors.cardBackground)
        .shadow(color: .black.opacity(0.05), radius: 2, y: 2)
    }
    
    // MARK: - Profile Picture Section
    private var profilePictureSection: some View {
        VStack(spacing: 12) {
            ZStack {
                if let image = profileImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } else {
                    AsyncImage(url: URL(string: authManager.currentUser?.profilePicture ?? "")) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                            )
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                }
                
                // Camera button overlay
                Button(action: { showingImagePicker = true }) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
                .offset(x: 40, y: 40)
            }
            
            Button("Change Photo") {
                showingImagePicker = true
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.blue)
        }
    }
    
    // MARK: - Username Section
    private var usernameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Username")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                if !canChangeUsername {
                    Text("(Can change in \(daysUntilUsernameChange) days)")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                }
            }
            
            HStack {
                TextField("Username", text: $username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .disabled(!canChangeUsername)
                    .onChange(of: username) { _, newValue in
                        // Debounce username checking
                        usernameCheckTimer?.invalidate()
                        if newValue != authManager.currentUser?.username {
                            isCheckingUsername = true
                            usernameCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                                checkUsernameAvailability(newValue)
                            }
                        } else {
                            usernameMessage = "Current username"
                            usernameAvailable = true
                        }
                    }
                
                if isCheckingUsername {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if !usernameMessage.isEmpty {
                    Image(systemName: usernameAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(usernameAvailable ? .green : .red)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .opacity(canChangeUsername ? 1.0 : 0.6)
            
            if !usernameMessage.isEmpty {
                Text(usernameMessage)
                    .font(.caption)
                    .foregroundColor(usernameAvailable ? .green : .red)
            }
            
            Text("Lowercase letters, numbers, and underscores only (3-20 characters)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Display Name Section
    private var displayNameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Display Name")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            TextField("How your name appears", text: $displayName)
                .textInputAutocapitalization(.words)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            
            Text("This is how your name will appear to others")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Personal Information Section
    private var personalInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Personal Information")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("First Name")
                        .font(.system(size: 14, weight: .medium))
                    TextField("First", text: $firstName)
                        .textInputAutocapitalization(.words)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Last Name")
                        .font(.system(size: 14, weight: .medium))
                    TextField("Last", text: $lastName)
                        .textInputAutocapitalization(.words)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Birthday")
                    .font(.system(size: 14, weight: .medium))
                DatePicker("", selection: $birthdate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
        }
    }
    
    // MARK: - Bio Section
    private var bioSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Bio")
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                Text("\(bio.count)/250")
                    .font(.caption)
                    .foregroundColor(bio.count > 250 ? .red : .secondary)
            }
            
            TextEditor(text: $bio)
                .frame(minHeight: 100)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .onChange(of: bio) { _, newValue in
                    if newValue.count > 250 {
                        bio = String(newValue.prefix(250))
                    }
                }
        }
    }
    
    // MARK: - Contact Information Section
    private var contactInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Contact Information")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.system(size: 14, weight: .medium))
                TextField("email@example.com", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .disabled(true) // Email usually can't be changed directly
                    .opacity(0.6)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Phone")
                        .font(.system(size: 14, weight: .medium))

                    Spacer()

                    if let user = authManager.currentUser,
                       let userPhone = user.phone, !userPhone.isEmpty,
                       user.phoneVerified == true {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 12))
                            Text("Verified")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    } else if let user = authManager.currentUser,
                              let userPhone = user.phone, !userPhone.isEmpty {
                        Button("Verify") {
                            showingSMSVerification = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }

                HStack {
                    TextField("Phone number", text: $phone)
                        .keyboardType(.phonePad)
                        .disabled(authManager.currentUser?.phoneVerified == true)
                        .opacity(authManager.currentUser?.phoneVerified == true ? 0.7 : 1.0)

                    if authManager.currentUser?.phoneVerified != true && !phone.isEmpty {
                        Button("Verify") {
                            showingSMSVerification = true
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)

                if authManager.currentUser?.phoneVerified == true {
                    Text("Phone number is verified and secured")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("Verify your phone number for security and account recovery")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Location")
                    .font(.system(size: 14, weight: .medium))
                TextField("City, State", text: $location)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Website")
                    .font(.system(size: 14, weight: .medium))
                TextField("https://yourwebsite.com", text: $website)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
        }
    }
    
    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: saveProfile) {
            if isSaving {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                Text("Save Changes")
                    .fontWeight(.semibold)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(12)
        .disabled(isSaving || (username != authManager.currentUser?.username && !usernameAvailable))
    }
    
    // MARK: - Helper Methods
    private func loadUserData() {
        guard let user = authManager.currentUser else { return }
        
        username = user.username
        displayName = user.displayName ?? user.username
        firstName = user.firstName ?? ""
        lastName = user.lastName ?? ""
        bio = user.bio ?? ""
        email = user.email
        phone = user.phone ?? ""
        location = user.location ?? ""
        website = user.website ?? ""
        
        if let birthdateString = user.birthdate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            birthdate = formatter.date(from: birthdateString) ?? Date()
        }
        
        // Check username change eligibility
        Task {
            await checkUsernameChangeEligibility()
        }
    }
    
    private func checkUsernameChangeEligibility() async {
        // This would call an API to check if user can change username
        // For now, we'll use the stored last change date
        if let user = authManager.currentUser,
           let lastChange = user.lastUsernameChange {
            let daysSinceChange = Date().timeIntervalSince(lastChange) / (60 * 60 * 24)
            if daysSinceChange < 90 {
                canChangeUsername = false
                daysUntilUsernameChange = Int(ceil(90 - daysSinceChange))
            }
        }
    }
    
    private func checkUsernameAvailability(_ username: String) {
        guard !username.isEmpty else {
            usernameMessage = ""
            return
        }
        
        // Validate format
        let usernameRegex = "^[a-z0-9_]{3,20}$"
        let usernamePredicate = NSPredicate(format: "SELF MATCHES %@", usernameRegex)
        
        if !usernamePredicate.evaluate(with: username.lowercased()) {
            usernameMessage = "Invalid format"
            usernameAvailable = false
            isCheckingUsername = false
            return
        }
        
        // Check availability via API
        Task {
            do {
                let available = try await APIClient.shared.checkUsernameAvailability(username: username.lowercased())
                await MainActor.run {
                    usernameAvailable = available.available
                    usernameMessage = available.message
                    isCheckingUsername = false
                }
            } catch {
                await MainActor.run {
                    usernameMessage = "Error checking username"
                    usernameAvailable = false
                    isCheckingUsername = false
                }
            }
        }
    }
    
    private func saveProfile() {
        guard !isSaving else { return }
        
        // Check if username is being changed
        if username != authManager.currentUser?.username && canChangeUsername {
            showUsernameWarning = true
            return
        }
        
        isSaving = true
        
        Task {
            do {
                // Upload profile image if changed
                var profilePictureUrl: String?
                if let image = profileImage {
                    profilePictureUrl = try await uploadProfileImage(image)
                }
                
                // Prepare update data
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"

                var updateData: [String: Any] = [
                    "first_name": firstName,
                    "last_name": lastName,
                    "bio": bio,
                    "phone": phone,
                    "website": website,
                    "birthdate": dateFormatter.string(from: birthdate)
                ]
                
                // Only include username if it changed
                if username != authManager.currentUser?.username {
                    updateData["username"] = username.lowercased()
                }
                
                if let profilePictureUrl = profilePictureUrl {
                    updateData["profile_picture"] = profilePictureUrl
                }
                
                // Call update API
                try await APIClient.shared.updateProfileEnhanced(data: updateData)
                
                // Refresh user data
                await authManager.refreshUserProfile()
                
                await MainActor.run {
                    isSaving = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func uploadProfileImage(_ image: UIImage) async throws -> String {
        // Use industry standard compression for profile images (smaller size for profiles)
        guard let imageData = image.optimizedForUpload(maxDimension: 1024, compressionQuality: 0.85) else {
            throw BrrowAPIError.validationError("Failed to process image")
        }

        // This would call the image upload API
        return try await APIClient.shared.uploadProfilePicture(imageData: imageData)
    }
}

// MARK: - View Model
class EditProfileViewModel: ObservableObject {
    @Published var usernameChangeInfo: UsernameChangeInfo?
    
    struct UsernameChangeInfo {
        let canChange: Bool
        let daysUntilAllowed: Int
        let message: String
        let changeCount: Int
        let previousUsername: String?
        let reservedUsernames: [String]
    }
}

// MARK: - Preview
struct EnhancedEditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        EnhancedEditProfileView()
            .environmentObject(AuthManager.shared)
    }
}