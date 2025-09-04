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
            // Image
            AsyncImage(url: URL(string: listing.images.first ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Theme.Colors.surface)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundColor(Theme.Colors.secondaryText)
                    )
            }
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
                
                if let rating = listing.rating {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                        
                        Text("\(rating, specifier: "%.1f")")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.Colors.secondaryText)
                        
                        Text("(\(listing.timesBorrowed))")
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
    }
}

