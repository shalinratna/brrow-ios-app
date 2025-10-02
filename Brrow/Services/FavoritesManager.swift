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
                self.favoriteListings = response.favorites ?? []
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
        let isFavorited = favoriteListingIds.contains(listingId)

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

        // Call API
        do {
            guard let userId = AuthManager.shared.currentUser?.id,
                  let userIdInt = Int(userId) else {
                throw NSError(domain: "FavoritesManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid user ID"])
            }

            let result = try await APIClient.shared.toggleFavoriteByListingId(listingId, userId: userIdInt)

            // Verify result matches our optimistic update
            await MainActor.run {
                if result != !isFavorited {
                    // Revert if mismatch
                    if isFavorited {
                        self.favoriteListingIds.insert(listingId)
                        var updatedListing = listing
                        updatedListing.isFavorite = true
                        self.favoriteListings.append(updatedListing)
                    } else {
                        self.favoriteListingIds.remove(listingId)
                        self.favoriteListings.removeAll { $0.id == listingId }
                    }
                }
            }

            // Post notification for UI updates
            NotificationCenter.default.post(name: .favoriteStatusChanged, object: ["listingId": listingId, "isFavorited": !isFavorited])

        } catch {
            print("❌ FavoritesManager: Failed to toggle favorite: \(error)")

            // Revert optimistic update on error
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
