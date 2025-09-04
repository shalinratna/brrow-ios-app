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
    @Published var birthdate = Date()
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var isLoginMode = true
    @Published var isLoggedIn = false
    @Published var showPassword = false
    @Published var showError = false
    
    private var cancellables = Set<AnyCancellable>()
    private let authManager = AuthManager.shared
    
    init() {
        // Observe authentication state
        authManager.$isAuthenticated
            .assign(to: \.isLoggedIn, on: self)
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
    
    var isValidUsername: Bool {
        let usernameRegex = "^[a-zA-Z0-9_]{3,20}$"
        let usernamePredicate = NSPredicate(format: "SELF MATCHES %@", usernameRegex)
        return usernamePredicate.evaluate(with: username)
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
            return isValidEmail && isValidPassword && isValidUsername && isValidAge && !isLoading
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
            // Call the async version directly
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
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                let user = try await authManager.register(
                    email: email,
                    username: username, 
                    password: password, 
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
                    self.errorMessage = error.localizedDescription
                    self.trackRegistrationError(error.localizedDescription)
                }
            }
        }
    }
    
    func toggleMode() {
        isLoginMode.toggle()
        errorMessage = ""
    }
    
    func clearForm() {
        email = ""
        password = ""
        username = ""
        birthdate = Date()
        errorMessage = ""
    }
    
    @MainActor
    func signInWithApple(userIdentifier: String, email: String?, fullName: String, identityToken: String) async {
        isLoading = true
        errorMessage = ""
        showError = false
        
        do {
            let response = try await APIClient.shared.appleLogin(
                userIdentifier: userIdentifier,
                email: email,
                fullName: fullName,
                identityToken: identityToken
            )
            
            authManager.handleAuthSuccess(response)
            trackLoginSuccess()
            clearForm()
        } catch {
            errorMessage = "Apple sign in failed. Please try again."
            showError = true
            trackLoginError("apple_signin_failed")
        }
        
        isLoading = false
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