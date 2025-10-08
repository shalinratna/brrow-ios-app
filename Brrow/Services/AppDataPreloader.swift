//
//  AppDataPreloader.swift
//  Brrow
//
//  Comprehensive data preloader that loads ALL critical app data immediately after launch
//  for the smoothest user experience. No more waiting for tabs to load!
//

import Foundation
import Combine
import SwiftUI

/// Comprehensive data preloader for instant app responsiveness
/// Loads all critical data in parallel as soon as the app launches
class AppDataPreloader: ObservableObject {
    static let shared = AppDataPreloader()

    // Published state for tracking preload progress
    @Published var isPreloadComplete = false
    @Published var preloadProgress: Double = 0.0
    @Published var currentlyPreloading: String = ""

    // Cached data ready for instant access
    @Published var marketplaceListings: [Listing] = []
    @Published var userListings: [Listing] = []
    @Published var conversations: [Conversation] = []
    @Published var favorites: [Listing] = []
    @Published var featuredListings: [Listing] = []
    @Published var garageSales: [GarageSale] = []
    @Published var categories: [APICategory] = []
    @Published var userProfile: User?
    @Published var userStats: APIUserStats?
    @Published var unreadCount: Int = 0

    private let apiClient = APIClient.shared
    private let authManager = AuthManager.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {}

    /// Main preload function - call this right after authentication
    /// Loads everything in parallel for maximum speed
    func preloadAllData() {
        guard authManager.isAuthenticated, !authManager.isGuestUser else {
            print("⚠️ [PRELOAD] User not authenticated or is guest, skipping preload")
            return
        }

        print("🚀 [PRELOAD] Starting comprehensive app data preload...")
        print("🚀 [PRELOAD] This will load ALL critical data in parallel for instant tab switching")

        Task {
            // Use TaskGroup to load everything in parallel
            await withTaskGroup(of: Void.self) { group in
                // 1. Marketplace listings (highest priority - most viewed)
                group.addTask {
                    await self.preloadMarketplaceListings()
                }

                // 2. User's own listings (for profile/home tab)
                group.addTask {
                    await self.preloadUserListings()
                }

                // 3. Conversations/messages
                group.addTask {
                    await self.preloadConversations()
                }

                // 4. User favorites
                group.addTask {
                    await self.preloadFavorites()
                }

                // 5. Featured listings (for home tab)
                group.addTask {
                    await self.preloadFeaturedListings()
                }

                // 6. Garage sales (for home tab map)
                group.addTask {
                    await self.preloadGarageSales()
                }

                // 7. Categories (for filters/search)
                group.addTask {
                    await self.preloadCategories()
                }

                // 8. User profile data
                group.addTask {
                    await self.preloadUserProfile()
                }

                // 9. User stats (for profile tab)
                group.addTask {
                    await self.preloadUserStats()
                }

                // 10. Unread message count
                group.addTask {
                    await self.preloadUnreadCount()
                }

                // Wait for all tasks to complete
                await group.waitForAll()
            }

            // After all data is loaded, preload images in background
            await self.preloadCriticalImages()

            await MainActor.run {
                self.isPreloadComplete = true
                self.preloadProgress = 1.0
                print("✅ [PRELOAD] Comprehensive preload complete!")
                print("✅ [PRELOAD] Summary:")
                print("   - Marketplace: \(self.marketplaceListings.count) listings")
                print("   - User listings: \(self.userListings.count) items")
                print("   - Conversations: \(self.conversations.count) chats")
                print("   - Favorites: \(self.favorites.count) saved")
                print("   - Featured: \(self.featuredListings.count) items")
                print("   - Garage Sales: \(self.garageSales.count) sales")
                print("   - Categories: \(self.categories.count) types")
                print("   - Unread: \(self.unreadCount) messages")
            }
        }
    }

    // MARK: - Individual Preload Functions

