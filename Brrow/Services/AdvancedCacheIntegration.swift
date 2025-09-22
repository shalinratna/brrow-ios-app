//
//  AdvancedCacheIntegration.swift
//  Brrow
//
//  Integration layer for advanced cache management with existing services
//

import Foundation
import Combine

class AdvancedCacheIntegration: ObservableObject {
    static let shared = AdvancedCacheIntegration()

    let isolationManager = AdvancedUserIsolationManager.shared
    private let authManager = AuthManager.shared
    private let apiClient = APIClient.shared

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Auto User Context Management
    init() {
        setupUserContextTracking()
    }

    private func setupUserContextTracking() {
        // Automatically establish user context when user signs in
        authManager.$currentUser
            .compactMap { $0 }
            .sink { [weak self] user in
                self?.isolationManager.establishUserContext(userId: user.id)
                self?.preloadUserCriticalData(for: user)
            }
            .store(in: &cancellables)

        // Clear context when user signs out
        authManager.$isAuthenticated
            .filter { !$0 }
            .sink { [weak self] _ in
                self?.isolationManager.invalidateUserContext()
                self?.clearUserSpecificData()
            }
            .store(in: &cancellables)
    }

    // MARK: - Smart Data Management
    func cacheUserListings(_ listings: [Listing]) {
        isolationManager.store(
            listings,
            category: .userListings,
            key: "user_listings",
            userSpecific: true
        )
    }

    func getCachedUserListings() -> [Listing]? {
        return isolationManager.retrieve(
            [Listing].self,
            category: .userListings,
            key: "user_listings",
            userSpecific: true
        )
    }

    func cacheGlobalListings(_ listings: [Listing]) {
        isolationManager.store(
            listings,
            category: .globalListings,
            key: "global_listings",
            userSpecific: false
        )
    }

    func getCachedGlobalListings() -> [Listing]? {
        return isolationManager.retrieve(
            [Listing].self,
            category: .globalListings,
            key: "global_listings",
            userSpecific: false
        )
    }

    func cacheUserProfile(_ user: User) {
        isolationManager.store(
            user,
            category: .userProfile,
            key: "user_profile",
            userSpecific: true
        )
    }

    func getCachedUserProfile() -> User? {
        return isolationManager.retrieve(
            User.self,
            category: .userProfile,
            key: "user_profile",
            userSpecific: true
        )
    }

    func cacheUserFavorites(_ favorites: [String]) {
        isolationManager.store(
            favorites,
            category: .userFavorites,
            key: "user_favorites",
            userSpecific: true
        )
    }

    func getCachedUserFavorites() -> [String]? {
        return isolationManager.retrieve(
            [String].self,
            category: .userFavorites,
            key: "user_favorites",
            userSpecific: true
        )
    }

    // MARK: - Data Preloading
    private func preloadUserCriticalData(for user: User) {
        Task {
            // Preload user's listings
            if let response = try? await apiClient.fetchUserListings(userId: user.id),
               let listings = response.data?.listings {
                cacheUserListings(listings)
            }

            // Preload user's favorites
            if let favoritesResponse = try? await apiClient.fetchFavorites(),
               let favorites = favoritesResponse.favorites?.map({ $0.id }) {
                cacheUserFavorites(favorites)
            }

            // Preload global data that's shared across users
            if let globalListings = try? await apiClient.fetchListings() {
                cacheGlobalListings(globalListings)
            }
        }
    }

    private func clearUserSpecificData() {
        // Clear only user-specific cached data
        // Global data like categories remains cached for next user
        print("🧹 Clearing user-specific cache data")
    }
}

// MARK: - APIClient Extensions for Cache Integration
extension APIClient {
    func fetchListingsWithCache() async throws -> [Listing] {
        let cacheIntegration = AdvancedCacheIntegration.shared

        // Try cache first
        if let cachedListings = cacheIntegration.getCachedGlobalListings() {
            print("📦 Serving listings from cache")
            return cachedListings
        }

        // Fetch from network and cache
        let listings = try await fetchListings()
        cacheIntegration.cacheGlobalListings(listings)
        return listings
    }

    func fetchUserListingsWithCache(userId: String) async throws -> [Listing] {
        let cacheIntegration = AdvancedCacheIntegration.shared

        // Try cache first for current user
        if let cachedListings = cacheIntegration.getCachedUserListings() {
            print("📦 Serving user listings from cache")
            return cachedListings
        }

        // Fetch from network and cache
        let response = try await fetchUserListings(userId: userId)
        let listings = response.data?.listings ?? []
        cacheIntegration.cacheUserListings(listings)
        return listings
    }

    func fetchProfileWithCache() async throws -> User {
        let cacheIntegration = AdvancedCacheIntegration.shared

        // Try cache first
        if let cachedProfile = cacheIntegration.getCachedUserProfile() {
            print("📦 Serving profile from cache")
            return cachedProfile
        }

        // Fetch from network and cache
        let profile = try await fetchProfile()
        cacheIntegration.cacheUserProfile(profile)
        return profile
    }
}

// MARK: - AuthManager Extensions for User Isolation
extension AuthManager {
    func signOutWithAdvancedCleanup() {
        // Clear user-specific cache before signing out
        AdvancedCacheIntegration.shared.isolationManager.invalidateUserContext()

        // Perform normal logout
        logout()

        print("🔐 Advanced user isolation cleanup completed")
    }

    func switchUserWithIsolation(newUser: User) {
        // Clear current user context
        AdvancedCacheIntegration.shared.isolationManager.invalidateUserContext()

        // Update current user
        updateUser(newUser)

        // Establish new user context
        AdvancedCacheIntegration.shared.isolationManager.establishUserContext(userId: newUser.id)

        print("🔄 User switched with complete isolation")
    }
}