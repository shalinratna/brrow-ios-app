//
//  IDmeService.swift
//  Brrow
//
//  ID.me Identity Verification Service
//

import Foundation
import SafariServices
import UIKit

// MARK: - ID.me Configuration
struct IDmeConfig {
    // ID.me Production Credentials
    static let clientID = "02ef5aa6d4b40536a8cb82b7b902aba4"
    static let clientSecret = "d79736fd19dd7960b40d4a342fd56876"
    static let redirectURI = "https://brrow-backend-nodejs-production.up.railway.app/brrow/idme/callback"
    // ✅ Updated to match ID.me dashboard configuration exactly
    
    // ID.me API Endpoints
    static let baseURL = "https://api.id.me"
    static let authURL = "https://api.id.me/oauth/authorize"
    static let tokenURL = "https://api.id.me/oauth/token"
    static let userInfoURL = "https://api.id.me/api/public/v3/attributes.json"
    
    // Verification scopes - Using standard OAuth2 scopes
    // ✅ CRITICAL FIX: ID.me OAuth app doesn't have scopes configured
    // Sending ANY scope (even "openid") causes invalid_scope error
    // Solution: Omit scope parameter entirely to use ID.me's default permissions
    static let noScope = ""  // No scope - use ID.me defaults
    static let basicScope = "openid"  // Minimal OpenID scope
    static let profileScope = "openid profile"  // Includes profile info
    static let emailScope = "openid profile email"  // Includes email
    static let identityScope = "openid profile email phone address"
    static let studentScope = "openid profile email student" // For Phase 2

    // Use empty scope to avoid invalid_scope errors
    // ID.me will use default permissions configured in developer portal
    static let defaultScope = noScope
}

// MARK: - ID.me Models
struct IDmeUserProfile: Codable {
    let status: String
    let attributes: IDmeAttributes
}

struct IDmeAttributes: Codable {
    let email: String?
    let firstName: String?
    let lastName: String?
    let birthDate: String?
    let phone: String?
    let zip: String?
    let verified: Bool
    let verificationLevel: String?
    let groups: [String]?
    
    enum CodingKeys: String, CodingKey {
        case email
        case firstName = "fname"
        case lastName = "lname"
        case birthDate = "birth_date"
        case phone
        case zip
        case verified
        case verificationLevel = "verification_level"
        case groups
    }
}

struct IDmeTokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let refreshToken: String?
    let scope: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case scope
    }
}

// MARK: - ID.me Service
class IDmeService: NSObject, ObservableObject {
    static let shared = IDmeService()
    
    @Published var isVerified = false
    @Published var userProfile: IDmeUserProfile?
    @Published var isVerifying = false
    
    private var currentViewController: UIViewController?
    private var safariViewController: SFSafariViewController?
    private var verificationCompletion: ((Result<IDmeUserProfile, Error>) -> Void)?
    
    // MARK: - Token Management
    private var accessToken: String? {
        get { KeychainHelper().loadString(forKey: "idme_access_token") }
        set { 
            if let token = newValue {
                KeychainHelper().save(token, forKey: "idme_access_token")
            } else {
                KeychainHelper().delete(forKey: "idme_access_token")
            }
        }
    }
    
    private var refreshToken: String? {
        get { KeychainHelper().loadString(forKey: "idme_refresh_token") }
        set { 
            if let token = newValue {
                KeychainHelper().save(token, forKey: "idme_refresh_token")
            } else {
                KeychainHelper().delete(forKey: "idme_refresh_token")
            }
        }
    }
    
    // MARK: - Public Methods
    func startVerification(
        from viewController: UIViewController,
        scope: String = IDmeConfig.basicScope,
        completion: @escaping (Result<IDmeUserProfile, Error>) -> Void
    ) {
        guard !isVerifying else {
            completion(.failure(IDmeError.verificationInProgress))
            return
        }
        
        isVerifying = true
        currentViewController = viewController
        verificationCompletion = completion
        
        // Generate authorization URL
        let authURL = buildAuthorizationURL(scope: scope)
        
        // Present Safari View Controller
        safariViewController = SFSafariViewController(url: authURL)
        safariViewController?.delegate = self
        
        viewController.present(safariViewController!, animated: true)
    }
    
