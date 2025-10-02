//
//  GoogleAuthService.swift
//  Brrow
//
//  Created by AI Assistant on 9/14/25.
//

import Foundation
import GoogleSignIn
import UIKit
import Combine

// MARK: - Google Authentication Service
class GoogleAuthService: ObservableObject {
    static let shared = GoogleAuthService()
    
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        configureGoogleSignIn()
    }
    
    // MARK: - Configuration
    private func configureGoogleSignIn() {
        // Use the actual Google Client ID provided
        let clientId = "13144810708-cdf0vg3j0u7krgff4m68pjj6qb6n2dlr.apps.googleusercontent.com"

        let config = GIDConfiguration(clientID: clientId)
        GIDSignIn.sharedInstance.configuration = config
        print("✅ Google Sign-In configured with client ID: \(String(clientId.prefix(20)))...")
    }
    
    // MARK: - Sign In Methods
    @MainActor
    func signIn() async {
        isLoading = true
        errorMessage = ""

        do {
            // Get view controller
            guard let viewController = getCurrentViewController() else {
                throw GoogleSignInError.noPresentingViewController
            }

            // Present sign-in - must be on main thread
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
            let user = result.user
            
            guard let idToken = user.idToken?.tokenString else {
                throw GoogleSignInError.noIDToken
            }
            
            // Extract user information
            let email = user.profile?.email ?? ""
            let firstName = user.profile?.givenName ?? ""
            let lastName = user.profile?.familyName ?? ""
            let fullName = user.profile?.name ?? "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
            // Disabled: Don't fetch Google profile pictures - use platform-only profile system
            let profilePictureUrl: String? = nil
            let googleId = user.userID ?? ""
            
            print("🔐 Google Sign-In successful for: \(email)")
            print("🔐 Google ID: \(googleId)")
            print("🔐 ID Token: \(String(idToken.prefix(50)))...")
            
            // Send to backend for authentication
            try await authenticateWithBackend(
                googleId: googleId,
                email: email,
                firstName: firstName,
                lastName: lastName,
                fullName: fullName,
                profilePictureUrl: profilePictureUrl,
                idToken: idToken
            )

        } catch {
            isLoading = false
            handleSignInError(error)
        }
    }
    
    // MARK: - Backend Authentication
    private func authenticateWithBackend(
        googleId: String,
        email: String,
        firstName: String,
        lastName: String,
        fullName: String,
        profilePictureUrl: String?,
        idToken: String
    ) async throws {
        guard let url = URL(string: "https://brrow-backend-nodejs-production.up.railway.app/api/auth/google") else {
            throw GoogleSignInError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Send the idToken which will be decoded by the backend for account linking
        let requestBody = ["idToken": idToken]

        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GoogleSignInError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)

            isLoading = false
            AuthManager.shared.handleAuthSuccess(authResponse)

            print("✅ Google Sign-In backend authentication successful")
        } else {
            // Try to parse error response
            if let errorResponse = try? JSONDecoder().decode(GoogleSignInErrorResponse.self, from: data) {
                throw GoogleSignInError.backendError(errorResponse.message ?? "Authentication failed")
            } else {
                throw GoogleSignInError.backendError("Authentication failed with status \(httpResponse.statusCode)")
            }
        }
    }
    
    // MARK: - Sign Out
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        print("🔐 Google Sign-Out completed")
    }
    
    // MARK: - Helper Methods
    @MainActor
    private func getCurrentViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        
        return window.rootViewController?.topMostViewController()
    }
    
    private func handleSignInError(_ error: Error) {
        print("❌ Google Sign-In error: \(error)")
        
        if let gidError = error as? GIDSignInError {
            switch gidError.code {
            case .canceled:
                errorMessage = "Sign-in was cancelled"
            case .EMM:
                errorMessage = "Enterprise Mobility Management error"
            case .keychain:
                errorMessage = "Keychain error occurred"
            case .hasNoAuthInKeychain:
                errorMessage = "No saved authentication found"
            case .scopesAlreadyGranted:
                errorMessage = "Permissions already granted"
            case .unknown:
                errorMessage = "An unknown error occurred"
            @unknown default:
                errorMessage = "Sign-in failed: \(error.localizedDescription)"
            }
        } else if let customError = error as? GoogleSignInError {
            switch customError {
            case .noPresentingViewController:
                errorMessage = "Unable to present sign-in interface"
            case .noIDToken:
                errorMessage = "Failed to obtain authentication token"
            case .invalidURL:
                errorMessage = "Configuration error - invalid server URL"
            case .invalidResponse:
                errorMessage = "Invalid response from server"
            case .backendError(let message):
                errorMessage = message
            }
        } else {
            errorMessage = "Sign-in failed: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Check Sign-In Status
    var isSignedIn: Bool {
        return GIDSignIn.sharedInstance.currentUser != nil
    }
    
    // MARK: - Restore Previous Sign-In
    func restorePreviousSignIn() async {
        do {
            guard GIDSignIn.sharedInstance.hasPreviousSignIn() else {
                print("🔐 No previous Google Sign-In found")
                return
            }
            
            let user = try await GIDSignIn.sharedInstance.restorePreviousSignIn()
            print("🔐 Restored previous Google Sign-In for: \(user.profile?.email ?? "unknown")")
            
            // You might want to refresh the token and re-authenticate with backend
            // depending on your app's requirements
            
        } catch {
            print("❌ Failed to restore previous Google Sign-In: \(error)")
        }
    }
}

// MARK: - Data Models
struct GoogleSignInRequest: Codable {
    let googleId: String
    let email: String
    let firstName: String
    let lastName: String
    let profilePictureUrl: String?
    let idToken: String
}

struct GoogleSignInErrorResponse: Codable {
    let success: Bool
    let message: String?
    let error: String?
}

// MARK: - Custom Errors
enum GoogleSignInError: LocalizedError {
    case noPresentingViewController
    case noIDToken
    case invalidURL
    case invalidResponse
    case backendError(String)
    
    var errorDescription: String? {
        switch self {
        case .noPresentingViewController:
            return "No presenting view controller found"
        case .noIDToken:
            return "Failed to obtain ID token from Google"
        case .invalidURL:
            return "Invalid backend URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .backendError(let message):
            return message
        }
    }
}

// MARK: - UIViewController Extension
extension UIViewController {
    func topMostViewController() -> UIViewController {
        if let presented = presentedViewController {
            return presented.topMostViewController()
        }
        
        if let navigationController = self as? UINavigationController {
            return navigationController.visibleViewController?.topMostViewController() ?? self
        }
        
        if let tabBarController = self as? UITabBarController {
            return tabBarController.selectedViewController?.topMostViewController() ?? self
        }
        
        return self
    }
}