//
//  AccountLinkingService.swift
//  Brrow
//
//  Service for linking/unlinking OAuth accounts
//

import Foundation
import GoogleSignIn
import AuthenticationServices
import UIKit

@MainActor
class AccountLinkingService: NSObject, ObservableObject {
    static let shared = AccountLinkingService()

    @Published var isLinking = false

    private var currentProvider: OAuthProvider?
    private var linkContinuation: CheckedContinuation<Void, Error>?

    private override init() {
        super.init()
    }

    // MARK: - Fetch Linked Accounts
    func fetchLinkedAccounts() async throws -> [LinkedAccount] {
        guard let token = AuthManager.shared.authToken else {
            throw LinkingError.notAuthenticated
        }

        let baseURL = await APIClient.shared.getBaseURL()
        guard let url = URL(string: "\(baseURL)/api/auth/linked-accounts") else {
            throw LinkingError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LinkingError.invalidResponse
        }

        if httpResponse.statusCode == 200 {
            struct AccountInfo: Codable {
                let linked: Bool
                let email: String?
                let linkedAt: String?
            }

            struct Response: Codable {
                let success: Bool
                let accounts: AccountsContainer

                struct AccountsContainer: Codable {
                    let google: AccountInfo
                    let apple: AccountInfo
                }
            }

            let apiResponse = try JSONDecoder().decode(Response.self, from: data)

            // Convert to LinkedAccount array
            var accounts: [LinkedAccount] = []

            if apiResponse.accounts.google.linked,
               let email = apiResponse.accounts.google.email,
               let linkedAt = apiResponse.accounts.google.linkedAt {
                accounts.append(LinkedAccount(
                    id: "google",
                    provider: "google",
                    email: email,
                    createdAt: linkedAt
                ))
            }

            if apiResponse.accounts.apple.linked,
               let email = apiResponse.accounts.apple.email,
               let linkedAt = apiResponse.accounts.apple.linkedAt {
                accounts.append(LinkedAccount(
                    id: "apple",
                    provider: "apple",
                    email: email,
                    createdAt: linkedAt
                ))
            }

            return accounts
        } else {
            throw LinkingError.serverError(statusCode: httpResponse.statusCode)
        }
    }

    // MARK: - Link Account
    func linkAccount(provider: OAuthProvider) async throws {
        isLinking = true
        currentProvider = provider

        do {
            switch provider {
            case .google:
                try await linkGoogleAccount()
            case .apple:
                try await linkAppleAccount()
            }
            isLinking = false
        } catch {
            isLinking = false
            throw error
        }
    }

    // MARK: - Link Google Account
    private func linkGoogleAccount() async throws {
        guard let viewController = getCurrentViewController() else {
            throw LinkingError.noPresentingViewController
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
        let user = result.user

        guard let idToken = user.idToken?.tokenString else {
            throw LinkingError.noIDToken
        }

        let email = user.profile?.email ?? ""
        let googleId = user.userID ?? ""

        // Send to backend
        try await sendLinkRequest(provider: "google", providerId: googleId, email: email, idToken: idToken)
    }

    // MARK: - Link Apple Account
    private func linkAppleAccount() async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.linkContinuation = continuation

            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.email]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    // MARK: - Unlink Account
    func unlinkAccount(provider: OAuthProvider) async throws {
        guard let token = AuthManager.shared.authToken else {
            throw LinkingError.notAuthenticated
        }

        let baseURL = await APIClient.shared.getBaseURL()
        guard let url = URL(string: "\(baseURL)/api/auth/unlink/\(provider.rawValue)") else {
            throw LinkingError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LinkingError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            throw LinkingError.serverError(statusCode: httpResponse.statusCode)
        }
    }

    // MARK: - Send Link Request to Backend
    private func sendLinkRequest(provider: String, providerId: String, email: String, idToken: String) async throws {
        guard let token = AuthManager.shared.authToken else {
            throw LinkingError.notAuthenticated
        }

        let baseURL = await APIClient.shared.getBaseURL()
        guard let url = URL(string: "\(baseURL)/api/auth/link/\(provider)") else {
            throw LinkingError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let requestBody: [String: String] = [
            "idToken": idToken,
            "email": email
        ]

        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LinkingError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            // Try to parse error message
            struct ErrorResponse: Codable {
                let success: Bool
                let message: String?
            }

            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data),
               let message = errorResponse.message {
                throw LinkingError.backendError(message)
            } else {
                throw LinkingError.serverError(statusCode: httpResponse.statusCode)
            }
        }
    }

    // MARK: - Helper Methods
    private func getCurrentViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }

        return window.rootViewController?.topMostViewController()
    }
}

// MARK: - Apple Sign In Delegate
extension AccountLinkingService: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Task { @MainActor in
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                linkContinuation?.resume(throwing: LinkingError.invalidAppleCredential)
                linkContinuation = nil
                return
            }

            guard let identityToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: identityToken, encoding: .utf8) else {
                linkContinuation?.resume(throwing: LinkingError.noIDToken)
                linkContinuation = nil
                return
            }

            let appleUserId = appleIDCredential.user
            let email = appleIDCredential.email ?? ""

            do {
                try await sendLinkRequest(provider: "apple", providerId: appleUserId, email: email, idToken: idTokenString)
                linkContinuation?.resume()
                linkContinuation = nil
            } catch {
                linkContinuation?.resume(throwing: error)
                linkContinuation = nil
            }
        }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Task { @MainActor in
            linkContinuation?.resume(throwing: LinkingError.appleSignInFailed(error))
            linkContinuation = nil
        }
    }
}

// MARK: - Presentation Context Provider
extension AccountLinkingService: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }
}

// MARK: - Errors
enum LinkingError: LocalizedError {
    case notAuthenticated
    case invalidURL
    case invalidResponse
    case noPresentingViewController
    case noIDToken
    case invalidAppleCredential
    case appleSignInFailed(Error)
    case backendError(String)
    case serverError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to link accounts"
        case .invalidURL:
            return "Invalid server URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .noPresentingViewController:
            return "Unable to present sign-in interface"
        case .noIDToken:
            return "Failed to obtain authentication token"
        case .invalidAppleCredential:
            return "Invalid Apple credential"
        case .appleSignInFailed(let error):
            return "Apple Sign In failed: \(error.localizedDescription)"
        case .backendError(let message):
            return message
        case .serverError(let statusCode):
            return "Server error: \(statusCode)"
        }
    }
}
