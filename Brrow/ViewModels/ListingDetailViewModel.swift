import Foundation
import Combine
import SwiftUI

@MainActor
class ListingDetailViewModel: ObservableObject {
    @Published var listing: Listing
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isFavorited = false
    @Published var showingOfferSheet = false
    @Published var showingContactSheet = false
    @Published var showingReportSheet = false
    @Published var showGuestAlert = false
    @Published var ownerRating: Double = 0.0
    @Published var similarListings: [Listing] = []
    @Published var seller: User?
    @Published var averageRating: Double = 0.0
    @Published var reviewCount: Int = 0
    @Published var distanceFromUser: String?
    @Published var nextAvailableDate: Date?
    @Published var similarItems: [Listing] = []
    @Published var sellerActiveListings: Int = 0
    @Published var sellerCompletedTransactions: Int = 0
    
    private var cancellables = Set<AnyCancellable>()
    private let apiClient = APIClient.shared
    private let authManager = AuthManager.shared

    // Expose guest user status
    var isGuestUser: Bool {
        return authManager.isGuestUser
    }

    init(listing: Listing) {
        print("📱 ListingDetailViewModel init with listing: \(listing.listingId)")
        print("  Initial images count: \(listing.images.count)")
        listing.images.enumerated().forEach { index, url in
            print("  Initial Image \(index): \(url)")
        }
        self.listing = listing
        self.averageRating = listing.ownerRating ?? 0.0
        self.similarItems = []
        
        // CRITICAL: Preload all images immediately for smooth viewing
        preloadAllListingImages()
        
        // Only fetch details if we don't have complete data or if listing is not owned by current user
        let isOwnListing = authManager.currentUser?.apiId == listing.user?.apiId
        let hasCompleteData = !listing.images.isEmpty && listing.ownerUsername != nil
        
        if !isOwnListing || !hasCompleteData {
            loadListingDetailsInBackground()
        }
        
        checkFavoriteStatus()
        loadSimilarListings()
        loadSellerInfo()
    }
    
    func loadListingDetailsInBackground() {
        // Don't show loading indicator - load in background
        errorMessage = nil
        
        Task {
            do {
                let detailedListing = try await apiClient.fetchListingDetailsByListingId(listing.listingId)
                
                // Only fetch rating if owner ID is valid
                var ownerRatingValue = 0.0
                if Int(listing.userId) ?? 0 > 0 {
                    do {
                        let rating = try await apiClient.fetchUserRating(userId: Int(listing.userId) ?? 0)
                        ownerRatingValue = rating.rating
                    } catch {
                        print("Failed to fetch owner rating: \(error)")
                        // Continue without rating
                    }
                }
                
                await MainActor.run {
                    // CRITICAL: Only update if the listing ID matches to prevent wrong details
                    if detailedListing.listingId == self.listing.listingId {
                        print("🔄 Background update with matching listing ID: \(detailedListing.listingId)")
                        self.listing = detailedListing
                        self.ownerRating = ownerRatingValue

                        // Preload new images if any
                        self.preloadAllListingImages()
                    } else {
                        print("⚠️ MISMATCH: API returned wrong listing! Expected: \(self.listing.listingId), Got: \(detailedListing.listingId)")
                    }
                }
            } catch {
                // Silently fail for background updates - we already have cached data
                print("Background update failed (non-critical): \(error)")
            }
        }
    }
    
    func loadListingDetails() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let detailedListing = try await apiClient.fetchListingDetailsByListingId(listing.listingId)
                
                // Only fetch rating if owner ID is valid
                var ownerRatingValue = 0.0
                if Int(listing.userId) ?? 0 > 0 {
                    do {
                        let rating = try await apiClient.fetchUserRating(userId: Int(listing.userId) ?? 0)
                        ownerRatingValue = rating.rating
                    } catch {
                        print("Failed to fetch owner rating: \(error)")
                        // Continue without rating
                    }
                }
                
