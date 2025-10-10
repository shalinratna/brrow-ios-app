//
//  ListingStatusBadge.swift
//  Brrow
//
//  Professional status badge component for new listing status system
//

import SwiftUI

struct ListingStatusBadge: View {
    let listing: Listing
    let size: BadgeSize

    enum BadgeSize {
        case small
        case medium
        case large

        var fontSize: CGFloat {
            switch self {
            case .small: return 10
            case .medium: return 12
            case .large: return 14
            }
        }

        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6)
            case .medium: return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
            case .large: return EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10)
            }
        }
    }

    init(listing: Listing, size: BadgeSize = .medium) {
        self.listing = listing
        self.size = size
    }

    var body: some View {
        Text(listing.statusDisplayText)
            .font(.system(size: size.fontSize, weight: .semibold))
            .foregroundColor(.white)
            .padding(size.padding)
            .background(badgeBackgroundColor)
            .cornerRadius(12)
    }

    private var badgeBackgroundColor: Color {
        switch listing.statusBadgeColor {
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "orange": return .orange
        case "yellow": return .yellow
        case "gray": return .gray
        case "red": return .red
        default: return .gray
        }
    }
}

// MARK: - Convenience Extensions
extension View {
    func listingStatusBadge(_ listing: Listing, size: ListingStatusBadge.BadgeSize = .medium) -> some View {
        self.overlay(
            ListingStatusBadge(listing: listing, size: size)
                .padding(8),
            alignment: .topTrailing
        )
    }
}

// MARK: - Preview
struct ListingStatusBadge_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Available
            ListingStatusBadge(listing: Listing.example, size: .small)
            ListingStatusBadge(listing: Listing.example, size: .medium)
            ListingStatusBadge(listing: Listing.example, size: .large)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
