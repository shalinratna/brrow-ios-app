//
//  TrendingListingCard.swift
//  Brrow
//
//  Card component for trending listings
//

import SwiftUI

struct TrendingListingCard: View {
    let listing: Listing
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: URL(string: listing.images.first ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Theme.Colors.surface)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(Theme.Colors.secondaryText)
                    )
            }
            .frame(height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(listing.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
                    .lineLimit(1)
                
                Text("$\(listing.price, specifier: "%.0f")/day")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Theme.Colors.primary)
            }
        }
        .frame(width: 120)
    }
}

