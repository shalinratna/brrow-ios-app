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
        print("🟢 ListingNavigationManager.showListing called for: \(listing.title) (ID: \(listing.listingId))")
        print("🟢 Current selectedListing before change: \(selectedListing?.title ?? "nil") (ID: \(selectedListing?.listingId ?? "nil"))")
        print("🟢 Setting selectedListing to: \(listing.title) and showingListingDetail = true")

        // Set new state directly - no need to clear first with .id() modifier
        pendingListingId = nil
        selectedListing = listing
        showingListingDetail = true

        print("🟢 Final selectedListing: \(selectedListing?.title ?? "nil") (ID: \(selectedListing?.listingId ?? "nil"))")
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
                print("🔍 ListingNavigationManager: Loading listing with ID: \(id)")

                // Use the proper APIClient method
                let listing = try await APIClient.shared.fetchListingDetailsByListingId(id)

                await MainActor.run {
                    print("✅ ListingNavigationManager: Successfully loaded listing: \(listing.title)")
                    self.selectedListing = listing
                    self.pendingListingId = nil
                    self.isLoadingListing = false
                }
            } catch {
                await MainActor.run {
                    print("❌ ListingNavigationManager: Failed to load listing \(id): \(error)")
                    self.isLoadingListing = false
                    self.showingListingDetail = false
                }
            }
        }
    }
}

// MARK: - View Modifier for Universal Listing Detail

struct UniversalListingDetailModifier: ViewModifier {
    @ObservedObject private var navigationManager = ListingNavigationManager.shared

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $navigationManager.showingListingDetail) {
                if let listing = navigationManager.selectedListing {
                    NavigationView {
                        ProfessionalListingDetailView(listing: listing)
                    }
                    .id(listing.listingId) // Force view recreation when listing changes
                    .onDisappear {
                        print("🔶 Sheet dismissed, clearing navigation state")
                        navigationManager.clearListing()
                    }
                } else if let listingId = navigationManager.pendingListingId {
                    DeepLinkedListingView(listingId: listingId)
                        .id(listingId) // Force view recreation when listing ID changes
                        .onDisappear {
                            print("🔶 Deep linked sheet dismissed, clearing navigation state")
                            navigationManager.clearListing()
                        }
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