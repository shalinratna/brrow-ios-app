//
//  AuthManager.swift
//  Brrow
//
//  Created by Shalin Ratna on 7/16/25.
//

import Foundation
import Combine
import Security
import UIKit
// import OneSignalFramework // Temporarily disabled - install via Xcode

// MARK: - Authentication Manager
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var authToken: String?
    @Published var isValidatingToken = false
    
    private let keychain = KeychainHelper()
    private var cancellables = Set<AnyCancellable>()
    
    // Keychain Keys
    private let tokenKey = "brrow_auth_token"
    private let userKey = "brrow_user_data"
    private let sessionKey = "brrow_session_id"
    
    // Session Management
    @Published var sessionId: String = UUID().uuidString
    
    private init() {
        print("🎯 AuthManager.init() called")
        
        // Load stored authentication data
        loadStoredAuth()
        
        // Defer session tracking and monitoring to avoid early initialization issues
        DispatchQueue.main.async { [weak self] in
            self?.setupSessionTracking()
            self?.startTokenExpirationMonitoring()
            
            // Only perform background validation if we have auth data and user is authenticated
            if let self = self,
               self.authToken != nil,
               self.currentUser != nil,
               self.isAuthenticated {
                print("🔐 Starting background token validation")
                Task {
                    // Add a delay to avoid race conditions during login
                    try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 second delay
                    await self.validateStoredToken()
                }
            } else if self?.authToken != nil && self?.currentUser != nil {
                // We have stored data but user is not authenticated (expired token, etc.)
                print("🔐 Stored auth data found but not authenticated - user needs to login")
            } else {
                print("🔐 No stored auth data - user needs to login")
            }
        }
    }
    
    // MARK: - Authentication Methods
    func login(email: String, password: String) -> AnyPublisher<Bool, BrrowAPIError> {
        print("🔐 AuthManager: Starting login for \(email)")
        return APIClient.shared.login(email: email, password: password)
            .handleEvents(
                receiveOutput: { [weak self] authResponse in
                    print("🔐 AuthManager: Received auth response")
                    print("🔐 AuthManager: Token = \(authResponse.authToken ?? "nil")")
                    print("🔐 AuthManager: User = \(authResponse.user.username)")
                    self?.handleAuthSuccess(authResponse)
                },
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ AuthManager: Login failed - \(error)")
                    }
                }
            )
            .map { _ in true }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func register(email: String, username: String, password: String, firstName: String, lastName: String, birthdate: Date) async throws -> User {
        let birthdateString = ISO8601DateFormatter().string(from: birthdate)
        return try await registerWithAPI(username: username, email: email, password: password, firstName: firstName, lastName: lastName, birthdate: birthdateString)
    }
    
    private func registerWithAPI(username: String, email: String, password: String, firstName: String, lastName: String, birthdate: String) async throws -> User {
        // Call the actual API
        let response = try await APIClient.shared.register(
            username: username,
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName,
            birthdate: birthdate
        )
        
        handleAuthSuccess(response)
        
        return response.user
    }
    
    func register_legacy(username: String, email: String, password: String, birthdate: String) -> AnyPublisher<Bool, BrrowAPIError> {
        return APIClient.shared.register(username: username, email: email, password: password, birthdate: birthdate)
            .handleEvents(receiveOutput: { [weak self] authResponse in
                self?.handleAuthSuccess(authResponse)
            })
            .map { _ in true }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Guest Browsing
    func loginAsGuest() {
        print("🔐 AuthManager: Logging in as guest")
        
        // Create a guest user object
        let guestUser = User(
            id: "0",
            username: "Guest",
            email: "guest@brrowapp.com",
            apiId: "guest_\(UUID().uuidString)",
            profilePicture: nil,
            listerRating: 0.0,
            renteeRating: 0.0,
            bio: "Browsing as guest",
            emailVerified: false,
            idVerified: false,
            stripeLinked: false
        )
        
        // Set guest state
        self.currentUser = guestUser
        self.authToken = nil // No token for guests
        self.isAuthenticated = true // Allow navigation but with restrictions
        
        // Track guest session
        sessionId = "guest_session_\(UUID().uuidString)"
        
        // Set marketplace as default tab for guests
        DispatchQueue.main.async {
            TabSelectionManager.shared.selectedTab = 1
        }
        
        print("✅ Guest login successful")
    }
    
    var isGuestUser: Bool {
        return currentUser?.apiId?.starts(with: "guest_") ?? false
    }
    
    func refreshUserProfile() async {
        guard let token = authToken else { return }
        
        do {
            // Fetch fresh user profile from server
            let freshUser = try await APIClient.shared.fetchProfile()
            
            // Update stored user data
            DispatchQueue.main.async {
                self.currentUser = freshUser
            }
            
            // Update keychain with fresh user data
            if let userData = try? JSONEncoder().encode(freshUser) {
                keychain.save(userData, forKey: userKey)
            }
            
            print("✅ User profile refreshed successfully")
        } catch {
            print("❌ Failed to refresh user profile: \(error)")
        }
    }
    
    func logout() {
        // Clear keychain
        keychain.delete(forKey: tokenKey)
        keychain.delete(forKey: userKey)
        keychain.delete(forKey: sessionKey)
        
        // Clear published properties
        DispatchQueue.main.async {
            self.isAuthenticated = false
            self.currentUser = nil
            self.authToken = nil
            self.sessionId = UUID().uuidString

            // Clear favorites
            FavoritesManager.shared.clearAll()

            // Logout from OneSignal
            // OneSignal.logout()
            print("📱 OneSignal user will be logged out")
        }
        
        // Logout from Google Sign-In
        GoogleAuthService.shared.signOut()
        
        // Reset token manager
        TokenManager.shared.resetRefreshAttempts()
        
        // Track logout event
        trackAuthEvent("logout")
    }
    
    // updateToken method already exists below, removing duplicate
    
    func updateUser(_ user: User) {
        currentUser = user
        
        // Save to keychain
        if let userData = try? JSONEncoder().encode(user) {
            keychain.save(String(data: userData, encoding: .utf8) ?? "", forKey: userKey)
        }
    }
    
    func refreshToken() -> AnyPublisher<Bool, BrrowAPIError> {
        guard let token = authToken else {
            return Fail(error: BrrowAPIError.unauthorized)
                .eraseToAnyPublisher()
        }
        
        // Check if token is expired or about to expire
        if let expirationDate = getTokenExpirationDate(from: token) {
            let timeUntilExpiry = expirationDate.timeIntervalSinceNow
            
            // If token expires in more than 24 hours, no need to refresh
            if timeUntilExpiry > 86400 { // 24 hours
                return Just(true)
                    .setFailureType(to: BrrowAPIError.self)
                    .eraseToAnyPublisher()
            }
        }
        
        // Use the new refresh endpoint
        return Future<Bool, BrrowAPIError> { [weak self] promise in
            Task {
                guard let self = self else {
                    promise(.failure(BrrowAPIError.networkError("AuthManager deallocated")))
                    return
                }
                
                do {
                    // Make a direct API call to refresh token
                    let baseURL = await APIClient.shared.getBaseURL()
                    guard let url = URL(string: "\(baseURL)/api/auth/refresh-token") else {
                        promise(.failure(.networkError("Invalid URL")))
                        return
                    }
                    
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    if let currentToken = self.authToken {
                        request.setValue("Bearer \(currentToken)", forHTTPHeaderField: "Authorization")
                    }
                    
                    let (data, response) = try await URLSession.shared.data(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode == 200 else {
                        promise(.failure(.unauthorized))
                        return
                    }
                    
                    struct TokenRefreshResponse: Codable {
                        let success: Bool
                        let data: TokenData?
                        
                        struct TokenData: Codable {
                            let token: String
                            let expires_at: String
                        }
                    }
                    
                    let refreshResponse = try JSONDecoder().decode(TokenRefreshResponse.self, from: data)
                    
                    if refreshResponse.success, let tokenData = refreshResponse.data {
                        self.updateToken(tokenData.token)
                        promise(.success(true))
                    } else {
                        promise(.failure(.unauthorized))
                    }
                } catch {
                    if let apiError = error as? BrrowAPIError {
                        promise(.failure(apiError))
                    } else {
                        promise(.failure(.networkError(error.localizedDescription)))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
    
    // MARK: - Token Management
    func updateToken(_ newToken: String) {
        authToken = newToken
        keychain.save(newToken, forKey: tokenKey)
        isAuthenticated = true
        print("🔐 Token updated and saved to keychain")
        
        // Reset token manager on successful update
        TokenManager.shared.resetRefreshAttempts()
    }
    
    private func startTokenExpirationMonitoring() {
        // Check token expiration every hour
        Timer.publish(every: 3600, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkTokenExpiration()
            }
            .store(in: &cancellables)
        
        // Also check on app foreground
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.checkTokenExpiration()
            }
            .store(in: &cancellables)
    }
    
    private func checkTokenExpiration() {
        guard let token = authToken,
              let expirationDate = getTokenExpirationDate(from: token) else {
            return
        }
        
        let timeUntilExpiry = expirationDate.timeIntervalSinceNow
        let hoursUntilExpiry = timeUntilExpiry / 3600
        
        // If token expires in less than 24 hours, refresh it proactively
        if hoursUntilExpiry < 24 && hoursUntilExpiry > 0 {
            print("🔐 Token expires in \(Int(hoursUntilExpiry)) hours, refreshing proactively")
            refreshToken()
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            print("🔐 Proactive token refresh failed: \(error)")
                        }
                    },
                    receiveValue: { success in
                        if success {
                            print("🔐 Proactive token refresh successful")
                        }
                    }
                )
                .store(in: &cancellables)
        }
        // If token is already expired, logout
        else if timeUntilExpiry <= 0 {
            print("🔐 Token has expired, logging out")
            logout()
        }
    }
    
    private func getTokenExpirationDate(from token: String) -> Date? {
        // Handle test tokens that start with "test_token_"
        if token.hasPrefix("test_token_") {
            // For test tokens, assume they expire in 24 hours from now
            return Date().addingTimeInterval(86400)
        }
        
        // Parse JWT token to get expiration
        let segments = token.components(separatedBy: ".")
        guard segments.count == 3 else { 
            print("🔐 Token does not have 3 segments (not a JWT)")
            return nil 
        }
        
        // Decode payload
        var base64String = segments[1]
        let remainder = base64String.count % 4
        if remainder > 0 {
            base64String += String(repeating: "=", count: 4 - remainder)
        }
        
        guard let payloadData = Data(base64Encoded: base64String) else {
            print("🔐 Failed to decode base64 payload")
            return nil
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: payloadData, options: []),
              let payload = json as? [String: Any] else {
            print("🔐 Failed to parse JSON payload")
            return nil
        }
        
        guard let exp = payload["exp"] as? TimeInterval else {
            print("🔐 No exp field in token payload")
            return nil
        }
        
        return Date(timeIntervalSince1970: exp)
    }
    
    // MARK: - Auth Success Handler
    func handleAuthSuccess(_ authResponse: AuthResponse) {
        print("🔐 handleAuthSuccess called")
        print("🔐 Token to save: \(authResponse.authToken ?? "nil")")
        print("🔐 User to save: \(authResponse.user.username) (API ID: \(authResponse.user.apiId ?? "NIL!"))")
        print("🔐 User ID: \(authResponse.user.id)")
        print("🔐 User email: \(authResponse.user.email)")
        print("🖼️ User profile picture (raw): \(authResponse.user.profilePicture ?? "nil")")
        print("🖼️ User profile picture (computed URL): \(authResponse.user.fullProfilePictureURL ?? "nil")")

        // Critical check: ensure apiId is not nil
        if authResponse.user.apiId == nil {
            print("❌ CRITICAL: User apiId is nil! This will cause API failures.")
            print("🔍 Full user object: \(authResponse.user)")
        }
        
        // Store in keychain FIRST before updating published properties
        if let token = authResponse.authToken {
            print("🔐 Saving token to keychain...")
            keychain.save(token, forKey: tokenKey)
            print("✅ Token saved to keychain")
            
            // Update authToken immediately on current thread
            self.authToken = token
            print("✅ authToken property updated immediately")
        } else {
            print("❌ No token to save!")
        }
        
        if let userData = try? JSONEncoder().encode(authResponse.user) {
            let userDataString = String(data: userData, encoding: .utf8) ?? ""
            print("🔐 Saving user data to keychain...")
            keychain.save(userDataString, forKey: userKey)
            print("✅ User data saved to keychain")
            
            // Update currentUser immediately
            self.currentUser = authResponse.user
            print("✅ currentUser property updated immediately")
        } else {
            print("❌ Failed to encode user data!")
        }
        
        keychain.save(sessionId, forKey: sessionKey)
        print("✅ Session ID saved: \(sessionId)")
        
        // Update isAuthenticated on main thread for UI updates
        if Thread.isMainThread {
            print("🔐 Already on main thread, updating isAuthenticated")
            self.isAuthenticated = true

            // Set OneSignal external user ID for push notifications
            // OneSignal.login(authResponse.user.apiId)
            print("📱 OneSignal user ID will be set: \(authResponse.user.apiId)")

            // Track achievement for daily login
            AchievementManager.shared.trackDailyLogin()

            // Load favorites after successful login
            Task {
                await FavoritesManager.shared.loadFavorites()
            }

            // Update language preference if provided
            if let preferredLanguage = authResponse.user.preferredLanguage,
               let language = LocalizationManager.Language(rawValue: preferredLanguage) {
                LocalizationManager.shared.currentLanguage = language
            }
        } else {
            DispatchQueue.main.async {
                print("🔐 Updating isAuthenticated on main thread...")
                self.isAuthenticated = true
                print("✅ Auth state updated: isAuthenticated = \(self.isAuthenticated)")

                // Set OneSignal external user ID for push notifications
                // OneSignal.login(authResponse.user.apiId)
                print("📱 OneSignal user ID will be set: \(authResponse.user.apiId)")

                // Track achievement for daily login
                AchievementManager.shared.trackDailyLogin()

                // Load favorites after successful login
                Task {
                    await FavoritesManager.shared.loadFavorites()
                }

                // Update language preference if provided
                if let preferredLanguage = authResponse.user.preferredLanguage,
                   let language = LocalizationManager.Language(rawValue: preferredLanguage) {
                    LocalizationManager.shared.currentLanguage = language
                }
            }
        }
        
        // Verify the values are set
        print("🔔 Final auth state check:")
        print("  - authToken: \(self.authToken.map { "Set (\(String($0.prefix(20)))...)" } ?? "nil")")
        print("  - currentUser: \(self.currentUser?.username ?? "nil")")
        print("  - isAuthenticated: \(self.isAuthenticated)")
        
        // Track login event
        trackAuthEvent("login")
        print("🎉 handleAuthSuccess completed")
    }
    
    private func loadStoredAuth() {
        print("🔔 loadStoredAuth called")
        
        authToken = keychain.loadString(forKey: tokenKey)
        if let token = authToken {
            print("🔔 Loaded token from keychain: Found (\(String(token.prefix(20)))...)")
        } else {
            print("🔔 Loaded token from keychain: Not found")
        }
        
        if let userDataString = keychain.loadString(forKey: userKey),
           let userData = userDataString.data(using: .utf8),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            currentUser = user
            print("🔔 Loaded user from keychain: \(user.username) (API ID: \(user.apiId))")
        } else {
            print("🔔 No user data found in keychain")
        }
        
        if let storedSessionId = keychain.loadString(forKey: sessionKey) {
            sessionId = storedSessionId
            print("🔔 Loaded session ID: \(sessionId)")
        }
        
        // If we have a token but no user, clear everything (corrupted state)
        if authToken != nil && currentUser == nil {
            print("🔐 Corrupted auth state - token without user, clearing")
            // Clear the authentication state but don't call logout() during init
            authToken = nil
            currentUser = nil
            isAuthenticated = false
            
            // Clear keychain data directly without calling logout()
            keychain.delete(forKey: tokenKey)
            keychain.delete(forKey: userKey)
            keychain.delete(forKey: sessionKey)
            return
        }
        
        // If we have both token and user, check token validity
        if let token = authToken, let _ = currentUser {
            // Check token expiration first
            if let expirationDate = getTokenExpirationDate(from: token) {
                if expirationDate < Date() {
                    // Token is expired, clear auth - but defer the logout to avoid initialization issues
                    print("🔐 Auth token expired locally, will clear auth after initialization")
                    // Clear the authentication state but don't call logout() during init
                    authToken = nil
                    currentUser = nil
                    isAuthenticated = false
                    
                    // Clear keychain data directly without calling logout()
                    keychain.delete(forKey: tokenKey)
                    keychain.delete(forKey: userKey)
                    keychain.delete(forKey: sessionKey)
                    
                    return
                } else {
                    let timeUntilExpiry = expirationDate.timeIntervalSinceNow
                    print("🔐 Auth token valid for \(Int(timeUntilExpiry / 3600)) hours")
                    
                    // Token is not expired - optimistically set as authenticated
                    isAuthenticated = true
                    print("🔐 Auto-login successful - user authenticated from stored token")
                    return
                }
            } else {
                // Could not parse token expiration - treat as valid for now
                print("🔐 Could not parse token expiration - optimistically authenticating")
                isAuthenticated = true
                return
            }
        }
        
        // No stored auth or invalid state
        print("🔐 No valid stored authentication found")
        isAuthenticated = false
    }
    
    private func validateStoredToken() async {
        guard let token = authToken, let user = currentUser else {
            print("🔐 Background validation: No token or user data")
            return
        }
        
        // Don't change authentication state during background validation
        // The user is already authenticated from loadStoredAuth()
        print("🔐 Background validation: User already authenticated, performing server check")
        
        // Check if token is expired before making network request
        if let expirationDate = getTokenExpirationDate(from: token) {
            if expirationDate < Date() {
                print("🔐 Background validation: Token expired locally, attempting refresh")
                // Try to refresh token before logging out
                refreshToken()
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(_) = completion {
                                DispatchQueue.main.async {
                                    print("🔐 Background validation: Token refresh failed - logging out")
                                    self.logout()
                                }
                            }
                        },
                        receiveValue: { success in
                            if success {
                                print("🔐 Background validation: Token refreshed successfully")
                            }
                        }
                    )
                    .store(in: &cancellables)
                return
            }
        }
        
        // Optional: Perform background validation without aggressive logout
        Task<Void, Never> {
            do {
                let baseURL = await APIClient.shared.getBaseURL()
                guard let url = URL(string: "\(baseURL)/api/users/me") else {
                    return // Don't logout on URL construction failure
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                request.setValue(user.apiId, forHTTPHeaderField: "X-User-API-ID")
                request.timeoutInterval = 20.0 // Timeout for background validation (increased for Railway latency)
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("🔐 Background token validation - invalid response, but keeping user logged in")
                    return
                }
                
                if httpResponse.statusCode == 200 {
                    // Parse the profile response and update user data
                    struct ProfileAPIResponse: Codable {
                        let success: Bool
                        let data: ProfileData?
                        
                        struct ProfileData: Codable {
                            let id: Int
                            let api_id: String
                            let username: String
                            let email: String?
                            let profile_picture: String?
                            let bio: String
                            let lister_rating: Double
                            let rentee_rating: Double
                            let stats: ProfileStats
                            
                            struct ProfileStats: Codable {
                                let rating: Double
                                let reviews: Int
                            }
                        }
                    }
                    
                    if let profileResponse = try? JSONDecoder().decode(ProfileAPIResponse.self, from: data),
                       profileResponse.success, let profileData = profileResponse.data {
                        // Update user with real data from server
                        let updatedUser = User(
                            id: String(profileData.id),  // Convert Int to String
                            username: profileData.username,
                            email: profileData.email ?? user.email,
                            apiId: profileData.api_id,
                            profilePicture: profileData.profile_picture,
                            listerRating: Float(profileData.lister_rating),
                            renteeRating: Float(profileData.rentee_rating),
                            bio: profileData.bio,
                            emailVerified: user.emailVerified ?? false,
                            idVerified: user.idVerified ?? false,
                            stripeLinked: user.stripeLinked ?? false
                        )
                        
                        DispatchQueue.main.async {
                            self.currentUser = updatedUser
                            print("🔐 Background token validation successful - user data updated")
                        }
                        
                        // Save updated user data
                        if let userData = try? JSONEncoder().encode(updatedUser) {
                            keychain.save(String(data: userData, encoding: .utf8) ?? "", forKey: userKey)
                        }
                    }
                } else if httpResponse.statusCode == 401 {
                    // Only logout on explicit 401 - token is definitely invalid
                    DispatchQueue.main.async {
                        print("🔐 Background validation returned 401 - token invalid, logging out")
                        self.logout()
                    }
                } else {
                    // Other status codes - don't logout, might be temporary server issues
                    print("🔐 Background token validation returned \(httpResponse.statusCode) - keeping user logged in")
                }
            } catch {
                // Network errors or other issues - don't logout, keep user authenticated
                print("🔐 Background token validation failed with error: \(error) - keeping user logged in")
            }
        }
    }
    
    func updateCurrentUserUsername(_ newUsername: String) {
        guard let user = currentUser else { return }

        // Create updated user with new username
        var updatedUserData = try? JSONEncoder().encode(user)
        if let data = updatedUserData,
           var userDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            userDict["username"] = newUsername

            if let updatedData = try? JSONSerialization.data(withJSONObject: userDict),
               let updatedUser = try? JSONDecoder().decode(User.self, from: updatedData) {
                // Update in memory
                self.currentUser = updatedUser

                // Update in keychain with the UPDATED user, not the old one
                if let userData = try? JSONEncoder().encode(updatedUser) {
                    keychain.save(String(data: userData, encoding: .utf8) ?? "", forKey: userKey)
                }
            }
        }

        print("✅ Username updated locally to: \(newUsername)")
    }

    private func setupSessionTracking() {
        // Track session start
        trackAuthEvent("session_start")
        
        // Setup app lifecycle observers
        NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.trackAuthEvent("session_end")
        }
    }
    
    #if DEBUG
    // Debug method for testing My Posts functionality
    func simulateLoginForTesting() {
        print("🧪 DEBUG: Simulating login for testing...")
        
        // Create mock user "mom" using the simpler initializer
        let mockUser = User(
            id: "9",
            username: "mom",
            email: "mom@brrowapp.com",
            apiId: "usr_687b4d8b25f075.49510878",
            profilePicture: nil,
            listerRating: 4.5,
            renteeRating: 4.8,
            bio: "Test user for debugging",
            emailVerified: true,
            idVerified: false,
            stripeLinked: false
        )
        
        // Set mock token
        let mockToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjo5LCJhcGlfaWQiOiJ1c3JfNjg3YjRkOGIyNWYwNzUuNDk1MTA4NzgiLCJlbWFpbCI6Im1vbUBicnJvd2FwcC5jb20iLCJleHAiOjE3NTQ2ODYyMzMsImlhdCI6MTc1NDA4MTQzM30.dJvhJcUWWXYxHGkJyJl4bvhqILIXxrOV3L89SqNBp8I"
        
        // Set authentication state
        self.currentUser = mockUser
        self.authToken = mockToken
        self.isAuthenticated = true
        
        // Store in keychain using shared instance
        let keychain = KeychainHelper()
        keychain.save(mockToken, forKey: "brrow_auth_token")
        if let userData = try? JSONEncoder().encode(mockUser) {
            keychain.save(userData, forKey: "brrow_user_data")
        }
        
        print("✅ DEBUG: Mock login successful - User: \(mockUser.username), API ID: \(mockUser.apiId)")
    }
    #endif
    
    private func trackAuthEvent(_ eventName: String) {
        let event = AnalyticsEvent(
            eventName: eventName,
            eventType: "auth",
            userId: currentUser?.apiId,
            sessionId: sessionId,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            metadata: [
                "platform": "ios",
                "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
            ]
        )
        
        // Send to Shaiitech Sentinel A7
        APIClient.shared.trackAnalytics(event: event)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }
}

