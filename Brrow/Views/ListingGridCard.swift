//
//  ListingGridCard.swift
//  Brrow
//
//  Grid card component for displaying listings
//

import SwiftUI

struct ListingGridCard: View {
    let listing: Listing

    // Check if listing is new (updated in last 48 hours and available)
    private var isNewListing: Bool {
        guard listing.availabilityStatus == .available else { return false }

        // Parse the updatedAt timestamp
        let formatter = ISO8601DateFormatter()
        guard let updatedDate = formatter.date(from: listing.updatedAt) else {
            return false
        }

        // Check if updated within last 48 hours
        let fortyEightHoursAgo = Date().addingTimeInterval(-48 * 60 * 60)
        return updatedDate > fortyEightHoursAgo
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image section with status badge
            ZStack(alignment: .topTrailing) {
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

                // Badges container - use separate overlays to prevent overlap
                VStack {
                    Spacer()
                }
                // Status badge overlay (top-leading) - only show if not AVAILABLE
                .overlay(
                    Group {
                        if listing.availabilityStatus != .available {
                            VStack {
                                HStack {
                                    ListingStatusBadge(listing: listing, size: .small)
                                        .padding(6)
                                    Spacer()
                                }
                                Spacer()
                            }
                        }
                    }
                )
                // NEW badge overlay (top-trailing) - only if available and new
                .overlay(
                    Group {
                        if isNewListing {
                            VStack {
                                HStack {
                                    Spacer()
                                    HStack(spacing: 2) {
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 8))
                                        Text("NEW")
                                            .font(.system(size: 9, weight: .bold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule()
                                            .fill(Color.blue)
                                    )
                                    .padding(6)
                                }
                                Spacer()
                            }
                        }
                    }
                )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(listing.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
                    .lineLimit(2)

                // Show pricing based on pricing type
                if listing.pricingType == "RENTAL" {
                    Text("$\(listing.price, specifier: "%.0f")/day")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.Colors.primary)
                } else {
                    Text("$\(listing.price, specifier: "%.0f")")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.Colors.primary)
                }
                
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

