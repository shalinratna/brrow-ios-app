//
//  HomeView.swift
//  Brrow
//
//  Created by Shalin Ratna on 7/16/25.
//

import SwiftUI
import Combine

struct HomeView: View {
    @EnvironmentObject var viewModel: HomeViewModel
    @State private var showingCreateListing = false
    @State private var searchText = ""
    @State private var selectedQuickFilter = "Popular"
    
    private let quickFilters = ["Nearby", "Popular", "New"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Full-width promo banner
                    promoBanner
                    
                    // Main content with proper spacing
                    VStack(spacing: Theme.Spacing.lg) {
                        // Search section
                        searchSection
                        
                        // Quick access pills
                        quickAccessSection
                        
                        // Recommended section
                        recommendedSection
                        
                        // Recent listings
                        recentListingsSection
                    }
                    .padding(.top, Theme.Spacing.md)
                }
            }
            .background(Theme.Colors.background)
            .navigationBarHidden(true)
            .sheet(isPresented: $showingCreateListing) {
                CreateListingView()
            }
            .onAppear {
                if viewModel.listings.isEmpty {
                    viewModel.loadListings()
                }
            }
            .refreshable {
                viewModel.refreshListings()
            }
        }
    }
    
    // MARK: - Promo Banner (Brand Guideline: Full-width)
    private var promoBanner: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [Theme.Colors.primary, Theme.Colors.secondary],
                startPoint: .leading,
                endPoint: .trailing
            )
            
            VStack(spacing: Theme.Spacing.sm) {
                Text("Welcome to Brrow")
                    .font(Theme.Typography.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Borrow what you need, lend what you don't")
                    .font(Theme.Typography.body)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, Theme.Spacing.xl)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Search Section
    private var searchSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Header with greeting and add button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Good \(timeOfDayGreeting())")
                        .font(Theme.Typography.title)
                        .foregroundColor(Theme.Colors.text)
                    
                    Text("What are you looking for?")
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                
                Spacer()
                
                Button(action: { showingCreateListing = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Theme.Colors.primary)
                        .clipShape(Circle())
                        .shadow(color: Theme.Shadows.button, radius: 4, x: 0, y: 2)
                }
                .pressableScale()
            }
            
            // Elegant search bar
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Theme.Colors.secondaryText)
                    .font(.system(size: 16, weight: .medium))
                
                TextField("Search for items to borrow...", text: $searchText)
                    .font(Theme.Typography.body)
                    .onSubmit {
                        viewModel.searchListings(query: searchText)
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        viewModel.clearSearch()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.surface)
            .cornerRadius(Theme.CornerRadius.card)
            .shadow(color: Theme.Shadows.card, radius: Theme.Shadows.cardRadius, x: 0, y: 2)
        }
        .padding(.horizontal, Theme.Spacing.md)
    }
    
    // MARK: - Quick Access Pills (Brand Guideline)
    private var quickAccessSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("Quick Access")
                    .font(Theme.Typography.title)
                    .foregroundColor(Theme.Colors.text)
                Spacer()
            }
            .padding(.horizontal, Theme.Spacing.md)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.gutter) {
                    ForEach(quickFilters, id: \.self) { filter in
                        Text(filter)
                            .pillButton(isSelected: selectedQuickFilter == filter)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedQuickFilter = filter
                                    applyQuickFilter(filter)
                                }
                            }
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
        }
    }
    
    // MARK: - Recommended Section (Brand Guideline: Horizontal Carousel)
    private var recommendedSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("Recommended For You")
                    .font(Theme.Typography.title)
                    .foregroundColor(Theme.Colors.text)
                Spacer()
                Button("See All") {
                    // Navigate to browse
                }
                .font(Theme.Typography.label)
                .foregroundColor(Theme.Colors.primary)
            }
            .padding(.horizontal, Theme.Spacing.md)
            
            if viewModel.isLoading {
                recommendedLoadingView
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.gutter) {
                        ForEach(Array(viewModel.listings.prefix(5)), id: \.listingId) { listing in
                            NavigationLink(destination: ListingDetailView(listing: listing)) {
                                RecommendedCard(listing: listing)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                }
            }
        }
    }
    
    // MARK: - Recent Listings Grid
    private var recentListingsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("Recently Added")
                    .font(Theme.Typography.title)
                    .foregroundColor(Theme.Colors.text)
                Spacer()
            }
            .padding(.horizontal, Theme.Spacing.md)
            
            if viewModel.listings.isEmpty && !viewModel.isLoading {
                emptyStateView
                    .padding(.horizontal, Theme.Spacing.md)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: Theme.Spacing.gutter),
                    GridItem(.flexible(), spacing: Theme.Spacing.gutter)
                ], spacing: Theme.Spacing.gutter) {
                    ForEach(viewModel.listings, id: \.listingId) { listing in
                        NavigationLink(destination: ListingDetailView(listing: listing)) {
                            HomeModernListingCard(listing: listing)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
        }
    }
    
    // MARK: - Recommended Loading View
    private var recommendedLoadingView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.gutter) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                        .fill(Theme.Colors.surface)
                        .frame(width: 180, height: 140)
                        .shimmerLoading()
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }
    
    // MARK: - Helper Functions
    private func timeOfDayGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Morning"
        case 12..<17: return "Afternoon"
        case 17..<22: return "Evening"
        default: return "Night"
        }
    }
    
    private func applyQuickFilter(_ filter: String) {
        switch filter {
        case "Nearby":
            // Apply location-based filter (sort by distance)
            viewModel.listings.sort { listing1, listing2 in
                // In real implementation, calculate distance from user location
                return listing1.locationString.localizedCompare(listing2.locationString) == .orderedAscending
            }
        case "Popular":
            // Apply popularity filter (sort by view count/favorites)
            viewModel.listings.sort { listing1, listing2 in
                // In real implementation, sort by popularity metrics
                return listing1.title.localizedCompare(listing2.title) == .orderedDescending
            }
        case "New":
            // Apply recent filter (sort by creation date)
            viewModel.listings.sort { listing1, listing2 in
                // In real implementation, sort by creation date
                return listing1.title.localizedCompare(listing2.title) == .orderedAscending
            }
        default:
            break
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 48))
                .foregroundColor(Theme.Colors.primary.opacity(0.6))
            
            Text("No Items Yet")
                .font(Theme.Typography.title)
                .foregroundColor(Theme.Colors.text)
            
            Text("Be the first to share something amazing with your community!")
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
            
            Button(action: { showingCreateListing = true }) {
                Text("Create First Listing")
                    .primaryButtonStyle()
            }
        }
        .padding(.vertical, Theme.Spacing.xl)
        .brandCard()
    }
}