    func handleRedirectURL(_ url: URL) -> Bool {
        // Handle both URL scheme and web callback
        if url.scheme == "brrowapp" {
            // Handle verification result from web callback
            if url.host == "verification" {
                if url.path == "/success" {
                    if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
                       let dataParam = queryItems.first(where: { $0.name == "data" })?.value,
                       let decodedData = Data(base64Encoded: dataParam),
                       let userData = try? JSONSerialization.jsonObject(with: decodedData) as? [String: Any] {
                        
                        // Process successful verification
                        handleVerificationSuccess(userData)
                        return true
                    }
                } else if url.path == "/error" {
                    let error = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                        .queryItems?.first(where: { $0.name == "error" })?.value ?? "Unknown error"
                    handleVerificationError(IDmeError.authorizationFailed(error))
                    return true
                }
            }
        }
        
        return false
    }
    
    func getUserProfile() async throws -> IDmeUserProfile {
        guard let token = accessToken else {
            throw IDmeError.noAccessToken
        }
        
        var request = URLRequest(url: URL(string: IDmeConfig.userInfoURL)!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw IDmeError.invalidResponse
        }
        
        let profile = try JSONDecoder().decode(IDmeUserProfile.self, from: data)
        
        await MainActor.run {
            self.userProfile = profile
            self.isVerified = profile.attributes.verified
        }
        
        return profile
    }
    
    func logout() {
        accessToken = nil
        refreshToken = nil
        userProfile = nil
        isVerified = false
    }
    
    // MARK: - Private Methods
    private func buildAuthorizationURL(scope: String) -> URL {
        var components = URLComponents(string: IDmeConfig.authURL)!

        // Build base query items without scope
        var queryItems = [
            URLQueryItem(name: "client_id", value: IDmeConfig.clientID),
            URLQueryItem(name: "redirect_uri", value: IDmeConfig.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "state", value: generateRandomState())
        ]

        // CRITICAL FIX: Only add scope if not empty
        // ID.me OAuth may not have scopes configured, causing invalid_scope error
        // Omitting scope parameter uses ID.me's default permissions
        if !scope.isEmpty {
            queryItems.append(URLQueryItem(name: "scope", value: scope))
        }

        components.queryItems = queryItems
        return components.url!
    }
    
