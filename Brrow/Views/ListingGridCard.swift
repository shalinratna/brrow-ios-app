//
//  ListingGridCard.swift
//  Brrow
//
//  Grid card component for displaying listings
//

import SwiftUI

struct ListingGridCard: View {
    let listing: Listing
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image - Using CachedAsyncImage for better performance
            BrrowAsyncImage(
                url: listing.imageUrls.first ?? listing.firstImageUrl ?? listing.images.first?.url,
                content: { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                },
                placeholder: {
                    Rectangle()
                        .fill(Theme.Colors.surface)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.title2)
                                .foregroundColor(Theme.Colors.secondaryText)
                        )
                }
            )
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .clipped()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(listing.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
                    .lineLimit(2)
                
                Text("$\(listing.price, specifier: "%.0f")/day")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.Colors.primary)
                
                if let rating = listing.ownerRating {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                        
                        Text("\(rating, specifier: "%.1f")")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.Colors.secondaryText)
                        
                        Text("(0)") // timesBorrowed not in new model
                            .font(.system(size: 10))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
                
                Text(listing.location.city)
                    .font(.system(size: 10))
                    .foregroundColor(Theme.Colors.secondaryText)
                    .lineLimit(1)
            }
            .padding(.horizontal, 4)
        }
        .background(Theme.Colors.surface)
        .cornerRadius(Theme.CornerRadius.card)
        .shadow(color: Theme.Shadows.card, radius: 2, x: 0, y: 1)
        .onAppear {
            // Preload all images for this listing when card appears
            preloadListingImages()
        }
    }
    
    private func preloadListingImages() {
        // Get all image URLs for preloading
        let imageURLs: [String] = listing.imageUrls.isEmpty ? 
            listing.images.compactMap { $0.url } : 
            listing.imageUrls
        
        // Skip if no additional images
        guard imageURLs.count > 1 else { return }
        
        // Preload remaining images (first is already loading)
        Task.detached(priority: .low) {
            for url in imageURLs.dropFirst() {
                do {
                    _ = try await ImageCacheManager.shared.loadImage(from: url)
                } catch {
                    // Silent fail for preloading
                }
            }
        }
    }
}