// MARK: - Recommended Card (Horizontal Carousel)
struct RecommendedCard: View {
    let listing: Listing
    @State private var isFavorite = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Image with overlay
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: listing.firstImageUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Theme.Colors.secondary.opacity(0.2))
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(Theme.Colors.secondaryText)
                        )
                }
                .frame(width: 180, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.card))
                
                // Favorite button
                Button(action: { isFavorite.toggle() }) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isFavorite ? Theme.Colors.error : .white)
                        .frame(width: 24, height: 24)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .padding(Theme.Spacing.sm)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(listing.title)
                    .font(Theme.Typography.body)
                    .fontWeight(.medium)
                    .foregroundColor(Theme.Colors.text)
                    .lineLimit(1)
                
                Text(listing.isFree ? "Free" : "$\(Int(listing.price))/day")
                    .font(Theme.Typography.label)
                    .fontWeight(.semibold)
                    .foregroundColor(listing.isFree ? Theme.Colors.success : Theme.Colors.primary)
            }
            .padding(.horizontal, 4)
        }
        .frame(width: 180)
        .onAppear {
            isFavorite = listing.isFavorite
        }
    }
}

// MARK: - Modern Listing Card (Grid)
struct HomeModernListingCard: View {
    let listing: Listing
    @State private var isFavorite = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image with gradient overlay
            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: URL(string: listing.firstImageUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Theme.Colors.secondary.opacity(0.2))
                        .overlay(
                            Image(systemName: "photo")
                                .font(.headline)
                                .foregroundColor(Theme.Colors.secondaryText)
                        )
                }
                .frame(height: 140)
                .clipped()
                
                // Gradient overlay for text readability
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Price badge
                HStack {
                    Text(listing.isFree ? "FREE" : "$\(Int(listing.price))")
                        .font(Theme.Typography.label)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(listing.isFree ? Theme.Colors.success : Theme.Colors.primary)
                        )
                    
                    Spacer()
                    
                    // Favorite button
                    Button(action: { isFavorite.toggle() }) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(isFavorite ? Theme.Colors.error : .white)
                            .frame(width: 28, height: 28)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding(Theme.Spacing.sm)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(listing.title)
                    .font(Theme.Typography.body)
                    .fontWeight(.medium)
                    .foregroundColor(Theme.Colors.text)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    Image(systemName: "location.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.secondary)
                    
                    Text("\(listing.location.city), \(listing.location.state)")
                        .font(Theme.Typography.label)
                        .foregroundColor(Theme.Colors.secondaryText)
                        .lineLimit(1)
                    
                    Spacer()
                }
                
                if !listing.isFree {
                    Text("per day")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
            }
            .padding(Theme.Spacing.md)
        }
        .background(Theme.Colors.surface)
        .cornerRadius(Theme.CornerRadius.card)
        .shadow(color: Theme.Shadows.card, radius: Theme.Shadows.cardRadius, x: 0, y: 2)
        .onAppear {
            isFavorite = listing.isFavorite
        }
    }
}

