//
//  PredictiveLoadingManager.swift
//  Brrow
//
//  Advanced predictive loading system for lightning-fast user experience
//

import SwiftUI
import Foundation

@MainActor
class PredictiveLoadingManager: ObservableObject {
    static let shared = PredictiveLoadingManager()

    // MARK: - Cache Storage
    @Published private var userProfileCache: [String: User] = [:]
    @Published private var userListingsCache: [String: [Listing]] = [:]
    @Published private var conversationCache: [String: [Conversation]] = [:]
    @Published private var marketplaceCache: [String: [Listing]] = [:]

    // MARK: - Loading States
    @Published var isPredictiveLoading = false
    @Published var backgroundSyncProgress: Double = 0.0

    // MARK: - Configuration
    private let maxCacheSize = 100
    private let preloadDelay: TimeInterval = 0.5 // 500ms after user stops typing
    private var preloadTimer: Timer?

    private init() {}

    // MARK: - Username-based Predictive Loading

    /// Triggers predictive loading when user types in username/email fields
    func startPredictiveLoading(for input: String) {
        // Cancel previous timer
        preloadTimer?.invalidate()

        // Only preload if input is substantial enough
        guard input.count >= 3 else { return }

        // Debounce - wait for user to stop typing
        preloadTimer = Timer.scheduledTimer(withTimeInterval: preloadDelay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                await self?.executeUserPredictiveLoad(for: input)
            }
        }
    }

    private func executeUserPredictiveLoad(for input: String) async {
        isPredictiveLoading = true

        do {
            // 1. Pre-load user profile
            if let user = await preloadUserProfile(identifier: input) {
                print("🚀 Predictively loaded profile for: \(input)")

                // 2. Pre-load user's listings
                await preloadUserListings(userId: user.id)

                // 3. Pre-load conversation history if exists
                await preloadConversationHistory(with: user.id)
            }
        } catch {
            print("❌ Predictive loading failed: \(error)")
        }

        isPredictiveLoading = false
    }

    // MARK: - User Profile Preloading

    private func preloadUserProfile(identifier: String) async -> User? {
        // Check cache first
        if let cachedUser = userProfileCache[identifier] {
            return cachedUser
        }

        do {
            // Determine if input is email or username
            let isEmail = identifier.contains("@")
            let user: User

            if isEmail {
                user = try await getUserByEmail(identifier)
            } else {
                user = try await getUserByUsername(identifier)
            }

            // Cache the result
            userProfileCache[identifier] = user
            manageCacheSize()

            return user
        } catch {
            // Silently fail - this is predictive, not critical
            return nil
        }
    }

    // MARK: - Listing Preloading

    private func preloadUserListings(userId: String) async {
        // Check cache first
        guard userListingsCache[userId] == nil else { return }

        do {
            let listings = try await getUserListings(userId: userId, limit: 20)
            userListingsCache[userId] = listings
            manageCacheSize()

            // Also preload listing images
            await preloadListingImages(listings)

            print("🚀 Predictively loaded \(listings.count) listings for user: \(userId)")
        } catch {
            // Silently fail
            print("⚠️ Failed to preload listings: \(error)")
        }
    }

    // MARK: - Conversation Preloading

    private func preloadConversationHistory(with userId: String) async {
        guard conversationCache[userId] == nil else { return }

        do {
            let conversations = try await getUserConversations()
            let userConversations = conversations.filter {
                $0.otherUser.id == userId
            }

            conversationCache[userId] = userConversations
            manageCacheSize()

            print("🚀 Predictively loaded conversation history with: \(userId)")
        } catch {
            // Silently fail
            print("⚠️ Failed to preload conversations: \(error)")
        }
    }

    // MARK: - Marketplace Predictive Loading

    /// Preload marketplace data based on user behavior patterns
    func preloadMarketplaceData(category: String? = nil, location: String? = nil) async {
        let cacheKey = "\(category ?? "all")_\(location ?? "all")"

        guard marketplaceCache[cacheKey] == nil else { return }

        do {
            let listings = try await getMarketplaceListings(
                category: category,
                location: location,
                limit: 50
            )

            marketplaceCache[cacheKey] = listings
            manageCacheSize()

            // Preload images for visible listings
            await preloadListingImages(Array(listings.prefix(10)))

            print("🚀 Predictively loaded marketplace data: \(cacheKey)")
        } catch {
            print("⚠️ Failed to preload marketplace: \(error)")
        }
    }

    // MARK: - Image Preloading

    private func preloadListingImages(_ listings: [Listing]) async {
        let imageURLs = listings.compactMap { listing in
            listing.imageUrls.first
        }.prefix(5) // Limit to first 5 to avoid overwhelming

        for imageURL in imageURLs {
            // Use URLSession to cache images
            Task.detached {
                do {
                    guard let url = URL(string: imageURL) else { return }
                    let (_, _) = try await URLSession.shared.data(from: url)
                    // Image is now cached by URLSession
                } catch {
                    // Silently fail
                }
            }
        }
    }

    // MARK: - Background Sync

    /// Performs background sync of critical data
    func startBackgroundSync() async {
        backgroundSyncProgress = 0.0

        let tasks = [
            syncUserProfile,
            syncFavorites,
            syncRecentMessages,
            syncUserListings,
            syncNotifications
        ]

        let totalTasks = Double(tasks.count)

        for (index, task) in tasks.enumerated() {
            await task()
            await MainActor.run {
                backgroundSyncProgress = Double(index + 1) / totalTasks
            }
        }

        print("✅ Background sync completed")
    }

    private func syncUserProfile() async {
        // Sync user profile data
        do {
            _ = try await APIClient.shared.fetchUserProfile()
        } catch {
            print("⚠️ Failed to sync user profile: \(error)")
        }
    }

    private func syncFavorites() async {
        // Sync user's favorite listings
        do {
            _ = try await getUserFavorites()
        } catch {
            print("⚠️ Failed to sync favorites: \(error)")
        }
    }

    private func syncRecentMessages() async {
        // Sync recent conversations
        do {
            _ = try await getUserConversations()
        } catch {
            print("⚠️ Failed to sync messages: \(error)")
        }
    }

    private func syncUserListings() async {
        // Sync user's own listings
        do {
            _ = try await getUserFavorites() // Placeholder for user's own listings
        } catch {
            print("⚠️ Failed to sync user listings: \(error)")
        }
    }

    private func syncNotifications() async {
        // Sync notifications
        do {
            _ = try await getUserNotifications()
        } catch {
            print("⚠️ Failed to sync notifications: \(error)")
        }
    }

    // MARK: - Cache Management

    private func manageCacheSize() {
        // Simple LRU-style cache management
        if userProfileCache.count > maxCacheSize {
            // Remove oldest entries (simplified)
            let keysToRemove = Array(userProfileCache.keys.prefix(maxCacheSize / 4))
            keysToRemove.forEach { userProfileCache.removeValue(forKey: $0) }
        }

        if userListingsCache.count > maxCacheSize {
            let keysToRemove = Array(userListingsCache.keys.prefix(maxCacheSize / 4))
            keysToRemove.forEach { userListingsCache.removeValue(forKey: $0) }
        }

        if marketplaceCache.count > maxCacheSize {
            let keysToRemove = Array(marketplaceCache.keys.prefix(maxCacheSize / 4))
            keysToRemove.forEach { marketplaceCache.removeValue(forKey: $0) }
        }
    }

    // MARK: - Smart Navigation Prediction

    /// Predict and preload data for likely next screens
    func predictNextNavigation(from currentView: String, userBehavior: [String: Any]? = nil) async {
        switch currentView {
        case "marketplace":
            // User browsing marketplace - preload listing details for top items
            await preloadTopListingDetails()

        case "listing_detail":
            // User viewing listing - preload seller profile and related listings
            if let listingId = userBehavior?["listingId"] as? String {
                await preloadRelatedContent(for: listingId)
            }

        case "profile":
            // User viewing profile - preload their listings and conversations
            await preloadUserOwnedContent()

        default:
            break
        }
    }

    private func preloadTopListingDetails() async {
        // Get currently cached marketplace listings and preload details for top 3
        let allListings = marketplaceCache.values.flatMap { $0 }
        let topListings = Array(allListings.prefix(3))

        for listing in topListings {
            // Preload full listing details
            Task.detached {
                do {
                    _ = try await APIClient.shared.fetchListingDetails(id: Int(listing.id) ?? 0)
                } catch {
                    // Silently fail
                }
            }
        }
    }

    private func preloadRelatedContent(for listingId: String) async {
        // Preload seller profile and related listings
        Task.detached {
            do {
                let listing = try await APIClient.shared.fetchListingDetailsByListingId(listingId)
                // Preload seller's other listings
                _ = try await APIClient.shared.fetchUserListings(userId: Int(listing.userId) ?? 0)
            } catch {
                // Silently fail
            }
        }
    }

    private func preloadUserOwnedContent() async {
        // Preload user's listings and conversations
        await syncUserListings()
        await syncRecentMessages()
    }

    // MARK: - Cache Getters

    func getCachedUserProfile(identifier: String) -> User? {
        return userProfileCache[identifier]
    }

    func getCachedUserListings(userId: String) -> [Listing]? {
        return userListingsCache[userId]
    }

    func getCachedMarketplaceData(category: String? = nil, location: String? = nil) -> [Listing]? {
        let cacheKey = "\(category ?? "all")_\(location ?? "all")"
        return marketplaceCache[cacheKey]
    }

    // MARK: - Performance Metrics

    func getPerformanceMetrics() -> [String: Any] {
        return [
            "cached_profiles": userProfileCache.count,
            "cached_listings": userListingsCache.count,
            "cached_marketplace": marketplaceCache.count,
            "cached_conversations": conversationCache.count,
            "is_predictive_loading": isPredictiveLoading,
            "background_sync_progress": backgroundSyncProgress
        ]
    }

    // MARK: - Clear Cache

    func clearAllCaches() {
        userProfileCache.removeAll()
        userListingsCache.removeAll()
        conversationCache.removeAll()
        marketplaceCache.removeAll()
        print("🧹 All caches cleared")
    }

    // MARK: - Private Helper Methods for API Calls

    private func getUserByEmail(_ email: String) async throws -> User {
        // Use existing fetchUserProfile method with email parameter
        return try await APIClient.shared.fetchUserProfile(username: email)
    }

    private func getUserByUsername(_ username: String) async throws -> User {
        // Use existing fetchUserProfile method
        return try await APIClient.shared.fetchUserProfile(username: username)
    }

    private func getUserListings(userId: String, limit: Int) async throws -> [Listing] {
        // Use existing fetchUserListings method
        return try await APIClient.shared.fetchUserListings(userId: Int(userId) ?? 0)
    }

    private func getMarketplaceListings(category: String? = nil, location: String? = nil, limit: Int) async throws -> [Listing] {
        // Use existing listings method (placeholder implementation)
        return []
    }

    private func getUserFavorites() async throws -> [Listing] {
        // Placeholder - use existing favorites method when available
        return []
    }

    private func getUserNotifications() async throws -> [AppNotification] {
        // Use existing getNotifications method
        let (notifications, _) = try await APIClient.shared.getNotifications(limit: 20)
        return notifications
    }

    private func getUserConversations() async throws -> [Conversation] {
        // Placeholder - implement when conversations API is ready
        return []
    }
}