// MARK: - Keychain Helper
class KeychainHelper {
    
    func save(_ value: String, forKey key: String) {
        print("🔑 KeychainHelper.save called for key: \(key)")
        print("🔑 Value length: \(value.count) characters")
        
        guard let data = value.data(using: .utf8) else {
            print("❌ Failed to convert string to data")
            return
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        let deleteStatus = SecItemDelete(query as CFDictionary)
        print("🔑 Delete status: \(deleteStatus) (\(deleteStatus == errSecSuccess ? "Success" : "Item not found or error"))")
        
        let addStatus = SecItemAdd(query as CFDictionary, nil)
        print("🔑 Add status: \(addStatus) (\(addStatus == errSecSuccess ? "Success" : "Failed"))")
        
        if addStatus != errSecSuccess {
            print("❌ Keychain save failed with error: \(addStatus)")
        } else {
            print("✅ Successfully saved to keychain")
        }
    }
    
    func save(_ data: Data, forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func loadString(forKey key: String) -> String? {
        print("🔓 KeychainHelper.loadString called for key: \(key)")
        guard let data = loadData(forKey: key) else {
            print("🔓 No data found for key: \(key)")
            return nil
        }
        let value = String(data: data, encoding: .utf8)
        print("🔓 Loaded value length: \(value?.count ?? 0) characters")
        return value
    }
    
    func loadData(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess {
            return dataTypeRef as? Data
        }
        
        return nil
    }
    
    func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