// MARK: - Legacy Listing Card (keeping for compatibility)
struct ListingCard: View {
    let listing: Listing
    @State private var isFavorite = false
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Image
            AsyncImage(url: URL(string: listing.firstImageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .foregroundColor(Theme.Colors.divider)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.title)
                            .foregroundColor(Theme.Colors.secondaryText)
                    )
            }
            .frame(height: 120)
            .clipped()
            .overlay(
                HStack {
                    Spacer()
                    VStack {
                        Button(action: {
                            toggleFavorite()
                        }) {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .font(.subheadline)
                                .foregroundColor(isFavorite ? Theme.Colors.error : .white)
                                .shadow(color: .black.opacity(0.3), radius: 2)
                        }
                        
                        Spacer()
                    }
                    .padding(Theme.Spacing.sm)
                }
            )
            
            // Content
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(listing.title)
                    .font(Theme.Typography.callout)
                    .fontWeight(.medium)
                    .foregroundColor(Theme.Colors.text)
                    .lineLimit(2)
                
                Text("\(listing.location.city), \(listing.location.state)")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .lineLimit(1)
                
                HStack {
                    Text(listing.isFree ? "Free" : "$\(listing.price)")
                        .font(Theme.Typography.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(listing.isFree ? Theme.Colors.success : Theme.Colors.primary)
                    
                    Spacer()
                    
                    // Show price per day for non-free items
                    if !listing.isFree {
                        Text("$\(listing.price, specifier: "%.2f")")
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.bottom, Theme.Spacing.sm)
        }
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.md)
        .shadow(color: Theme.Shadows.card, radius: 4, x: 0, y: 2)
        .onAppear {
            isFavorite = listing.isFavorite
        }
    }
    
    private func toggleFavorite() {
        isFavorite.toggle()
        PersistenceController.shared.toggleFavorite(listingId: listing.listingId)
        
        // Track favorite action
        let event = AnalyticsEvent(
            eventName: isFavorite ? "listing_favorited" : "listing_unfavorited",
            eventType: "interaction",
            userId: AuthManager.shared.currentUser?.apiId,
            sessionId: AuthManager.shared.sessionId,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            metadata: [
                "listing_id": listing.id,
                "listing_title": listing.title,
                "platform": "ios"
            ]
        )
        
        APIClient.shared.trackAnalytics(event: event)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
}

// MARK: - String Extension
extension String {
    var isNilOrEmpty: Bool {
        return self.isEmpty
    }
}

extension Optional where Wrapped == String {
    var isNilOrEmpty: Bool {
        return self?.isEmpty ?? true
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
