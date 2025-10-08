//
//  MarketplaceDataPreloader.swift
//  Brrow
//
//  Preloads marketplace data before user navigates to marketplace
//

import Foundation
import Combine

/// Preloads marketplace data on app launch so marketplace is ready instantly when user taps the tab
class MarketplaceDataPreloader: ObservableObject {
    static let shared = MarketplaceDataPreloader()

    @Published var isPreloaded = false
    @Published var listings: [Listing] = []

    private let apiClient = APIClient.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {}

    /// Preload marketplace data in background on app launch
    func preloadMarketplaceData() {
        Task {
            do {
                print("🔄 [PRELOAD] Starting marketplace data preload...")
                print("🔄 [PRELOAD] This will fetch ALL active listings from ALL users for marketplace browsing")

                // Fetch all active listings from ALL users (never filtered by user_id)
                let fetchedListings = try await apiClient.fetchListings()

                await MainActor.run {
                    self.listings = fetchedListings
                    self.isPreloaded = true
                    print("✅ [PRELOAD] Marketplace data preloaded: \(fetchedListings.count) listings from ALL users")

                    // Log first few listing IDs for debugging
                    if fetchedListings.count > 0 {
                        let sampleIds = fetchedListings.prefix(3).map { $0.id }
                        print("✅ [PRELOAD] Sample listing IDs: \(sampleIds)")
                    }
                }

                // Preload images in background
                await preloadImages(for: fetchedListings)

            } catch {
                print("❌ [PRELOAD] Failed to preload marketplace: \(error.localizedDescription)")
                await MainActor.run {
                    self.isPreloaded = false
                }
            }
        }
    }

    /// Preload first image of each listing
    private func preloadImages(for listings: [Listing]) async {
        print("🖼️ [PRELOAD] Starting image preload for \(listings.count) listings...")

        var successCount = 0
        let maxConcurrent = 5 // Limit concurrent downloads

        for batch in listings.chunked(into: maxConcurrent) {
            await withTaskGroup(of: Void.self) { group in
                for listing in batch {
                    group.addTask {
                        // Preload first image only
                        if let firstImage = listing.images.first,
                           let url = URL(string: firstImage.url ?? "") {
                            do {
                                let (data, _) = try await URLSession.shared.data(from: url)
                                if data.count > 0 {
                                    await MainActor.run {
                                        successCount += 1
                                    }
                                }
                            } catch {
                                // Silent fail for image preload
                            }
                        }
                    }
                }
            }
        }

        print("✅ [PRELOAD] Images preloaded: \(successCount)/\(listings.count)")
    }

    /// Get preloaded listings or empty array if not ready
    func getPreloadedListings() -> [Listing] {
        return isPreloaded ? listings : []
    }

    /// Clear preloaded data (call when user creates/updates a listing to force refresh)
    func invalidateCache() {
        print("🔄 [PRELOAD] Invalidating marketplace cache")
        listings = []
        isPreloaded = false
    }

    /// Refresh preloaded data in background
    func refreshInBackground() {
        Task {
            print("🔄 [PRELOAD] Refreshing marketplace data in background...")
            invalidateCache()
            preloadMarketplaceData()
        }
    }
}

// Extension to chunk arrays for batch processing
// NOTE: This extension is also defined in AppDataPreloader.swift
// Keep both implementations for backwards compatibility
