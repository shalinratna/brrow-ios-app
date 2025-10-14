//
//  LoginViewModel.swift
//  Brrow
//
//  Created by Shalin Ratna on 7/16/25.
//

import Foundation
import Combine
import SwiftUI

// MARK: - Login View Model
class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var username = ""
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var birthdate = Date()
    @Published var birthdateText = ""  // For text input field
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var isLoginMode = true

    var isBirthdateValid: Bool {
        let age = Calendar.current.dateComponents([.year], from: birthdate, to: Date()).year ?? 0
        return age >= 13
    }
    @Published var isLoggedIn = false
    @Published var showPassword = false
    @Published var showError = false
    @Published var showSpecialUsernameAlert = false
    @Published var specialUsernameCode = ""

    // Username availability checking
    @Published var isCheckingUsername = false
    @Published var usernameIsAvailable: Bool? = nil
    @Published var usernameCheckMessage = ""

    private var cancellables = Set<AnyCancellable>()
    private let authManager = AuthManager.shared
    private var usernameCheckTask: Task<Void, Never>?
    
    init() {
        // Observe authentication state
        authManager.$isAuthenticated
            .assign(to: \.isLoggedIn, on: self)
            .store(in: &cancellables)

        // Set up debounced username checking
        $username
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] newUsername in
                self?.checkUsernameAvailability(newUsername)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Validation
    var isValidEmail: Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    var isValidPassword: Bool {
        return password.count >= 8
    }
    
    // Reserved usernames that cannot be used
    private let reservedUsernames: Set<String> = [
        "admin", "root", "api", "test", "null", "undefined",
        "brrow", "official", "support", "help", "staff",
        "settings", "profile", "account", "login", "signup",
        "moderator", "mod", "customer_service", "service",
        "brrow_official", "brrow_admin", "brrow_support", "team",
        "system", "bot", "anonymous", "deleted", "blocked"
    ]
    
    // Special usernames that require access codes (for friends/family)
    private let specialUsernames: Set<String> = [
        "shalin", "rishay", "deepa", "raj", "gold toes", 
        "ratnuts", "ratna", "shalina", "shalu", 
        "3217 ormonde", "bravin"
    ]
    
    // Single access code for all special usernames
    private let specialAccessCode = "caloricDeficit14"
    
    // Check if username requires special code
    func requiresSpecialCode(_ username: String) -> Bool {
        return specialUsernames.contains(username.lowercased())
    }
    
    // Validate special code
    func validateSpecialCode(_ username: String, code: String) -> Bool {
        guard specialUsernames.contains(username.lowercased()) else {
            return false
        }
        return code == specialAccessCode
    }
    
    var isValidUsername: Bool {
        // Check length first
        guard username.count >= 3 && username.count <= 20 else { return false }
        
        // Special usernames are allowed with code, so don't block them here
        if requiresSpecialCode(username) {
            return true // Will require code verification later
        }
        
        // Check if it's a reserved username (non-special)
        if reservedUsernames.contains(username.lowercased()) {
            return false
        }
        
        // Check for brrow impersonation patterns
        let lowerUsername = username.lowercased()
        if lowerUsername.hasPrefix("brrow_") || lowerUsername.hasPrefix("official_") || 
           lowerUsername.contains("_official") || lowerUsername.contains("_admin") ||
           lowerUsername.contains("_support") || lowerUsername.contains("_staff") {
            return false
        }
        
        // New regex: allows letters, numbers, underscore, and period
        // Cannot start/end with period or underscore
        // No consecutive periods or underscores
        let usernameRegex = "^(?![._])(?!.*[._]{2})[a-zA-Z0-9._]{3,20}(?<![._])$"
        let usernamePredicate = NSPredicate(format: "SELF MATCHES %@", usernameRegex)
        return usernamePredicate.evaluate(with: username)
    }
    
    var usernameValidationMessage: String {
        if username.isEmpty {
            return "Username is required"
        } else if username.count < 3 {
            return "Username must be at least 3 characters"
        } else if username.count > 20 {
            return "Username must be 20 characters or less"
        } else if requiresSpecialCode(username) {
            return "This username requires a special access code"
        } else if reservedUsernames.contains(username.lowercased()) {
            return "This username is reserved"
        } else if username.lowercased().hasPrefix("brrow_") || 
                  username.lowercased().contains("_official") ||
                  username.lowercased().contains("_admin") {
            return "This username is not allowed"
        } else if username.hasPrefix(".") || username.hasPrefix("_") {
            return "Username cannot start with . or _"
        } else if username.hasSuffix(".") || username.hasSuffix("_") {
            return "Username cannot end with . or _"
        } else if username.contains("..") || username.contains("__") {
            return "Username cannot have consecutive . or _"
        } else if !isValidUsername {
            return "Username can only contain letters, numbers, . and _"
        }
        return ""
    }
    
    var isValidAge: Bool {
        let age = Calendar.current.dateComponents([.year], from: birthdate, to: Date()).year ?? 0
        return age >= 13
    }
    
    var canSubmit: Bool {
        if isLoginMode {
            // For login, accept either valid email OR non-empty username
            let hasValidLoginId = isValidEmail || !email.isEmpty
            return hasValidLoginId && isValidPassword && !isLoading
        } else {
            // For sign-up, also check username availability
            let usernameOk = isValidUsername && (usernameIsAvailable == true) && !isCheckingUsername
            return isValidEmail && isValidPassword && usernameOk && isValidAge && !isLoading
        }
    }

    // MARK: - Username Availability Check
    private func checkUsernameAvailability(_ username: String) {
        // Cancel any pending check
        usernameCheckTask?.cancel()

        // Reset state
        usernameIsAvailable = nil
        usernameCheckMessage = ""

        // Don't check if username is empty or too short
        guard !username.isEmpty && username.count >= 3 else {
            return
        }

        // Don't check if username format is invalid
        guard isValidUsername else {
            return
        }

        // Don't check if it's a special username (requires code)
        if requiresSpecialCode(username) {
            return
        }

        // Show loading state
        isCheckingUsername = true

        // Create new check task
        usernameCheckTask = Task { @MainActor in
            do {
                // Add a small delay to debounce
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

                // Check if task was cancelled
                if Task.isCancelled {
                    return
                }

                // Call API to check username
                let response = try await APIClient.shared.checkUsernameAvailability(username: username)

                // Check if task was cancelled after API call
                if Task.isCancelled {
                    return
                }

                // Update UI
                await MainActor.run {
                    self.usernameIsAvailable = response.available
                    self.usernameCheckMessage = response.message
                    self.isCheckingUsername = false
                }

            } catch {
                // Handle error
                if !Task.isCancelled {
                    await MainActor.run {
                        self.usernameIsAvailable = nil
                        self.usernameCheckMessage = "Failed to check availability"
                        self.isCheckingUsername = false
                    }
                }
            }
        }
    }

    // MARK: - Actions
    @MainActor
    func login() async {
        guard canSubmit else { return }
        
        isLoading = true
        errorMessage = ""
        showError = false
        
        do {
            // Call the async version directly - use email as username for login
            let authResponse = try await APIClient.shared.login(email: email, password: password)
            
            // Handle success
            authManager.handleAuthSuccess(authResponse)
            
            // Test authentication immediately after login
            Task {
                do {
                    print("🔐 Testing authentication after login...")
                    let testResult = try await APIClient.shared.testAuthenticationDetailed()
                    print("🔐 Auth test result: \(testResult)")
                } catch {
                    print("❌ Auth test failed: \(error)")
                }
            }
            
            trackLoginSuccess()
            clearForm()
            isLoading = false
            
        } catch {
            isLoading = false
            
            // Handle specific error types
            if let brrowError = error as? BrrowAPIError {
                switch brrowError {
                case .networkError(let message):
                    errorMessage = "Network error: \(message)"
                case .unauthorized:
                    errorMessage = "Invalid email/username or password"
                case .serverError(let message):
                    errorMessage = message
                case .validationError(let message):
                    errorMessage = message
                default:
                    errorMessage = "Login failed. Please try again."
                }
            } else {
                errorMessage = error.localizedDescription
            }
            
            showError = true
            trackLoginError(errorMessage)
        }
    }
    
    func register() {
        guard canSubmit else { return }
        
        // Check if this is a special username
        if requiresSpecialCode(username) {
            showSpecialUsernameAlert = true
            return
        }
        
        isLoading = true
        errorMessage = ""
        showError = false
        
        Task {
            do {
                let user = try await authManager.register(
                    email: email,
                    username: username, 
                    password: password,
                    firstName: firstName,
                    lastName: lastName,
                    birthdate: birthdate
                )
                await MainActor.run {
                    self.isLoading = false
                    self.trackRegistrationSuccess()
                    self.clearForm()
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.showError = true
                    
                    // Handle specific error types
                    if let brrowError = error as? BrrowAPIError {
                        switch brrowError {
                        case .networkError(let message):
                            self.errorMessage = "Network error: \(message)"
                        case .unauthorized:
                            self.errorMessage = "Email already registered"
                        case .serverError(let message):
                            self.errorMessage = message
                        case .validationError(let message):
                            self.errorMessage = message
                        default:
                            self.errorMessage = "Registration failed. Please try again."
                        }
                    } else {
                        self.errorMessage = error.localizedDescription
                    }
                    
                    self.trackRegistrationError(self.errorMessage)
                }
            }
        }
    }
    
    func toggleMode() {
        isLoginMode.toggle()
        errorMessage = ""
    }
    
    func proceedWithSpecialRegistration() {
        // Validate the access code
        if !validateSpecialCode(username, code: specialUsernameCode) {
            errorMessage = "Invalid access code"
            showError = true
            showSpecialUsernameAlert = false
            specialUsernameCode = ""
            return
        }
        
        // Clear the code and proceed with registration
        showSpecialUsernameAlert = false
        specialUsernameCode = ""
        
        // Now proceed with the actual registration
        isLoading = true
        errorMessage = ""
        showError = false
        
        Task {
            do {
                let user = try await authManager.register(
                    email: email,
                    username: username,
                    password: password,
                    firstName: firstName,
                    lastName: lastName,
                    birthdate: birthdate
                )
                await MainActor.run {
                    self.isLoading = false
                    self.trackRegistrationSuccess()
                    self.clearForm()
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.showError = true
                    
                    // Handle specific error types
                    if let brrowError = error as? BrrowAPIError {
                        switch brrowError {
                        case .networkError(let message):
                            self.errorMessage = "Network error: \(message)"
                        case .unauthorized:
                            self.errorMessage = "Email already registered"
                        case .serverError(let message):
                            self.errorMessage = message
                        case .validationError(let message):
                            self.errorMessage = message
                        default:
                            self.errorMessage = "Registration failed. Please try again."
                        }
                    } else {
                        self.errorMessage = error.localizedDescription
                    }
                    
                    self.trackRegistrationError(self.errorMessage)
                }
            }
        }
    }
    
    func clearForm() {
        email = ""
        password = ""
        username = ""
        firstName = ""
        lastName = ""
        birthdate = Date()
        birthdateText = ""
        errorMessage = ""
        showError = false
    }
    
    func parseBirthdate(_ text: String) {
        // Try different date formats
        let formatters = [
            "MM/dd/yyyy",
            "M/d/yyyy",
            "MM-dd-yyyy",
            "M-d-yyyy",
            "yyyy-MM-dd",
            "MMddyyyy"
        ]
        
        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            
            if let date = formatter.date(from: text) {
                birthdate = date
                return
            }
        }
        
        // If no format matches, try to be smart about it
        let cleaned = text.replacingOccurrences(of: "[^0-9]", with: "/", options: .regularExpression)
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        if let date = formatter.date(from: cleaned) {
            birthdate = date
        }
    }
    
    @MainActor
    func signInWithApple(userIdentifier: String, email: String?, firstName: String?, lastName: String?, identityToken: String) async {
        print("🍎 [LOGIN-VM] signInWithApple called")
        print("🍎 [LOGIN-VM] User ID: \(userIdentifier)")
        print("🍎 [LOGIN-VM] Email: \(email ?? "nil")")
        print("🍎 [LOGIN-VM] First Name: \(firstName ?? "nil")")
        print("🍎 [LOGIN-VM] Last Name: \(lastName ?? "nil")")
        print("🍎 [LOGIN-VM] Token length: \(identityToken.count)")

        isLoading = true
        errorMessage = ""
        showError = false

        do {
            print("🍎 [LOGIN-VM] Calling APIClient.shared.appleLogin...")

            let response = try await APIClient.shared.appleLogin(
                userIdentifier: userIdentifier,
                email: email,
                firstName: firstName,
                lastName: lastName,
                identityToken: identityToken
            )

            print("🍎 [LOGIN-VM] API call successful")
            print("🍎 [LOGIN-VM] Response token: \(response.authToken ?? "nil")")
            print("🍎 [LOGIN-VM] Response user ID: \(response.user.apiId ?? "nil")")

            authManager.handleAuthSuccess(response)
            print("🍎 [LOGIN-VM] AuthManager.handleAuthSuccess completed")

            trackLoginSuccess()
            clearForm()
            print("✅ [LOGIN-VM] Apple Sign-In completed successfully")
        } catch {
            print("❌ [LOGIN-VM] Apple Sign-In failed with error: \(error)")
            print("❌ [LOGIN-VM] Error type: \(type(of: error))")
            print("❌ [LOGIN-VM] Error description: \(error.localizedDescription)")

            errorMessage = "Apple sign in failed. Please try again."
            showError = true
            trackLoginError("apple_signin_failed: \(error.localizedDescription)")
        }

        isLoading = false
        print("🍎 [LOGIN-VM] isLoading set to false")
    }
    
    // MARK: - Analytics (Shaiitech Sentinel A7)
    private func trackLoginSuccess() {
        let event = AnalyticsEvent(
            eventName: "login_success",
            eventType: "auth",
            userId: authManager.currentUser?.apiId,
            sessionId: authManager.sessionId,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            metadata: [
                "method": "email",
                "platform": "ios"
            ]
        )
        
        APIClient.shared.trackAnalytics(event: event)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
    
    private func trackLoginError(_ error: String) {
        let event = AnalyticsEvent(
            eventName: "login_error",
            eventType: "auth",
            userId: nil,
            sessionId: authManager.sessionId,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            metadata: [
                "error": error,
                "method": "email",
                "platform": "ios"
            ]
        )
        
        APIClient.shared.trackAnalytics(event: event)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
    
    private func trackRegistrationSuccess() {
        let event = AnalyticsEvent(
            eventName: "registration_success",
            eventType: "auth",
            userId: authManager.currentUser?.apiId,
            sessionId: authManager.sessionId,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            metadata: [
                "method": "email",
                "platform": "ios"
            ]
        )
        
        APIClient.shared.trackAnalytics(event: event)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
    
    private func trackRegistrationError(_ error: String) {
        let event = AnalyticsEvent(
            eventName: "registration_error",
            eventType: "auth",
            userId: nil,
            sessionId: authManager.sessionId,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            metadata: [
                "error": error,
                "method": "email",
                "platform": "ios"
            ]
        )
        
        APIClient.shared.trackAnalytics(event: event)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
}