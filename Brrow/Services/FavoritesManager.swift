//
//  FavoritesManager.swift
//  Brrow
//
//  Centralized favorites management service
//

import Foundation
import Combine

class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()

    @Published var favoriteListingIds: Set<String> = []
    @Published var favoriteListings: [Listing] = []
    @Published var isLoading = false

    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Load favorites on initialization
        Task {
            await loadFavorites()
        }
    }

    // MARK: - Load Favorites
    func loadFavorites() async {
        guard AuthManager.shared.isAuthenticated, !AuthManager.shared.isGuestUser else {
            await MainActor.run {
                self.favoriteListingIds.removeAll()
                self.favoriteListings.removeAll()
            }
            return
        }

        await MainActor.run {
            self.isLoading = true
        }

        do {
            let response = try await APIClient.shared.fetchFavorites(limit: 100)
            await MainActor.run {
                // Use the computed property that extracts listings from FavoriteItems
                self.favoriteListings = response.listings
                self.favoriteListingIds = Set(self.favoriteListings.map { $0.id })
                self.isLoading = false
            }
        } catch {
            print("❌ FavoritesManager: Failed to load favorites: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }

    // MARK: - Toggle Favorite
    func toggleFavorite(listing: Listing) async {
        // 🔍 DEBUG: Log listing details
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🔍 [FAVORITES DEBUG] toggleFavorite called")
        print("   📌 Listing ID: \(listing.id)")
        print("   📝 Listing Title: \(listing.title)")
        print("   ⚡ Status: \(listing.availabilityStatus)")
        print("   💰 Price: $\(listing.price)")
        print("   👤 User ID: \(AuthManager.shared.currentUser?.id ?? "NONE")")
        print("   🔐 Auth Token: \(AuthManager.shared.authToken?.prefix(20) ?? "NONE")...")

        guard AuthManager.shared.isAuthenticated, !AuthManager.shared.isGuestUser else {
            print("   ❌ User not authenticated")
            await MainActor.run {
                ToastManager.shared.showError(
                    title: "Sign In Required",
                    message: "Please sign in to save favorites"
                )
            }
            return
        }

        let listingId = listing.id
        let isFavorited = favoriteListingIds.contains(listingId)

        print("   ⭐ Currently Favorited: \(isFavorited)")
        print("   🎯 Action: \(isFavorited ? "REMOVE" : "ADD")")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // Optimistic update
        await MainActor.run {
            if isFavorited {
                self.favoriteListingIds.remove(listingId)
                self.favoriteListings.removeAll { $0.id == listingId }
            } else {
                self.favoriteListingIds.insert(listingId)
                var updatedListing = listing
                updatedListing.isFavorite = true
                self.favoriteListings.append(updatedListing)
            }
        }

        // Track analytics
        AnalyticsService.shared.trackFavorite(listingId: listingId, action: isFavorited ? "remove" : "add")

        // Call API using new dedicated endpoints
        do {
            print("🌐 [FAVORITES DEBUG] Calling API...")
            if isFavorited {
                print("   📍 Endpoint: DELETE /api/favorites/\(listingId)")
                try await APIClient.shared.removeFavorite(listingId)
                print("   ✅ Successfully removed from favorites")
            } else {
                print("   📍 Endpoint: POST /api/favorites/\(listingId)")
                try await APIClient.shared.addFavorite(listingId)
                print("   ✅ Successfully added to favorites")
            }

            // Post notification for UI updates
            NotificationCenter.default.post(name: .favoriteStatusChanged, object: ["listingId": listingId, "isFavorited": !isFavorited])

        } catch {
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("❌ [FAVORITES DEBUG] API Call FAILED")
            print("   Error Type: \(type(of: error))")
            print("   Error: \(error)")

            if let apiError = error as? BrrowAPIError {
                print("   API Error Details: \(apiError)")
                print("   Error Description: \(apiError.errorDescription ?? "none")")
            }

            // Try to extract more info from error
            let errorString = String(describing: error)
            print("   Full Error String: \(errorString)")

            // Check if error is "already in favorites" - this is OK, just sync local state
            let isAlreadyFavoritedError = errorString.contains("already in favorites") ||
                                         errorString.contains("Listing already in favorites")
            let isNotFavoritedError = errorString.contains("not in favorites") ||
                                     errorString.contains("Favorite not found")

            if isAlreadyFavoritedError {
                print("   ℹ️ Item already favorited on backend - syncing local state")
                // Keep the optimistic update (already added to local state)
                // Just post notification and show success
                await MainActor.run {
                    ToastManager.shared.showSuccess(
                        title: "Added to Favorites",
                        message: "Item saved successfully"
                    )
                }
                NotificationCenter.default.post(name: .favoriteStatusChanged, object: ["listingId": listingId, "isFavorited": true])
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                return
            }

            if isNotFavoritedError {
                print("   ℹ️ Item not favorited on backend - syncing local state")
                // Keep the optimistic update (already removed from local state)
                await MainActor.run {
                    ToastManager.shared.showSuccess(
                        title: "Removed from Favorites",
                        message: "Item removed successfully"
                    )
                }
                NotificationCenter.default.post(name: .favoriteStatusChanged, object: ["listingId": listingId, "isFavorited": false])
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                return
            }

            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

            // Revert optimistic update only for real errors
            await MainActor.run {
                if isFavorited {
                    self.favoriteListingIds.insert(listingId)
                    var updatedListing = listing
                    updatedListing.isFavorite = true
                    self.favoriteListings.append(updatedListing)
                } else {
                    self.favoriteListingIds.remove(listingId)
                    self.favoriteListings.removeAll { $0.id == listingId }
                }

                ToastManager.shared.showError(
                    title: "Failed to Update Favorite",
                    message: "Please try again"
                )
            }
        }
    }

    // MARK: - Add Favorite (explicit method)
    func addFavorite(listing: Listing) async {
        guard AuthManager.shared.isAuthenticated, !AuthManager.shared.isGuestUser else {
            await MainActor.run {
                ToastManager.shared.showError(
                    title: "Sign In Required",
                    message: "Please sign in to save favorites"
                )
            }
            return
        }

        let listingId = listing.id

        // Optimistic update
        await MainActor.run {
            self.favoriteListingIds.insert(listingId)
            var updatedListing = listing
            updatedListing.isFavorite = true
            self.favoriteListings.append(updatedListing)
        }

        // Track analytics
        AnalyticsService.shared.trackFavorite(listingId: listingId, action: "add")

        do {
            try await APIClient.shared.addFavorite(listingId)

            // Post notification for UI updates
            NotificationCenter.default.post(name: .favoriteStatusChanged, object: ["listingId": listingId, "isFavorited": true])

        } catch {
            print("❌ FavoritesManager: Failed to add favorite: \(error)")

            // Revert on error
            await MainActor.run {
                self.favoriteListingIds.remove(listingId)
                self.favoriteListings.removeAll { $0.id == listingId }

                ToastManager.shared.showError(
                    title: "Failed to Add Favorite",
                    message: "Please try again"
                )
            }
        }
    }

    // MARK: - Remove Favorite (explicit method)
    func removeFavorite(listing: Listing) async {
        guard AuthManager.shared.isAuthenticated, !AuthManager.shared.isGuestUser else {
            return
        }

        let listingId = listing.id

        // Optimistic update
        await MainActor.run {
            self.favoriteListingIds.remove(listingId)
            self.favoriteListings.removeAll { $0.id == listingId }
        }

        // Track analytics
        AnalyticsService.shared.trackFavorite(listingId: listingId, action: "remove")

        do {
            try await APIClient.shared.removeFavorite(listingId)

            // Post notification for UI updates
            NotificationCenter.default.post(name: .favoriteStatusChanged, object: ["listingId": listingId, "isFavorited": false])

        } catch {
            print("❌ FavoritesManager: Failed to remove favorite: \(error)")

            // Revert on error
            await MainActor.run {
                self.favoriteListingIds.insert(listingId)
                var updatedListing = listing
                updatedListing.isFavorite = true
                self.favoriteListings.append(updatedListing)

                ToastManager.shared.showError(
                    title: "Failed to Remove Favorite",
                    message: "Please try again"
                )
            }
        }
    }

    // MARK: - Check if Favorited
    func isFavorited(_ listingId: String) -> Bool {
        return favoriteListingIds.contains(listingId)
    }

    // MARK: - Clear All (for logout)
    func clearAll() {
        favoriteListingIds.removeAll()
        favoriteListings.removeAll()
    }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let favoriteStatusChanged = Notification.Name("favoriteStatusChanged")
}
