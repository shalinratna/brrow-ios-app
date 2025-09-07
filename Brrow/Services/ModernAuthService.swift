//
//  ModernAuthService.swift
//  Brrow
//
//  Modern authentication service that enhances the existing AuthManager
//  with better error handling, analytics, and user experience
//

import Foundation
import AuthenticationServices
import Combine

@MainActor
class ModernAuthService: ObservableObject {
    // MARK: - Published Properties
    @Published var authState: AuthState = .unauthenticated
    @Published var authError: AuthError?
    @Published var isLoading = false
    
    // MARK: - Private Properties
    private let authManager = AuthManager.shared
    private let apiClient = APIClient.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Enums
    enum AuthState {
        case unauthenticated
        case authenticating
        case authenticated
        case guest
    }
    
    enum AuthError: LocalizedError {
        case invalidCredentials
        case networkError(String)
        case serverError(String)
        case appleSignInFailed
        case accountExists
        case invalidData
        case unknown(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidCredentials:
                return "Invalid email or password. Please try again."
            case .networkError(let message):
                return "Network error: \(message)"
            case .serverError(let message):
                return message
            case .appleSignInFailed:
                return "Apple Sign In failed. Please try again."
            case .accountExists:
                return "An account with this email already exists. Try signing in instead."
            case .invalidData:
                return "Please check your information and try again."
            case .unknown(let message):
                return message
            }
        }
    }
    
    // MARK: - Initialization
    init() {
        // Listen to AuthManager changes
        authManager.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuthenticated in
                if isAuthenticated {
                    if self?.authManager.isGuestUser == true {
                        self?.authState = .guest
                    } else {
                        self?.authState = .authenticated
                    }
                } else {
                    self?.authState = .unauthenticated
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Email/Password Authentication
    func signIn(email: String, password: String) async throws {
        guard validateEmail(email) else {
            throw AuthError.invalidData
        }
        
        guard !password.isEmpty else {
            throw AuthError.invalidData
        }
        
        authState = .authenticating
        authError = nil
        
        do {
            _ = try await withCheckedThrowingContinuation { continuation in
                authManager.login(email: email, password: password)
                    .sink(
                        receiveCompletion: { completion in
                            switch completion {
                            case .finished:
                                continuation.resume()
                            case .failure(let error):
                                continuation.resume(throwing: self.mapAPIError(error))
                            }
                        },
                        receiveValue: { _ in
                            // Success handled by AuthManager
                        }
                    )
                    .store(in: &cancellables)
            }
            
            // Track successful login
            await trackAuthEvent(.emailLoginSuccess)
            
        } catch {
            authState = .unauthenticated
            let authError = error as? AuthError ?? AuthError.unknown(error.localizedDescription)
            self.authError = authError
            
            // Track failed login
            await trackAuthEvent(.emailLoginFailure, metadata: ["error": authError.localizedDescription ?? "unknown"])
            
            throw authError
        }
    }
    
    func signUp(email: String, username: String, password: String, birthdate: Date) async throws {
        guard validateEmail(email) else {
            throw AuthError.invalidData
        }
        
        guard validateUsername(username) else {
            throw AuthError.invalidData
        }
        
        guard password.count >= 8 else {
            throw AuthError.invalidData
        }
        
        guard validateAge(birthdate) else {
            throw AuthError.invalidData
        }
        
        authState = .authenticating
        authError = nil
        
        do {
            _ = try await authManager.register(
                email: email,
                username: username,
                password: password,
                birthdate: birthdate
            )
            
            // Track successful registration
            await trackAuthEvent(.emailSignupSuccess)
            
        } catch {
            authState = .unauthenticated
            let authError = mapGenericError(error)
            self.authError = authError
            
            // Track failed registration
            await trackAuthEvent(.emailSignupFailure, metadata: ["error": authError.localizedDescription ?? "unknown"])
            
            throw authError
        }
    }
    
    // MARK: - Apple Sign In
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthError.appleSignInFailed
        }
        
        authState = .authenticating
        authError = nil
        
        do {
            let userIdentifier = credential.user
            let email = credential.email
            let firstName = credential.fullName?.givenName
            let lastName = credential.fullName?.familyName
            
            let authResponse = try await apiClient.appleLogin(
                userIdentifier: userIdentifier,
                email: email,
                firstName: firstName,
                lastName: lastName,
                identityToken: tokenString
            )
            
            authManager.handleAuthSuccess(authResponse)
            
            // Track successful Apple Sign In
            await trackAuthEvent(.appleLoginSuccess, metadata: [
                "is_new_user": "\(authResponse.isNewUser ?? false)"
            ])
            
        } catch {
            authState = .unauthenticated
            let authError = mapAPIError(error as? BrrowAPIError ?? BrrowAPIError.serverError("Apple Sign In failed"))
            self.authError = authError
            
            // Track failed Apple Sign In
            await trackAuthEvent(.appleLoginFailure, metadata: ["error": authError.localizedDescription ?? "unknown"])
            
            throw authError
        }
    }
    
    // MARK: - Guest Mode
    func continueAsGuest() {
        authManager.loginAsGuest()
        authState = .guest
        
        Task {
            await trackAuthEvent(.guestLogin)
        }
    }
    
    // MARK: - Logout
    func signOut() {
        authManager.logout()
        authState = .unauthenticated
        authError = nil
        
        Task {
            await trackAuthEvent(.logout)
        }
    }
    
    // MARK: - Validation Methods
    private func validateEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func validateUsername(_ username: String) -> Bool {
        let usernameRegex = "^[a-zA-Z0-9_]{3,20}$"
        let usernamePredicate = NSPredicate(format: "SELF MATCHES %@", usernameRegex)
        return usernamePredicate.evaluate(with: username) && username.count >= 3
    }
    
    private func validateAge(_ birthdate: Date) -> Bool {
        let age = Calendar.current.dateComponents([.year], from: birthdate, to: Date()).year ?? 0
        return age >= 13
    }
    
    // MARK: - Error Mapping
    private func mapAPIError(_ error: BrrowAPIError) -> AuthError {
        switch error {
        case .networkError(let message):
            return .networkError(message)
        case .unauthorized:
            return .invalidCredentials
        case .serverError(let message):
            return .serverError(message)
        case .serverErrorCode(let code):
            return .serverError("Server error (\(code))")
        case .validationError(let message):
            return .serverError(message)
        case .addressConflict(let message):
            return .accountExists
        case .decodingError:
            return .invalidData
        case .invalidResponse:
            return .unknown("Invalid server response")
        }
    }
    
    private func mapGenericError(_ error: Error) -> AuthError {
        if let brrowError = error as? BrrowAPIError {
            return mapAPIError(brrowError)
        } else {
            return .unknown(error.localizedDescription)
        }
    }
    
    // MARK: - Helper Methods
    private func createFullName(from personNameComponents: PersonNameComponents?) -> String {
        guard let components = personNameComponents else { return "" }
        
        let parts = [components.givenName, components.familyName]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        
        return parts.joined(separator: " ")
    }
    
    // MARK: - Analytics
    private enum AuthEventType {
        case emailLoginSuccess
        case emailLoginFailure
        case emailSignupSuccess
        case emailSignupFailure
        case appleLoginSuccess
        case appleLoginFailure
        case guestLogin
        case logout
        
        var eventName: String {
            switch self {
            case .emailLoginSuccess:
                return "auth_email_login_success"
            case .emailLoginFailure:
                return "auth_email_login_failure"
            case .emailSignupSuccess:
                return "auth_email_signup_success"
            case .emailSignupFailure:
                return "auth_email_signup_failure"
            case .appleLoginSuccess:
                return "auth_apple_login_success"
            case .appleLoginFailure:
                return "auth_apple_login_failure"
            case .guestLogin:
                return "auth_guest_login"
            case .logout:
                return "auth_logout"
            }
        }
    }
    
    private func trackAuthEvent(_ eventType: AuthEventType, metadata: [String: String] = [:]) async {
        var eventMetadata = metadata
        eventMetadata["platform"] = "ios"
        eventMetadata["app_version"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        
        let event = AnalyticsEvent(
            eventName: eventType.eventName,
            eventType: "authentication",
            userId: authManager.currentUser?.apiId,
            sessionId: authManager.sessionId,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            metadata: eventMetadata
        )
        
        _ = try? await apiClient.trackAnalytics(event: event)
    }
}

// MARK: - Convenience Extensions
extension ModernAuthService {
    var isAuthenticated: Bool {
        authState == .authenticated
    }
    
    var isGuest: Bool {
        authState == .guest
    }
    
    var currentUser: User? {
        authManager.currentUser
    }
    
    func clearError() {
        authError = nil
    }
}