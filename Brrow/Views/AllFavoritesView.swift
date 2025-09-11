//
//  AllFavoritesView.swift
//  Brrow
//
//  View for displaying all user's favorite listings
//

import SwiftUI

struct AllFavoritesView: View {
    @StateObject private var viewModel = AllFavoritesViewModel()
    @State private var selectedListing: Listing?
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading favorites...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.favorites.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(viewModel.favorites) { listing in
                            FavoriteGridItem(listing: listing) {
                                selectedListing = listing
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Theme.Colors.background)
        .onAppear {
            viewModel.loadFavorites()
        }
        .sheet(item: $selectedListing) { listing in
            NavigationView {
                ListingDetailView(listing: listing)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.slash")
                .font(.system(size: 60))
                .foregroundColor(Theme.Colors.secondary)
            
            Text("No Favorites Yet")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(Theme.Colors.text)
            
            Text("Items you favorite will appear here")
                .font(.system(size: 16))
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
            
            Button(action: {
                TabSelectionManager.shared.switchToMarketplace()
            }) {
                Text("Browse Marketplace")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Theme.Colors.primary)
                    .cornerRadius(25)
            }
        }
        .padding()
    }
}

struct FavoriteGridItem: View {
    let listing: Listing
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Image
                AsyncImage(url: URL(string: listing.imageUrls.first ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Theme.Colors.secondary.opacity(0.2))
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 24))
                                .foregroundColor(Theme.Colors.secondary)
                        )
                }
                .frame(height: 160)
                .clipped()
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    Text(listing.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.Colors.text)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        Text("$\(String(format: "%.2f", listing.price))")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Theme.Colors.primary)
                        
                        Text("/day")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.secondary)
                        
                        Text(listing.location.city)
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.secondaryText)
                            .lineLimit(1)
                    }
                }
                .padding(12)
            }
            .background(Theme.Colors.cardBackground)
            .cornerRadius(12)
            .shadow(color: Theme.Shadows.card, radius: 6, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

class AllFavoritesViewModel: ObservableObject {
    @Published var favorites: [Listing] = []
    @Published var isLoading = false
    
    func loadFavorites() {
        isLoading = true
        
        Task {
            do {
                let response = try await APIClient.shared.fetchFavorites(limit: 50)
                await MainActor.run {
                    self.favorites = response.favorites ?? []
                    self.isLoading = false
                }
            } catch {
                print("Failed to load favorites: \(error)")
                await MainActor.run {
                    self.favorites = []
                    self.isLoading = false
                }
            }
        }
    }
}