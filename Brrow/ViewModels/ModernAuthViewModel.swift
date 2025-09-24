//
//  ModernAuthViewModel.swift
//  Brrow
//
//  Modern authentication view model with enhanced error handling
//  and Apple Sign-In integration
//

import Foundation
import Combine
import AuthenticationServices
import SwiftUI

@MainActor
class ModernAuthViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var email = ""
    @Published var username = ""
    @Published var password = ""
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var birthdate = Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var isAuthenticated = false
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let authManager = AuthManager.shared
    private let apiClient = APIClient.shared
    
    // MARK: - Computed Properties
    var isValidEmail: Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    var isValidUsername: Bool {
        let usernameRegex = "^[a-zA-Z0-9_]{3,20}$"
        let usernamePredicate = NSPredicate(format: "SELF MATCHES %@", usernameRegex)
        return usernamePredicate.evaluate(with: username) && username.count >= 3
    }
    
    var isValidPassword: Bool {
        return password.count >= 8
    }
    
    var isValidAge: Bool {
        let age = Calendar.current.dateComponents([.year], from: birthdate, to: Date()).year ?? 0
        return age >= 13
    }
    
    // MARK: - Initialization
    init() {
        // Listen for authentication state changes
        authManager.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .assign(to: \.isAuthenticated, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Sign In
    func signIn() async {
        guard !email.isEmpty && !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        guard isValidEmail else {
            errorMessage = "Please enter a valid email address"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            // Use the existing AuthManager login method
            _ = try await withCheckedThrowingContinuation { continuation in
                authManager.login(email: email, password: password)
                    .sink(
                        receiveCompletion: { completion in
                            switch completion {
                            case .finished:
                                continuation.resume()
                            case .failure(let error):
                                continuation.resume(throwing: error)
                            }
                        },
                        receiveValue: { success in
                            // Login successful - AuthManager has already handled the response
                        }
                    )
                    .store(in: &cancellables)
            }
            
            // Track successful login
            trackAuthEvent("email_login_success")
            
            // Clear form on success
            clearForm()
            
        } catch {
            handleAuthError(error)
            trackAuthEvent("email_login_failure", metadata: ["error": error.localizedDescription])
        }
        
        isLoading = false
    }
    
    // MARK: - Sign Up
    func signUp() async {
        guard !email.isEmpty && !username.isEmpty && !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        guard isValidEmail else {
            errorMessage = "Please enter a valid email address"
            return
        }
        
        guard isValidUsername else {
            errorMessage = "Username must be 3-20 characters and contain only letters, numbers, and underscores"
            return
        }
        
        guard isValidPassword else {
            errorMessage = "Password must be at least 8 characters long"
            return
        }
        
        guard isValidAge else {
            errorMessage = "You must be at least 13 years old to create an account"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            let user = try await authManager.register(
                email: email,
                username: username,
                password: password,
                firstName: firstName,
                lastName: lastName,
                birthdate: birthdate
            )
            
            // Track successful registration
            trackAuthEvent("email_signup_success")
            
            // Clear form on success
            clearForm()
            
        } catch {
            handleAuthError(error)
            trackAuthEvent("email_signup_failure", metadata: ["error": error.localizedDescription])
        }
        
        isLoading = false
    }
    
    // MARK: - Apple Sign In
    func signInWithApple(userIdentifier: String, email: String?, firstName: String?, lastName: String?, identityToken: String) async {
        isLoading = true
        errorMessage = ""

        print("🍎 Apple Sign-In initiated with user: \(userIdentifier)")

        // Use the existing LoginViewModel Apple Sign-In method
        let loginViewModel = LoginViewModel()
        await loginViewModel.signInWithApple(
            userIdentifier: userIdentifier,
            email: email,
            firstName: firstName,
            lastName: lastName,
            identityToken: identityToken
        )

        // Check if there was an error
        if !loginViewModel.errorMessage.isEmpty {
            errorMessage = loginViewModel.errorMessage
            trackAuthEvent("apple_login_failure", metadata: ["error": loginViewModel.errorMessage])
            print("❌ Apple Sign-In failed: \(loginViewModel.errorMessage)")
        } else {
            // Track successful Apple Sign In
            trackAuthEvent("apple_login_success")
            print("✅ Apple Sign-In successful")

            // Clear form on success
            clearForm()
        }

        isLoading = false
    }

    // Keep the old method for backward compatibility
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async {
        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            errorMessage = "Unable to process Apple Sign In. Please try again."
            return
        }

        await signInWithApple(
            userIdentifier: credential.user,
            email: credential.email,
            firstName: credential.fullName?.givenName,
            lastName: credential.fullName?.familyName,
            identityToken: tokenString
        )
    }
    
    // MARK: - Helper Methods
    private func createFullName(from personNameComponents: PersonNameComponents?) -> String {
        guard let components = personNameComponents else { return "" }
        
        let parts = [components.givenName, components.familyName]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        
        return parts.joined(separator: " ")
    }
    
    private func handleAuthError(_ error: Error) {
        if let brrowError = error as? BrrowAPIError {
            switch brrowError {
            case .networkError(let message):
                errorMessage = "Network error: \(message)"
            case .unauthorized:
                errorMessage = "Invalid email or password"
            case .serverError(let message):
                errorMessage = message
            case .serverErrorCode(let code):
                errorMessage = "Server error (\(code)). Please try again."
            case .validationError(let message):
                errorMessage = message
            case .addressConflict(let message):
                errorMessage = message
            case .decodingError:
                errorMessage = "Unable to process response. Please try again."
            case .invalidResponse:
                errorMessage = "Invalid response from server. Please try again."
            case .invalidURL:
                errorMessage = "Invalid request. Please try again."
            }
        } else if error.localizedDescription.contains("The Internet connection appears to be offline") {
            errorMessage = "Please check your internet connection and try again"
        } else {
            errorMessage = error.localizedDescription
        }
    }
    
    private func clearForm() {
        email = ""
        username = ""
        password = ""
        birthdate = Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
        errorMessage = ""
    }
    
    private func trackAuthEvent(_ eventName: String, metadata: [String: String] = [:]) {
        var eventMetadata = metadata
        eventMetadata["platform"] = "ios"
        eventMetadata["app_version"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        
        let event = AnalyticsEvent(
            eventName: eventName,
            eventType: "authentication",
            userId: authManager.currentUser?.apiId,
            sessionId: authManager.sessionId,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            metadata: eventMetadata
        )
        
        Task {
            _ = try? await apiClient.trackAnalytics(event: event)
        }
    }
}

// MARK: - BrrowAPIError Extension for better error handling
extension BrrowAPIError {
    var userFriendlyMessage: String {
        switch self {
        case .networkError(let message):
            return message.isEmpty ? "Please check your internet connection and try again" : message
        case .unauthorized:
            return "Invalid credentials. Please check your email and password."
        case .serverError(let message):
            return message.isEmpty ? "Server error. Please try again later." : message
        case .serverErrorCode(let code):
            return "Server error (\(code)). Please try again later."
        case .validationError(let message):
            return message.isEmpty ? "Please check your information and try again." : message
        case .addressConflict(let message):
            return message.isEmpty ? "This account already exists. Try signing in instead." : message
        case .decodingError(let error):
            return "Unable to process response: \(error.localizedDescription)"
        case .invalidResponse:
            return "Received invalid response from server. Please try again."
        case .invalidURL:
            return "Invalid server URL. Please contact support."
        }
    }
}