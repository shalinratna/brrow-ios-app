//
//  TokenManager.swift
//  Brrow
//
//  Manages token refresh logic and prevents infinite loops
//

import Foundation

class TokenManager {
    static let shared = TokenManager()
    
    private var isRefreshingToken = false
    private var lastRefreshAttempt: Date?
    private let refreshCooldown: TimeInterval = 10.0 // 10 seconds between attempts
    private let maxRefreshAttempts = 3
    private var refreshAttemptCount = 0
    private var refreshCompletionHandlers: [(String?) -> Void] = []
    
    private init() {}
    
    /// Check if we should attempt a token refresh
    func shouldAttemptRefresh() -> Bool {
        // Check if already refreshing
        if isRefreshingToken {
            return false
        }
        
        // Check cooldown period
        if let lastAttempt = lastRefreshAttempt,
           Date().timeIntervalSince(lastAttempt) < refreshCooldown {
            print("🔐 Token refresh on cooldown, skipping")
            return false
        }
        
        // Check max attempts
        if refreshAttemptCount >= maxRefreshAttempts {
            print("🔐 Max token refresh attempts reached")
            return false
        }
        
        return true
    }
    
    /// Attempt to refresh the token with proper synchronization
    func refreshToken() async -> String? {
        // If already refreshing, wait for the result
        if isRefreshingToken {
            return await withCheckedContinuation { continuation in
                refreshCompletionHandlers.append { token in
                    continuation.resume(returning: token)
                }
            }
        }
        
        // Check if we should attempt refresh
        guard shouldAttemptRefresh() else {
            return nil
        }
        
        // Mark as refreshing
        isRefreshingToken = true
        lastRefreshAttempt = Date()
        refreshAttemptCount += 1
        
        do {
            // Perform the actual refresh
            let newToken = try await performTokenRefresh()
            
            // Success - reset attempt count
            refreshAttemptCount = 0
            isRefreshingToken = false
            
            // Notify all waiting handlers
            refreshCompletionHandlers.forEach { $0(newToken) }
            refreshCompletionHandlers.removeAll()
            
            return newToken
            
        } catch {
            print("🔐 Token refresh failed: \(error)")
            isRefreshingToken = false
            
            // If refresh fails, clear all auth to prevent loops
            if error is TokenRefreshError {
                await MainActor.run {
                    AuthManager.shared.logout()
                }
            }
            
            // Notify all waiting handlers
            refreshCompletionHandlers.forEach { $0(nil) }
            refreshCompletionHandlers.removeAll()
            
            return nil
        }
    }
    
    /// Reset refresh attempts (call after successful login)
    func resetRefreshAttempts() {
        refreshAttemptCount = 0
        lastRefreshAttempt = nil
        isRefreshingToken = false
        refreshCompletionHandlers.removeAll()
    }
    
    private func performTokenRefresh() async throws -> String {
        guard let currentToken = AuthManager.shared.authToken else {
            throw TokenRefreshError.noToken
        }
        
        let baseURL = APIClient.shared.baseURL
        guard let url = URL(string: "\(baseURL)/refresh_token.php") else {
            throw TokenRefreshError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(currentToken)", forHTTPHeaderField: "Authorization")
        
        if let user = AuthManager.shared.currentUser {
            request.setValue(user.apiId, forHTTPHeaderField: "X-User-API-ID")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TokenRefreshError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 {
            // Refresh token is invalid
            throw TokenRefreshError.invalidToken
        }
        
        guard httpResponse.statusCode == 200 else {
            throw TokenRefreshError.serverError(httpResponse.statusCode)
        }
        
        struct TokenRefreshResponse: Codable {
            let success: Bool
            let data: TokenData?
            let message: String?
            
            struct TokenData: Codable {
                let token: String
                let expiresAt: String
                let user: User
                
                struct User: Codable {
                    let id: Int
                    let apiId: String
                    let username: String
                    let email: String
                    
                    private enum CodingKeys: String, CodingKey {
                        case id
                        case apiId = "api_id"
                        case username
                        case email
                    }
                }
                
                private enum CodingKeys: String, CodingKey {
                    case token
                    case expiresAt = "expires_at"
                    case user
                }
            }
        }
        
        let refreshResponse = try JSONDecoder().decode(TokenRefreshResponse.self, from: data)
        
        guard refreshResponse.success, let tokenData = refreshResponse.data else {
            throw TokenRefreshError.apiError(refreshResponse.message ?? "Token refresh failed")
        }
        
        // Update stored token
        await MainActor.run {
            AuthManager.shared.authToken = tokenData.token
            // Save to keychain with correct key
            let keychain = KeychainHelper()
            keychain.save(tokenData.token, forKey: "brrow_auth_token")
            AuthManager.shared.isAuthenticated = true
            
            // Reset token manager on successful update
            TokenManager.shared.resetRefreshAttempts()
        }
        
        return tokenData.token
    }
}

enum TokenRefreshError: Error {
    case noToken
    case invalidURL
    case invalidResponse
    case invalidToken
    case serverError(Int)
    case apiError(String)
}