    private func preloadMarketplaceListings() async {
        await MainActor.run { currentlyPreloading = "Marketplace listings..." }
        do {
            let listings = try await apiClient.fetchListings()
            await MainActor.run {
                self.marketplaceListings = listings
                self.preloadProgress += 0.1
                print("✅ [PRELOAD] Marketplace: \(listings.count) listings")
            }
        } catch {
            print("❌ [PRELOAD] Marketplace failed: \(error.localizedDescription)")
        }
    }

    private func preloadUserListings() async {
        await MainActor.run { currentlyPreloading = "Your listings..." }
        guard let userId = authManager.currentUser?.apiId ?? authManager.currentUser?.id,
              let userIdInt = Int(userId) else {
            print("⚠️ [PRELOAD] No valid user ID for listings")
            return
        }

        do {
            let listings = try await apiClient.fetchUserListings(userId: userIdInt)
            await MainActor.run {
                self.userListings = listings
                self.preloadProgress += 0.1
                print("✅ [PRELOAD] User listings: \(listings.count) items")
            }
        } catch {
            print("❌ [PRELOAD] User listings failed: \(error.localizedDescription)")
        }
    }

    private func preloadConversations() async {
        await MainActor.run { currentlyPreloading = "Messages..." }
        do {
            let result = try await apiClient.fetchConversations(type: nil, limit: 50, offset: 0, search: nil, bypassCache: false)
            await MainActor.run {
                self.conversations = result.conversations
                self.preloadProgress += 0.1
                print("✅ [PRELOAD] Conversations: \(result.conversations.count) chats")
            }
        } catch {
            print("❌ [PRELOAD] Conversations failed: \(error.localizedDescription)")
        }
    }

    private func preloadFavorites() async {
        await MainActor.run { currentlyPreloading = "Favorites..." }
        do {
            let response = try await apiClient.fetchFavorites(limit: 50, offset: 0)
            await MainActor.run {
                self.favorites = response.favorites ?? []
                self.preloadProgress += 0.1
                print("✅ [PRELOAD] Favorites: \(response.favorites?.count ?? 0) items")
            }
        } catch {
            print("❌ [PRELOAD] Favorites failed: \(error.localizedDescription)")
        }
    }

    private func preloadFeaturedListings() async {
        await MainActor.run { currentlyPreloading = "Featured items..." }
        do {
            let response = try await apiClient.fetchFeaturedListings(category: nil, limit: 20, offset: 0)
            await MainActor.run {
                self.featuredListings = response.listings ?? []
                self.preloadProgress += 0.1
                print("✅ [PRELOAD] Featured: \(response.listings?.count ?? 0) items")
            }
        } catch {
            print("❌ [PRELOAD] Featured failed: \(error.localizedDescription)")
        }
    }

    private func preloadGarageSales() async {
        await MainActor.run { currentlyPreloading = "Garage sales..." }
        do {
            let garageSales = try await apiClient.fetchGarageSales(searchText: nil, radius: nil, location: nil)
            await MainActor.run {
                self.garageSales = garageSales
                self.preloadProgress += 0.1
                print("✅ [PRELOAD] Garage sales: \(garageSales.count) sales")
            }
        } catch {
            print("❌ [PRELOAD] Garage sales failed: \(error.localizedDescription)")
        }
    }

    private func preloadCategories() async {
        await MainActor.run { currentlyPreloading = "Categories..." }
        do {
            let categories = try await apiClient.fetchCategories()
            await MainActor.run {
                self.categories = categories
                self.preloadProgress += 0.1
                print("✅ [PRELOAD] Categories: \(categories.count) types")
            }
        } catch {
            print("❌ [PRELOAD] Categories failed: \(error.localizedDescription)")
        }
    }

    private func preloadUserProfile() async {
        await MainActor.run { currentlyPreloading = "Profile..." }
        do {
            let profile = try await apiClient.fetchProfile()
            await MainActor.run {
                self.userProfile = profile
                self.preloadProgress += 0.1
                print("✅ [PRELOAD] Profile loaded")
            }
        } catch {
            print("❌ [PRELOAD] Profile failed: \(error.localizedDescription)")
        }
    }

