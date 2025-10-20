//
//  EnhancedOffersView.swift
//  Brrow
//
//  Enhanced offers view with proper theme and no native navigation
//

import SwiftUI

struct EnhancedOffersView: View {
    @State private var selectedTab: OfferTab = .received
    @StateObject private var viewModel = OffersViewModel()
    @Environment(\.dismiss) private var dismiss
    
    enum OfferTab: String, CaseIterable {
        case received = "Received"
        case sent = "Sent"
        case history = "History"
        
        var icon: String {
            switch self {
            case .received: return "tray.and.arrow.down.fill"
            case .sent: return "tray.and.arrow.up.fill"
            case .history: return "clock.fill"
            }
        }
    }
    
    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom header
                customHeader
                
                // Tab selector
                tabSelector
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                
                // Content
                if viewModel.isLoading {
                    loadingView
                } else if currentOffers.isEmpty {
                    emptyState
                } else {
                    offersScrollView
                }
            }
        }
        .onAppear {
            viewModel.fetchOffers()
        }
    }

    // Computed property to get current offers based on selected tab
    private var currentOffers: [Offer] {
        switch selectedTab {
        case .received:
            return viewModel.receivedOffers
        case .sent:
            return viewModel.sentOffers
        case .history:
            // History shows all offers that are not pending
            return (viewModel.receivedOffers + viewModel.sentOffers).filter { $0.status != .pending }
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
            
            Text("My Offers")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Theme.Colors.text)
            
            Spacer()
            
            // Removed plus icon as requested
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal)
        .padding(.top, 60)
        .padding(.bottom, 16)
        .background(Theme.Colors.background)
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(OfferTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20))
                        
                        Text(tab.rawValue)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(selectedTab == tab ? Theme.Colors.primary : Theme.Colors.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        selectedTab == tab ?
                        Theme.Colors.primary.opacity(0.1) : Color.clear
                    )
                    .overlay(
                        Rectangle()
                            .fill(Theme.Colors.primary)
                            .frame(height: 3)
                            .offset(y: 24)
                            .opacity(selectedTab == tab ? 1 : 0),
                        alignment: .bottom
                    )
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.Colors.cardBackground)
        )
    }
    
    // MARK: - Offers ScrollView
    private var offersScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(currentOffers) { offer in
                    EnhancedOfferCard(
                        offer: offer,
                        isSent: selectedTab == .sent,
                        onAccept: { viewModel.acceptOffer(offer) },
                        onReject: { viewModel.rejectOffer(offer) }
                    )
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.primary))
                .scaleEffect(1.5)
            
            Text("Loading offers...")
                .font(.system(size: 16))
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: selectedTab == .received ? "tray.and.arrow.down" : "tray.and.arrow.up")
                .font(.system(size: 80))
                .foregroundColor(Theme.Colors.primary.opacity(0.3))
            
            VStack(spacing: 8) {
                Text("No \(selectedTab.rawValue) Offers")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Theme.Colors.text)
                
                Text(emptyMessage)
                    .font(.system(size: 16))
                    .foregroundColor(Theme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyMessage: String {
        switch selectedTab {
        case .received:
            return "You haven't received any offers yet"
        case .sent:
            return "You haven't sent any offers yet"
        case .history:
            return "Your offer history will appear here"
        }
    }
}

// MARK: - Enhanced Offer Card Component
struct EnhancedOfferCard: View {
    let offer: Offer
    let isSent: Bool
    let onAccept: () -> Void
    let onReject: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Listing image
            if let imageUrl = offer.listing?.images.first?.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Theme.Colors.secondaryBackground)
                        .overlay(
                            ProgressView()
                        )
                }
                .frame(width: 80, height: 80)
                .cornerRadius(12)
            } else {
                Rectangle()
                    .fill(Theme.Colors.secondaryBackground)
                    .frame(width: 80, height: 80)
                    .cornerRadius(12)
                    .overlay(
                        Image(systemName: "cube.box.fill")
                            .font(.title2)
                            .foregroundColor(Theme.Colors.secondary)
                    )
            }

            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(offer.listing?.title ?? "Unknown Item")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
                    .lineLimit(1)

                Text("$\(Int(offer.amount))")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Theme.Colors.primary)

                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.caption)
                    Text(isSent ? (offer.listing?.userId ?? "Unknown") : (offer.borrower?.username ?? "Unknown"))
                        .font(.caption)
                }
                .foregroundColor(Theme.Colors.secondaryText)
            }

            Spacer()

            // Status
            VStack(alignment: .trailing, spacing: 4) {
                StatusPill(status: offer.status.rawValue)

                Text(offer.createdAt.toShortUserFriendlyString())
                    .font(.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.Colors.cardBackground)
                .shadow(color: Theme.Shadows.card, radius: 4, y: 2)
        )
    }
}

// MARK: - Status Pill Component
struct StatusPill: View {
    let status: String

    var body: some View {
        Text(status.capitalized)
            .font(.caption.bold())
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(statusColor)
            )
    }

    private var statusColor: Color {
        switch status.lowercased() {
        case "pending": return .orange
        case "accepted": return .green
        case "rejected": return .red
        case "expired": return .gray
        case "cancelled": return .gray
        default: return Theme.Colors.secondary
        }
    }
}