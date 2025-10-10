//
//  EnhancedSavedItemsView.swift
//  Brrow
//
//  Enhanced saved items view with favorites functionality
//

import SwiftUI

struct EnhancedSavedItemsView: View {
    @StateObject private var favoritesManager = FavoritesManager.shared
    @State private var selectedCategory: String = "All"
    @State private var selectedListing: Listing?
    @Environment(\.dismiss) private var dismiss

    private let categories = ["All", "Items", "Garage Sales", "Seeks"]
    
    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom header
                customHeader
                
                // Category filter
                categoryFilter
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                
                // Content
                if favoritesManager.isLoading {
                    loadingView
                } else if filteredItems.isEmpty {
                    emptyState
                } else {
                    savedItemsGrid
                }
            }
        }
        .onAppear {
            Task {
                await favoritesManager.loadFavorites()
            }
        }
        .refreshable {
            await favoritesManager.loadFavorites()
        }
        .sheet(item: $selectedListing) { listing in
            NavigationView {
                SimplifiedListingDetailView(listing: listing)
            }
        }
    }
    
    // MARK: - Custom Header
    private var customHeader: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(Theme.Colors.primary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Theme.Colors.cardBackground)
                            .shadow(color: Theme.Shadows.card, radius: 4)
                    )
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("Saved Items")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Theme.Colors.text)
                
                Text("\(filteredItems.count) items")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            
            Spacer()
            
            // Sort button
            Button(action: { /* Show sort options */ }) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.title3)
                    .foregroundColor(Theme.Colors.primary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Theme.Colors.cardBackground)
                            .shadow(color: Theme.Shadows.card, radius: 4)
                    )
            }
        }
        .padding(.horizontal)
        .padding(.top, 60)
        .padding(.bottom, 16)
        .background(Theme.Colors.background)
    }
    
    // MARK: - Category Filter
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { category in
                    SavedItemsCategoryChip(
                        title: category,
                        isSelected: selectedCategory == category,
                        count: getCount(for: category),
                        action: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedCategory = category
                            }
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Saved Items Grid
    private var savedItemsGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(filteredItems) { listing in
                    SavedListingCard(
                        listing: listing,
                        onTap: {
                            selectedListing = listing
                        },
                        onToggleFavorite: {
                            Task {
                                await favoritesManager.toggleFavorite(listing: listing)
                            }
                        }
                    )
                }
            }
            .padding()
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.primary))
                .scaleEffect(1.5)
            
            Text("Loading saved items...")
                .font(.system(size: 16))
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.slash")
                .font(.system(size: 80))
                .foregroundColor(Theme.Colors.primary.opacity(0.3))
            
            VStack(spacing: 8) {
                Text("No Saved Items")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Theme.Colors.text)
                
                Text("Items you save will appear here")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                dismiss()
                TabSelectionManager.shared.selectedTab = 1 // Marketplace
            }) {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("Browse Marketplace")
                }
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Theme.Colors.primary)
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helper Methods
    private var filteredItems: [Listing] {
        // For now, only show listings (can add garage sales and seeks later)
        return favoritesManager.favoriteListings
    }

    private func getCount(for category: String) -> Int {
        switch category {
        case "Items":
            return favoritesManager.favoriteListings.count
        case "Garage Sales":
            return 0  // TODO: Add garage sales support
        case "Seeks":
            return 0  // TODO: Add seeks support
        default:
            return favoritesManager.favoriteListings.count
        }
    }
}

// MARK: - Saved Items Category Chip
struct SavedItemsCategoryChip: View {
    let title: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white.opacity(0.3) : Theme.Colors.primary.opacity(0.2))
                        )
                }
            }
            .foregroundColor(isSelected ? .white : Theme.Colors.text)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Theme.Colors.primary : Theme.Colors.secondaryBackground)
            )
        }
    }
}

// MARK: - Saved Listing Card
struct SavedListingCard: View {
    let listing: Listing
    let onTap: () -> Void
    let onToggleFavorite: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Image with favorite button
                ZStack(alignment: .topTrailing) {
                    BrrowAsyncImage(url: listing.imageUrls.first ?? "") { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Theme.Colors.secondaryBackground)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.title2)
                                    .foregroundColor(Theme.Colors.secondary)
                            )
                    }
                    .frame(height: 160)
                    .clipped()

                    // Favorite button
                    Button(action: onToggleFavorite) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.red)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.white)
                                    .shadow(radius: 4)
                            )
                    }
                    .padding(8)
                }

                // Content
                VStack(alignment: .leading, spacing: 6) {
                    Text(listing.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.Colors.text)
                        .lineLimit(2)

                    HStack {
                        Text("$\(Int(listing.price))")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Theme.Colors.primary)

                        Text("/day")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "location")
                            .font(.caption2)
                        Text(listing.location.city)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .foregroundColor(Theme.Colors.secondaryText)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.Colors.cardBackground)
                    .shadow(color: Theme.Shadows.card, radius: 4, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