    private func exchangeCodeForToken(_ code: String) {
        Task {
            do {
                var request = URLRequest(url: URL(string: IDmeConfig.tokenURL)!)
                request.httpMethod = "POST"
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                
                let body = [
                    "client_id": IDmeConfig.clientID,
                    "client_secret": IDmeConfig.clientSecret,
                    "redirect_uri": IDmeConfig.redirectURI,
                    "grant_type": "authorization_code",
                    "code": code
                ]
                
                request.httpBody = body.compactMap { key, value in
                    "\(key)=\(value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
                }.joined(separator: "&").data(using: .utf8)
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw IDmeError.tokenExchangeFailed
                }
                
                let tokenResponse = try JSONDecoder().decode(IDmeTokenResponse.self, from: data)
                
                await MainActor.run {
                    self.accessToken = tokenResponse.accessToken
                    self.refreshToken = tokenResponse.refreshToken
                }
                
                // Get user profile
                let profile = try await getUserProfile()
                
                await MainActor.run {
                    self.dismissSafariViewController()
                    self.verificationCompletion?(.success(profile))
                    self.cleanupVerification()
                }
                
            } catch {
                await MainActor.run {
                    self.handleVerificationError(error)
                }
            }
        }
    }
    
    private func handleVerificationSuccess(_ userData: [String: Any]) {
        Task {
            do {
                // Create IDmeUserProfile from web callback data
                let attributes = IDmeAttributes(
                    email: userData["email"] as? String,
                    firstName: userData["first_name"] as? String,
                    lastName: userData["last_name"] as? String,
                    birthDate: userData["birth_date"] as? String,
                    phone: userData["phone"] as? String,
                    zip: userData["zip"] as? String,
                    verified: userData["verified"] as? Bool ?? false,
                    verificationLevel: userData["verification_level"] as? String,
                    groups: userData["groups"] as? [String] ?? []
                )
                
                let profile = IDmeUserProfile(status: "success", attributes: attributes)
                
                // Update local state
                await MainActor.run {
                    self.userProfile = profile
                    self.isVerified = attributes.verified
                    
                    // Track achievement for completing identity verification
                    if attributes.verified {
                        AchievementManager.shared.trackIdentityVerified()
                    }
                    
                    self.dismissSafariViewController()
                    self.verificationCompletion?(.success(profile))
                    self.cleanupVerification()
                }
                
                // Update user profile via API
                try await updateUserProfileWithIDmeData(userData)
                
            } catch {
                await MainActor.run {
                    self.handleVerificationError(error)
                }
            }
        }
    }
    
    private func handleVerificationError(_ error: Error) {
        dismissSafariViewController()
        verificationCompletion?(.failure(error))
        cleanupVerification()
    }
    
    private func dismissSafariViewController() {
        safariViewController?.dismiss(animated: true)
        safariViewController = nil
    }
    
    private func cleanupVerification() {
        isVerifying = false
        currentViewController = nil
        verificationCompletion = nil
    }
    
    private func generateRandomState() -> String {
        return UUID().uuidString.replacingOccurrences(of: "-", with: "")
    }
    
    private func updateUserProfileWithIDmeData(_ userData: [String: Any]) async throws {
        guard let currentUser = AuthManager.shared.currentUser else {
            throw IDmeError.noAccessToken
        }
        
        let url = URL(string: "https://brrowapp.com/api_update_idme_verification.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(currentUser.apiId, forHTTPHeaderField: "X-User-API-ID")
        
        let payload: [String: Any] = [
            "email": userData["email"] as? String ?? "",
            "first_name": userData["first_name"] as? String,
            "last_name": userData["last_name"] as? String,
            "phone": userData["phone"] as? String,
            "zip": userData["zip"] as? String,
            "verified": userData["verified"] as? Bool ?? false,
            "verification_level": userData["verification_level"] as? String ?? "basic",
            "idme_profile": userData["idme_profile"] as? String
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw IDmeError.invalidResponse
        }
        
        // Parse response to update user data
        if let responseData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let userData = responseData["user"] as? [String: Any] {
            
            // Update AuthManager with new user data if needed
            await MainActor.run {
                print("✅ User profile updated with ID.me verification data")
                if let badges = userData["verification_badges"] as? [[String: Any]] {
                    print("🏆 Earned \(badges.count) verification badges")
                }
                if let usernameColor = userData["username_color"] as? String {
                    print("🎨 Username color set to: \(usernameColor)")
                }
            }
        }
    }
}

// MARK: - Safari View Controller Delegate
extension IDmeService: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        handleVerificationError(IDmeError.userCancelled)
    }
}

// MARK: - ID.me Errors
enum IDmeError: LocalizedError {
    case verificationInProgress
    case authorizationFailed(String)
    case noAuthorizationCode
    case tokenExchangeFailed
    case noAccessToken
    case invalidResponse
    case userCancelled
    
    var errorDescription: String? {
        switch self {
        case .verificationInProgress:
            return "Verification is already in progress"
        case .authorizationFailed(let reason):
            return "Authorization failed: \(reason)"
        case .noAuthorizationCode:
            return "No authorization code received"
        case .tokenExchangeFailed:
            return "Failed to exchange code for token"
        case .noAccessToken:
            return "No access token available"
        case .invalidResponse:
            return "Invalid response from ID.me"
        case .userCancelled:
            return "User cancelled verification"
        }
    }
}

