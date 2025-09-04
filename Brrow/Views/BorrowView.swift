//
//  BorrowView.swift
//  Brrow
//
//  Created by Claude Code on 7/19/25.
//

import SwiftUI

struct BorrowView: View {
    @EnvironmentObject var viewModel: OffersViewModel
    @State private var selectedTab = 0
    
    private let tabs = ["My Offers", "My Requests", "Transactions"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom tab selector
                tabSelector
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    offersTab.tag(0)
                    requestsTab.tag(1)
                    transactionsTab.tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .background(Theme.Colors.background)
            .navigationTitle("Borrow")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                }) {
                    Text(tab)
                        .font(Theme.Typography.label)
                        .foregroundColor(selectedTab == index ? .white : Theme.Colors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                                .fill(selectedTab == index ? Theme.Colors.primary : Color.clear)
                        )
                }
            }
        }
        .padding(4)
        .background(Theme.Colors.secondary.opacity(0.1))
        .cornerRadius(Theme.CornerRadius.card)
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.sm)
    }
    
    private var offersTab: some View {
        VStack {
            if viewModel.receivedOffers.isEmpty {
                emptyStateView(title: "No Offers", subtitle: "You haven't received any offers yet")
            } else {
                ScrollView {
                    LazyVStack(spacing: Theme.Spacing.gutter) {
                        ForEach(viewModel.receivedOffers, id: \.id) { offer in
                            BorrowOfferCard(offer: offer, isReceived: true)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                }
            }
        }
    }
    
    private var requestsTab: some View {
        VStack {
            if viewModel.sentOffers.isEmpty {
                emptyStateView(title: "No Requests", subtitle: "You haven't made any borrow requests yet")
            } else {
                ScrollView {
                    LazyVStack(spacing: Theme.Spacing.gutter) {
                        ForEach(viewModel.sentOffers, id: \.id) { offer in
                            BorrowOfferCard(offer: offer, isReceived: false)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                }
            }
        }
    }
    
    private var transactionsTab: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 48))
                .foregroundColor(Theme.Colors.secondaryText)
            
            Text("Transactions")
                .font(Theme.Typography.title)
                .foregroundColor(Theme.Colors.text)
            
            Text("Your transaction history will appear here")
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.Spacing.xl)
    }
    
    
    private func emptyStateView(title: String, subtitle: String) -> some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(Theme.Colors.secondaryText)
            
            Text(title)
                .font(Theme.Typography.title)
                .foregroundColor(Theme.Colors.text)
            
            Text(subtitle)
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.Spacing.xl)
    }
}

// Simple offer card component
struct BorrowOfferCard: View {
    let offer: Offer
    let isReceived: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(offer.listingTitle ?? "Unknown Item")
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.text)
                        .lineLimit(1)
                    
                    Text(isReceived ? "From: \(offer.borrower?.username ?? "Unknown")" : "To: \(offer.senderName)")
                        .font(Theme.Typography.label)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(Int(offer.amount))")
                        .font(Theme.Typography.body)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.Colors.primary)
                    
                    Text(offer.status.rawValue.capitalized)
                        .font(Theme.Typography.label)
                        .foregroundColor(statusColor(for: offer.status))
                }
            }
            
            if let message = offer.message, !message.isEmpty {
                Text(message)
                    .font(Theme.Typography.label)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .lineLimit(2)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface)
        .cornerRadius(Theme.CornerRadius.card)
        .shadow(color: Theme.Shadows.card, radius: Theme.Shadows.cardRadius, x: 0, y: 2)
    }
    
    private func statusColor(for status: OfferStatus) -> Color {
        switch status {
        case .pending:
            return Theme.Colors.warning
        case .accepted:
            return Theme.Colors.success
        case .rejected, .cancelled:
            return Theme.Colors.error
        case .expired:
            return Theme.Colors.secondaryText
        }
    }
}

struct BorrowView_Previews: PreviewProvider {
    static var previews: some View {
        BorrowView()
            .environmentObject(OffersViewModel())
    }
}