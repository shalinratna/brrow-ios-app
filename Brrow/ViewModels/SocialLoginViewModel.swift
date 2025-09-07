//
//  SocialLoginViewModel.swift
//  Brrow
//
//  Enhanced Login Supporting Email OR Username
//

import Foundation
import AuthenticationServices
import Combine

// MARK: - Social Login Error
enum SocialLoginError: Error {
    case loginFailed
    case invalidCredentials
    case networkError
}

@MainActor
class SocialLoginViewModel: ObservableObject {
    @Published var isLoggedIn = false
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var username = ""
    @Published var birthdate = Date()
    
    private var cancellables = Set<AnyCancellable>()
    private let authManager = AuthManager.shared
    private let apiClient = APIClient.shared
    
    init() {
        // Check if already logged in
        isLoggedIn = authManager.isAuthenticated
    }
    
    func signIn(loginInput: String, password: String) {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                // Determine if input is email or username
                let isEmail = loginInput.contains("@")
                
                // Use the existing login method
                await authManager.login(email: loginInput, password: password)
                
                await MainActor.run {
                    self.isLoading = false
                    self.isLoggedIn = true
                }
                
                // Track login analytics
                trackLoginEvent(method: isEmail ? "email" : "username")
                
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func signUp(email: String, password: String) {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                _ = try await authManager.register(
                    email: email,
                    username: username,
                    password: password,
                    birthdate: birthdate
                )
                
                await MainActor.run {
                    self.isLoading = false
                    self.isLoggedIn = true
                }
                
                // Track signup analytics
                trackSignupEvent(method: "email")
                
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func handleAppleSignIn(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }
    
    func handleAppleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                signInWithApple(credential: appleIDCredential)
            }
        case .failure(let error):
            errorMessage = "Apple Sign In failed: \(error.localizedDescription)"
        }
    }
    
    func signInWithGoogle() {
        // Google Sign In will be implemented when GoogleSignIn SDK is integrated
        errorMessage = "Google Sign In coming soon"
    }
    
    func canSubmit(loginInput: String, password: String, isLoginMode: Bool) -> Bool {
        if isLoginMode {
            return !loginInput.isEmpty && password.count >= 6
        } else {
            return !loginInput.isEmpty && 
                   !username.isEmpty && 
                   password.count >= 6 && 
                   isValidAge()
        }
    }
    
    // MARK: - Private Methods
    
    private func signInWithApple(credential: ASAuthorizationAppleIDCredential) {
        isLoading = true
        
        Task {
            do {
                _ = try await authManager.signInWithApple(credential: credential)
                
                await MainActor.run {
                    self.isLoading = false
                    self.isLoggedIn = true
                }
                
                trackLoginEvent(method: "apple")
                
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func isValidAge() -> Bool {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthdate, to: Date())
        return (ageComponents.year ?? 0) >= 13
    }
    
    private func trackLoginEvent(method: String) {
        let event = AnalyticsEvent(
            eventName: "user_login",
            eventType: "authentication",
            userId: authManager.currentUser?.apiId,
            sessionId: authManager.sessionId,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            metadata: [
                "login_method": method,
                "platform": "ios"
            ]
        )
        
        Task {
            _ = try? await apiClient.trackAnalytics(event: event)
        }
    }
    
    private func trackSignupEvent(method: String) {
        let event = AnalyticsEvent(
            eventName: "user_signup",
            eventType: "authentication",
            userId: authManager.currentUser?.apiId,
            sessionId: authManager.sessionId,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            metadata: [
                "signup_method": method,
                "platform": "ios"
            ]
        )
        
        Task {
            _ = try? await apiClient.trackAnalytics(event: event)
        }
    }
    
}

// MARK: - AuthManager Extensions

extension AuthManager {
    func signInWithUsername(username: String, password: String) async throws -> User {
        // Implementation for username-based login
        // This would call a new API endpoint that accepts username
        let loginData: [String: Any] = [
            "username": username,
            "password": password
        ]
        
        return try await performLogin(with: loginData)
    }
    
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws -> User {
        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid Apple credentials"])
        }
        
        let appleData: [String: Any] = [
            "identity_token": tokenString,
            "user_identifier": credential.user,
            "email": credential.email ?? "",
            "first_name": credential.fullName?.givenName ?? "",
            "last_name": credential.fullName?.familyName ?? ""
        ]
        
        return try await performAppleLogin(with: appleData)
    }
    
    private func performLogin(with data: [String: Any]) async throws -> User {
        // Simply create a mock user for now since social login is not fully implemented
        // The user should use the main login screen for username/email login
        let email = data["email"] as? String ?? ""
        let username = data["username"] as? String ?? ""
        
        // Create a temporary user object
        let tempUser = User(
            id: 1,
            username: username.isEmpty ? email.components(separatedBy: "@").first ?? "user" : username,
            email: email
        )
        
        // In a real implementation, this would call the proper login API
        // For now, throw an error to indicate social login is not available
        throw SocialLoginError.loginFailed
    }
    
    private func performAppleLogin(with data: [String: Any]) async throws -> User {
        // Use APIClient's appleLogin method
        let response = try await APIClient.shared.appleLogin(
            userIdentifier: data["user_identifier"] as? String ?? "",
            email: data["email"] as? String,
            firstName: data["first_name"] as? String,
            lastName: data["last_name"] as? String,
            identityToken: data["identity_token"] as? String ?? ""
        )
        
        // Handle auth success through AuthManager
        AuthManager.shared.handleAuthSuccess(response)
        
        guard let user = AuthManager.shared.currentUser else {
            throw SocialLoginError.loginFailed
        }
        
        return user
    }
}

