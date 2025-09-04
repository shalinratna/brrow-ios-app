//
//  ListingNavigationManager.swift
//  Brrow
//
//  Manages universal navigation to listing details from anywhere in the app
//

import SwiftUI
import Combine

class ListingNavigationManager: ObservableObject {
    static let shared = ListingNavigationManager()
    
    @Published var selectedListing: Listing?
    @Published var showingListingDetail = false
    @Published var pendingListingId: String?
    @Published var isLoadingListing = false
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Listen for listing selection notifications
        NotificationCenter.default.publisher(for: .showListingDetail)
            .compactMap { $0.object as? Listing }
            .sink { [weak self] listing in
                self?.showListing(listing)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Show a listing detail view with preloaded data
    func showListing(_ listing: Listing) {
        print("🟢 ListingNavigationManager.showListing called for: \(listing.title)")
        print("🟢 Setting selectedListing and showingListingDetail = true")
        selectedListing = listing
        showingListingDetail = true
        print("🟢 showingListingDetail is now: \(showingListingDetail)")
    }
    
    /// Show a listing detail view by ID (will load the listing)
    func showListingById(_ listingId: String) {
        pendingListingId = listingId
        showingListingDetail = true
        loadListing(id: listingId)
    }
    
    /// Clear the current listing
    func clearListing() {
        selectedListing = nil
        pendingListingId = nil
        showingListingDetail = false
        isLoadingListing = false
    }
    
    // MARK: - Private Methods
    
    private func loadListing(id: String) {
        isLoadingListing = true
        
        Task {
            do {
                let url = URL(string: "\(APIClient.shared.baseURL)/get_listing.php?listing_id=\(id)")!
                
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                
                if let token = await AuthManager.shared.authToken {
                    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                }
                
                let (data, _) = try await URLSession.shared.data(for: request)
                let response = try JSONDecoder().decode(APIResponse<ListingDetailResponse>.self, from: data)
                
                await MainActor.run {
                    if response.success, let listingData = response.data {
                        self.selectedListing = listingData.toListing()
                        self.pendingListingId = nil
                    }
                    self.isLoadingListing = false
                }
            } catch {
                await MainActor.run {
                    self.isLoadingListing = false
                    self.showingListingDetail = false
                    print("Failed to load listing: \(error)")
                }
            }
        }
    }
}

// MARK: - View Modifier for Universal Listing Detail

struct UniversalListingDetailModifier: ViewModifier {
    @StateObject private var navigationManager = ListingNavigationManager.shared
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $navigationManager.showingListingDetail) {
                if let listing = navigationManager.selectedListing {
                    UniversalListingDetailView(listing: listing)
                } else if let listingId = navigationManager.pendingListingId {
                    DeepLinkedListingView(listingId: listingId)
                }
            }
    }
}

extension View {
    func withUniversalListingDetail() -> some View {
        modifier(UniversalListingDetailModifier())
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let showListingDetail = Notification.Name("showListingDetail")
}