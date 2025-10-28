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

// MARK: - Stripe Connect Status Model
struct StripeConnectStatus: Codable {
    let connected: Bool
    let accountId: String?
    let payoutsEnabled: Bool
    let chargesEnabled: Bool
    let detailsSubmitted: Bool
    let bankLast4: String?
}

@MainActor
class AccountLinkingService: NSObject, ObservableObject {
    static let shared = AccountLinkingService()

    @Published var isLinking = false
    @Published var stripeStatus: StripeConnectStatus?

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

        print("🔍 [LINKED ACCOUNTS] Fetching linked accounts...")
        print("   URL: \(url)")
        print("   Token: \(token.prefix(20))...")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            let error = LinkingError.invalidResponse
            PESTControlSystem.shared.captureError(
                error,
                context: "Linked Accounts - Invalid Response",
                severity: .high
            )
            throw error
        }

        print("   Status Code: \(httpResponse.statusCode)")

        if httpResponse.statusCode == 200 {
            struct Response: Codable {
                let success: Bool
                let data: ResponseData

                struct ResponseData: Codable {
                    let accounts: [LinkedAccount]
                    let stripe: StripeStatus?

                    struct StripeStatus: Codable {
                        let connected: Bool
                        let accountId: String?
                        let payoutsEnabled: Bool
                        let chargesEnabled: Bool
                        let detailsSubmitted: Bool
                        let bankLast4: String?
                    }
                }
            }

            do {
                let apiResponse = try JSONDecoder().decode(Response.self, from: data)

                print("   ✅ Linked Accounts Count: \(apiResponse.data.accounts.count)")
                print("   ✅ Stripe Connected: \(apiResponse.data.stripe?.connected ?? false)")

                // Store Stripe status in published property
                if let stripe = apiResponse.data.stripe {
                    self.stripeStatus = StripeConnectStatus(
                        connected: stripe.connected,
                        accountId: stripe.accountId,
                        payoutsEnabled: stripe.payoutsEnabled,
                        chargesEnabled: stripe.chargesEnabled,
                        detailsSubmitted: stripe.detailsSubmitted,
                        bankLast4: stripe.bankLast4
                    )
                } else {
                    self.stripeStatus = nil
                }

                return apiResponse.data.accounts
            } catch {
                print("   ❌ Failed to decode response")
                print("   Raw response: \(String(data: data, encoding: .utf8) ?? "N/A")")

                // Report decoding error to PEST
                PESTControlSystem.shared.captureError(
                    error,
                    context: "Linked Accounts - Decoding Failed",
                    severity: .high,
                    userInfo: [
                        "endpoint": "/api/auth/linked-accounts",
                        "responseData": String(data: data, encoding: .utf8) ?? "N/A"
                    ]
                )
                throw error
            }
        } else {
            // Try to get error message from response
            print("   ❌ Error response: \(httpResponse.statusCode)")
            print("   Response body: \(String(data: data, encoding: .utf8) ?? "N/A")")

            // Report backend error to PEST
            let pestError: Error
            if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
               let message = errorData["message"] {
                pestError = LinkingError.backendError(message)
            } else {
                pestError = LinkingError.serverError(statusCode: httpResponse.statusCode)
            }

            PESTControlSystem.shared.captureError(
                pestError,
                context: "Linked Accounts API Error",
                severity: httpResponse.statusCode >= 500 ? .critical : .high,
                userInfo: [
                    "endpoint": "/api/auth/linked-accounts",
                    "statusCode": httpResponse.statusCode,
                    "responseBody": String(data: data, encoding: .utf8) ?? "N/A"
                ]
            )

            throw pestError
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
            case .discord:
                // Discord linking is handled through the Discord bot
                // User needs to use /verify command in Discord
                throw LinkingError.backendError("Discord linking must be done through the Discord server using /verify command")
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