                await MainActor.run {
                    // CRITICAL: Verify listing ID matches to prevent wrong details
                    if detailedListing.listingId == self.listing.listingId {
                        print("🔍 Updating listing with detailed data:")
                        print("  Original images count: \(self.listing.images.count)")
                        self.listing.images.enumerated().forEach { index, url in
                            print("    Original Image \(index): \(url)")
                        }
                        print("  New images count: \(detailedListing.images.count)")
                        detailedListing.images.enumerated().forEach { index, url in
                            print("    New Image \(index): \(url)")
                        }
                        self.listing = detailedListing
                        self.ownerRating = ownerRatingValue
                        self.isLoading = false
                        print("  Final images count after update: \(self.listing.images.count)")
                        self.listing.images.enumerated().forEach { index, url in
                            print("    Final Image \(index): \(url)")
                        }
                    } else {
                        print("❌ CRITICAL ERROR: API returned wrong listing! Expected: \(self.listing.listingId), Got: \(detailedListing.listingId)")
                        self.errorMessage = "Failed to load correct listing details"
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load listing: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func checkFavoriteStatus() {
        // Use FavoritesManager for instant state sync
        self.isFavorited = FavoritesManager.shared.isFavorited(listing.id)
    }
    
    private func loadSimilarListings() {
        Task {
            do {
                let similar = try await apiClient.fetchSimilarListings(
                    listingId: listing.id,
                    category: listing.category?.name ?? "Unknown",
                    limit: 5
                )
                await MainActor.run {
                    self.similarListings = similar
                    self.similarItems = similar
                    
                    // Preload similar items' images for smooth browsing
                    self.preloadSimilarImages()
                }
            } catch {
                // Similar listings failure is not critical
                print("Failed to load similar listings: \(error)")
            }
        }
    }
    
    // MARK: - Image Preloading for Performance
    
    private func preloadAllListingImages() {
        // Get all image URLs for this listing
        var imageURLs: [String] = []
        
        // Try images array first
        if !listing.images.isEmpty {
            imageURLs = listing.images.compactMap { $0.url }
        }
        // Fall back to imageUrls if available
        else if !listing.imageUrls.isEmpty {
            imageURLs = listing.imageUrls
        }
        // Try firstImageUrl as last resort
        else if let firstImage = listing.firstImageUrl {
            imageURLs = [firstImage]
        }
        
        guard !imageURLs.isEmpty else { return }
        
        print("🖼️ Preloading \(imageURLs.count) images for listing \(listing.title)")
        
        // Preload with high priority for instant display
        Task.detached(priority: .high) {
            for url in imageURLs {
                do {
                    _ = try await ImageCacheManager.shared.loadImage(from: url)
                    print("✅ Preloaded image: \(url)")
                } catch {
                    print("⚠️ Failed to preload image: \(url)")
                }
            }
        }
    }
    
    private func preloadSimilarImages() {
        let imageURLs = similarListings.compactMap { listing in
            listing.imageUrls.first ?? listing.firstImageUrl ?? listing.images.first?.url
        }
        
        guard !imageURLs.isEmpty else { return }
        
        print("🖼️ Preloading \(imageURLs.count) similar listing images")
        
        // Preload with medium priority
        Task.detached(priority: .medium) {
            for url in imageURLs {
                do {
                    _ = try await ImageCacheManager.shared.loadImage(from: url)
                } catch {
                    // Silent fail for similar images
                }
            }
        }
    }
    
    private func loadSellerInfo() {
        Task {
            // Use listing's owner info to create seller profile with all available data
            let seller = User(
                id: listing.userId,
                username: listing.ownerUsername ?? "Seller",
                email: "",
                apiId: listing.user?.apiId ?? String(Int(listing.userId) ?? 0),
                profilePicture: listing.ownerProfilePicture
            )
            
            // Fetch seller's active listings count
            do {
                let response = try await apiClient.fetchUserListings(userId: listing.userId)
                let listings = response.allListings
                if !listings.isEmpty {
                    let activeCount = listings.filter { $0.isActive }.count
                    let completedCount = listings.filter { $0.status == "completed" || $0.status == "sold" }.count
                    
                    await MainActor.run {
                        self.sellerActiveListings = activeCount
                        self.sellerCompletedTransactions = completedCount
                    }
                } else {
                    // No data available
                    await MainActor.run {
                        self.sellerActiveListings = 1 // At least this listing
                        self.sellerCompletedTransactions = 0
                    }
                }
            } catch {
                print("Failed to fetch seller listings: \(error)")
                // Set default values
                await MainActor.run {
                    self.sellerActiveListings = 1 // At least this listing
                    self.sellerCompletedTransactions = 0
                }
            }
            
            await MainActor.run {
                self.seller = seller
                self.distanceFromUser = listing.distanceText
                self.reviewCount = 0 // reviewCount not available in new model
            }
        }
    }
    
    func toggleFavorite() {
        // Check if user is a guest
        if authManager.isGuestUser {
            showGuestAlert = true
            return
        }

        guard authManager.currentUser != nil else { return }

        Task {
            // Use FavoritesManager's toggle method which handles both API and state sync
            await FavoritesManager.shared.toggleFavorite(listing: listing)

            // Update local state to match FavoritesManager
            await MainActor.run {
                self.isFavorited = FavoritesManager.shared.isFavorited(listing.id)
            }
        }
    }
    
    func deleteListing() async {
        do {
            // Call API to delete listing
            _ = try await apiClient.deleteListing(listingId: listing.listingId)

            // Post notifications to refresh UI across the app
            await MainActor.run {
                print("✅ [DELETE] Posting RefreshMyPosts notification for deleted listing: \(listing.listingId)")
                NotificationCenter.default.post(
                    name: Notification.Name("RefreshMyPosts"),
                    object: nil,
                    userInfo: ["listingId": listing.listingId, "action": "deleted"]
                )

                // Also post a dismissal notification so the detail view can close
                print("✅ [DELETE] Posting DismissListingDetail notification")
                NotificationCenter.default.post(
                    name: Notification.Name("DismissListingDetail"),
                    object: nil,
                    userInfo: ["listingId": listing.listingId]
                )
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to delete listing: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Owner Actions
    
    func updateListingPrice(_ newPrice: Double) async throws {
        isLoading = true
        defer { isLoading = false }
        
        try await apiClient.updateListingField(listingId: listing.listingId, field: "price", value: newPrice)
        
        // Reload listing details to get updated data
        await loadListingDetails()
    }
    
    func updateListingInventory(_ newInventory: Int) async throws {
        isLoading = true
        defer { isLoading = false }
        
        try await apiClient.updateListingField(listingId: listing.listingId, field: "inventoryAmount", value: newInventory)
        
        // Reload listing details to get updated data
        await loadListingDetails()
    }
    
    func updateListingStatus(_ newStatus: String) async throws {
        isLoading = true
        defer { isLoading = false }

        // Use the new status endpoint
        let updatedListing = try await apiClient.updateListingStatus(listingId: listing.listingId, status: newStatus)

        await MainActor.run {
            self.listing = updatedListing

            // Post notifications to refresh UI across the app
            print("✅ [STATUS UPDATE] Posting RefreshListingDetail notification for listing: \(updatedListing.listingId)")
            NotificationCenter.default.post(
                name: Notification.Name("RefreshListingDetail"),
                object: nil,
                userInfo: ["listingId": updatedListing.listingId]
            )

            // Also post MyPosts refresh notification so the list updates
            print("✅ [STATUS UPDATE] Posting RefreshMyPosts notification")
            NotificationCenter.default.post(
                name: Notification.Name("RefreshMyPosts"),
                object: nil,
                userInfo: ["listingId": updatedListing.listingId, "newStatus": newStatus]
            )
        }
    }

    // Convenience method for marking as sold/rented from detail view
    func markAsSoldOrRented() async throws {
        let newStatus = listing.listingType == "sale" ? "SOLD" : "RENTED"
        try await updateListingStatus(newStatus)
    }
    
    func submitOffer(amount: Double, message: String, duration: Int) {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                // CRITICAL FIX: Use correct field names that backend expects
                // Backend expects: { listingId, amount, message }
                let offerRequest = CreateOfferRequest(
                    listingId: listing.id,        // Correct: backend expects listingId (camelCase)
                    amount: amount,
                    message: message
                )

                // Call createOffer directly with properly formatted request
                let createdOffer = try await apiClient.createOffer(offerRequest)

                await MainActor.run {
                    self.isLoading = false
                    self.showingOfferSheet = false
                    // Show success message
                    print("Offer created successfully: \(createdOffer.id)")
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to send offer: \(error.localizedDescription)"
                    self.isLoading = false
                    print("Offer creation failed: \(error)")
                }
            }
        }
    }
    
    func contactOwner() {
        // Create or get chat with listing owner
        Task {
            await MainActor.run {
                self.isLoading = true
            }

            let ownerId = listing.userId

            // Check if user is trying to message themselves
            if ownerId == AuthManager.shared.currentUser?.id {
                await MainActor.run {
                    self.errorMessage = "You cannot message yourself"
                    self.isLoading = false
                }
                return
            }

            do {
                // Create or get direct chat with the owner
                let body = ["recipientId": ownerId, "listingId": listing.id]
                let bodyData = try JSONSerialization.data(withJSONObject: body)

                let response = try await apiClient.performRequest(
                    endpoint: "api/messages/chats/direct",
                    method: "POST",
                    body: bodyData,
                    responseType: CreateChatResponse.self
                )

                if let chat = response.data {
                    await MainActor.run {
                        self.isLoading = false
                        // Navigate to chat view
                        NotificationCenter.default.post(
                            name: .navigateToChat,
                            object: nil,
                            userInfo: ["chatId": chat.id, "listing": listing]
                        )
                    }
                } else {
                    throw BrrowAPIError.invalidResponse
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to start conversation: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func reportListing(reason: String, details: String) {
        Task {
            do {
                try await apiClient.reportListing(
                    listingId: Int(listing.id) ?? 0,
                    reason: reason,
                    details: details
                )
                
                await MainActor.run {
                    self.showingReportSheet = false
                    // Show success message
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func shareListing() {
        let shareURL = URL(string: "https://brrowapp.dx/listing/\(listing.id)")!
        let activityVC = UIActivityViewController(
            activityItems: [shareURL, listing.title],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
    
    var canMakeOffer: Bool {
        guard let currentUser = authManager.currentUser else { return false }
        return currentUser.id != listing.userId && listing.isAvailable
    }
    
    var formattedPrice: String {
        if listing.price == 0 {
            return "Free"
        } else {
            return "$\(String(format: "%.2f", listing.price))/day"
        }
    }
    
    func messageOwner() {
        // Check if user is a guest
        if authManager.isGuestUser {
            showGuestAlert = true
            return
        }

        // Get current user ID
        guard let currentUser = authManager.currentUser else {
            print("❌ No current user found")
            return
        }

        // Create chat ID based on user IDs and listing using string IDs
        let currentUserId = currentUser.id
        let ownerUserId = listing.userId

        // Create a consistent chat ID by sorting the user IDs alphabetically
        let sortedUserIds = [currentUserId, ownerUserId].sorted()
        let chatId = "listing_\(listing.id)_\(sortedUserIds[0])_\(sortedUserIds[1])"

        print("🔔 Posting navigateToChat notification with chatId: \(chatId)")
        print("🔔 Current user: \(currentUser.username ?? "unknown"), Owner: \(listing.userId)")
        print("🔔 User IDs - Current: \(currentUserId), Owner: \(ownerUserId)")

        // Navigate to chat with the listing owner
        NotificationCenter.default.post(
            name: .navigateToChat,
            object: nil,
            userInfo: [
                "chatId": chatId,
                "userId": ownerUserId,
                "listingId": listing.id,
                "listingTitle": listing.title,
                "listing": listing
            ]
        )
    }
    
    func sendInquiry(message: String) async throws -> Int {
        // Send inquiry using the new API endpoint
        let response = try await apiClient.sendListingInquiry(
            listingId: listing.listingId,
            message: message,
            inquiryType: "general"
        )
        
        // Post notification to navigate to chat with the conversation ID
        await MainActor.run {
            NotificationCenter.default.post(
                name: .navigateToChat,
                object: nil,
                userInfo: [
                    "conversationId": response.conversationId,
                    "listingId": listing.listingId,
                    "listingTitle": listing.title
                ]
            )
        }
        
        return response.conversationId
    }
    
    func calculateResponseTime() -> String {
        // Calculate based on user's typical response patterns
        // For now, return a reasonable default
        // TODO: Implement actual calculation based on message history
        let hours = Int.random(in: 1...4)
        return hours == 1 ? "1 hour" : "\(hours) hours"
    }
}