    private func preloadUserStats() async {
        await MainActor.run { currentlyPreloading = "Stats..." }
        do {
            let stats = try await apiClient.fetchUserStats()
            await MainActor.run {
                self.userStats = stats
                self.preloadProgress += 0.1
                print("✅ [PRELOAD] Stats loaded")
            }
        } catch {
            print("❌ [PRELOAD] Stats failed: \(error.localizedDescription)")
        }
    }

    private func preloadUnreadCount() async {
        await MainActor.run { currentlyPreloading = "Unread messages..." }
        do {
            let counts = try await apiClient.fetchUnreadCounts()
            await MainActor.run {
                self.unreadCount = counts.total
                self.preloadProgress += 0.1
                print("✅ [PRELOAD] Unread: \(counts.total) messages")
            }
        } catch {
            print("❌ [PRELOAD] Unread count failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Image Preloading

    private func preloadCriticalImages() async {
        print("🖼️ [PRELOAD] Starting critical image preload...")

        // Preload marketplace listing images (first 20 listings)
        let marketplaceImagesToPreload = marketplaceListings.prefix(20)
        await preloadImagesForListings(Array(marketplaceImagesToPreload), tag: "Marketplace")

        // Preload user's own listing images
        await preloadImagesForListings(userListings, tag: "User listings")

        // Preload featured listing images
        await preloadImagesForListings(featuredListings, tag: "Featured")

        // Preload favorite listing images
        await preloadImagesForListings(favorites, tag: "Favorites")

        print("✅ [PRELOAD] Image preload complete")
    }

    private func preloadImagesForListings(_ listings: [Listing], tag: String) async {
        let maxConcurrent = 5 // Limit concurrent downloads to avoid overwhelming network
        let imageUrls = listings.compactMap { $0.imageUrls.first }

        for batch in imageUrls.chunked(into: maxConcurrent) {
            await withTaskGroup(of: Void.self) { group in
                for imageUrl in batch {
                    group.addTask {
                        // Preload first image only for performance
                        if let url = URL(string: imageUrl) {
                            do {
                                let (data, _) = try await URLSession.shared.data(from: url)
                                if data.count > 0 {
                                    // Image is now cached by URLCache
                                }
                            } catch {
                                // Silent fail for image preload
                            }
                        }
                    }
                }
            }
        }

        print("🖼️ [PRELOAD] \(tag): Preloaded images for \(listings.count) listings")
    }

    // MARK: - Cache Invalidation

    /// Call this when user creates/updates data to refresh the cache
    func invalidateCache(for type: CacheType) {
        switch type {
        case .marketplace:
            marketplaceListings = []
            print("🔄 [PRELOAD] Invalidated marketplace cache")
        case .userListings:
            userListings = []
            print("🔄 [PRELOAD] Invalidated user listings cache")
        case .conversations:
            conversations = []
            print("🔄 [PRELOAD] Invalidated conversations cache")
        case .favorites:
            favorites = []
            print("🔄 [PRELOAD] Invalidated favorites cache")
        case .all:
            marketplaceListings = []
            userListings = []
            conversations = []
            favorites = []
            featuredListings = []
            garageSales = []
            isPreloadComplete = false
            print("🔄 [PRELOAD] Invalidated all caches")
        }
    }

    /// Refresh specific data type in background
    func refreshInBackground(type: CacheType) {
        Task {
            switch type {
            case .marketplace:
                await preloadMarketplaceListings()
            case .userListings:
                await preloadUserListings()
            case .conversations:
                await preloadConversations()
            case .favorites:
                await preloadFavorites()
            case .all:
                preloadAllData()
            }
        }
    }

    // MARK: - Helper Types

    enum CacheType {
        case marketplace
        case userListings
        case conversations
        case favorites
        case all
    }
}

// Extension to chunk arrays for batch processing
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
