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
    
    private var cancellables = Set<AnyCancellable>()
    private let apiClient = APIClient.shared
    private let authManager = AuthManager.shared
    
    init(listing: Listing) {
        print("📱 ListingDetailViewModel init with listing: \(listing.listingId)")
        print("  Initial images count: \(listing.images.count)")
        listing.images.enumerated().forEach { index, url in
            print("  Initial Image \(index): \(url)")
        }
        self.listing = listing
        self.averageRating = listing.rating ?? 0.0
        self.similarItems = []
        
        // Only fetch details if we don't have complete data or if listing is not owned by current user
        let isOwnListing = authManager.currentUser?.apiId == listing.ownerApiId
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
                if listing.ownerId > 0 {
                    do {
                        let rating = try await apiClient.fetchUserRating(userId: listing.ownerId)
                        ownerRatingValue = rating.rating
                    } catch {
                        print("Failed to fetch owner rating: \(error)")
                        // Continue without rating
                    }
                }
                
                await MainActor.run {
                    // Only update if we got better data
                    if detailedListing.images.count > self.listing.images.count || 
                       (detailedListing.images.count == self.listing.images.count && 
                        detailedListing.views > self.listing.views) {
                        print("🔄 Background update with better data")
                        self.listing = detailedListing
                        self.ownerRating = ownerRatingValue
                    } else {
                        print("✓ Keeping cached data - no update needed")
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
                if listing.ownerId > 0 {
                    do {
                        let rating = try await apiClient.fetchUserRating(userId: listing.ownerId)
                        ownerRatingValue = rating.rating
                    } catch {
                        print("Failed to fetch owner rating: \(error)")
                        // Continue without rating
                    }
                }
                
                await MainActor.run {
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
        guard let userId = authManager.currentUser?.id else { return }
        
        Task {
            do {
                let favorited = try await apiClient.checkFavoriteStatus(listingId: listing.id, userId: userId)
                await MainActor.run {
                    self.isFavorited = favorited
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func loadSimilarListings() {
        Task {
            do {
                let similar = try await apiClient.fetchSimilarListings(
                    listingId: listing.id,
                    category: listing.category,
                    limit: 5
                )
                await MainActor.run {
                    self.similarListings = similar
                    self.similarItems = similar
                }
            } catch {
                // Similar listings failure is not critical
                print("Failed to load similar listings: \(error)")
            }
        }
    }
    
    private func loadSellerInfo() {
        Task {
            // Use listing's owner info to create seller profile with all available data
            let seller = User(
                id: listing.ownerId,
                username: listing.ownerUsername ?? "Seller",
                email: "",
                apiId: listing.ownerApiId ?? String(listing.ownerId),
                profilePicture: listing.ownerProfilePicture
            )
            
            // Note: verified status can be fetched from user rating API if needed
            
            await MainActor.run {
                self.seller = seller
                self.distanceFromUser = listing.distanceText
                self.reviewCount = listing.reviewCount ?? 0
            }
        }
    }
    
    func toggleFavorite() {
        // Check if user is a guest
        if authManager.isGuestUser {
            showGuestAlert = true
            return
        }
        
        guard let userId = authManager.currentUser?.id else { return }
        
        Task {
            do {
                let newStatus = try await apiClient.toggleFavoriteByListingId(listing.listingId, userId: userId)
                await MainActor.run {
                    self.isFavorited = newStatus
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func deleteListing() async {
        do {
            // Call API to delete listing
            _ = try await apiClient.deleteListing(listingId: listing.listingId)
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
        
        // Since listing properties are immutable, we'll need to refetch after update
        // For now, just make the API call
        
        // TODO: Implement API call
        // try await apiClient.updateListingField(listing.listingId, field: "price", value: newPrice)
        // Then reload the listing details
        // loadListingDetails()
        
        // Temporary: just log the change
        print("Would update price to: \(newPrice)")
    }
    
    func updateListingInventory(_ newInventory: Int) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // TODO: Implement API call
        // try await apiClient.updateListingField(listing.listingId, field: "inventory_amt", value: newInventory)
        // Then reload the listing details
        // loadListingDetails()
        
        // Temporary: just log the change
        print("Would update inventory to: \(newInventory)")
    }
    
    func updateListingStatus(_ newStatus: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // TODO: Implement API call
        // try await apiClient.updateListingField(listing.listingId, field: "status", value: newStatus)
        // Then reload the listing details
        // loadListingDetails()
        
        // Temporary: just log the change
        print("Would update status to: \(newStatus)")
    }
    
    func submitOffer(amount: Double, message: String, duration: Int) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Create offer with proper initialization
                let offerData = [
                    "listing_id": listing.id,
                    "borrower_id": authManager.currentUser!.id,
                    "amount": amount,
                    "message": message,
                    "duration": duration
                ]
                
                // Convert to JSON for API call
                let jsonData = try JSONSerialization.data(withJSONObject: offerData)
                let decoder = JSONDecoder()
                let offer = try decoder.decode(Offer.self, from: jsonData)
                
                try await apiClient.submitOffer(offer)
                
                await MainActor.run {
                    self.isLoading = false
                    self.showingOfferSheet = false
                    // Show success message
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func contactOwner() {
        showingContactSheet = true
    }
    
    func reportListing(reason: String, details: String) {
        Task {
            do {
                try await apiClient.reportListing(
                    listingId: listing.id,
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
        return currentUser.id != listing.ownerId && listing.isAvailable
    }
    
    var formattedPrice: String {
        if listing.priceType == .free {
            return "Free"
        } else {
            return "$\(String(format: "%.2f", listing.price))/\(listing.priceType.rawValue)"
        }
    }
    
    func messageOwner() {
        // Check if user is a guest
        if authManager.isGuestUser {
            showGuestAlert = true
            return
        }
        
        // Navigate to chat with the listing owner
        // This would typically post a notification to open chat
        NotificationCenter.default.post(
            name: .navigateToChat,
            object: nil,
            userInfo: [
                "userId": listing.ownerId,
                "listingId": listing.id,
                "listingTitle": listing.title
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
}
