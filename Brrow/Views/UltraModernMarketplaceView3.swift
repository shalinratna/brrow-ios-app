//
//  UltraModernMarketplaceView3.swift
//  Brrow
//
//  Ultra modern marketplace with vibrant colors and animations
//

import SwiftUI

struct UltraModernMarketplaceView3: View {
    @StateObject private var viewModel = UltraModernMarketplaceViewModel()
    @StateObject private var predictiveLoader = PredictiveLoadingManager.shared
    @StateObject private var cacheManager = AggressiveCacheManager.shared
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    @State private var showingFilters = false
    @State private var animateGradient = false
    @State private var floatingOffset: CGFloat = 0
    @State private var showingCreateListing = false
    
    // Vibrant color palette
    private let colors = UltraModernColorPalette()
    
    // Grid columns for listings
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dynamic Gradient Background
                dynamicGradientBackground
                .onAppear {
                    print("🎨 UltraModernMarketplaceView3 loaded!")

                    // 🚀 PREDICTIVE LOADING: Preload marketplace data and images
                    Task {
                        await predictiveLoader.preloadMarketplaceData()
                        await cacheManager.preloadListingImages(viewModel.listings)
                    }
                }
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Hero Header Section
                        heroHeaderSection
                            .padding(.top, 10)
                        
                        // Animated Search Bar
                        modernSearchSection
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        
                        // Vibrant Category Pills
                        vibrantCategorySection
                            .padding(.top, 25)
                        
                        // Quick Stats Dashboard
                        modernStatsSection
                            .padding(.horizontal, 20)
                            .padding(.top, 30)

                        // Nearby Seeks Section
                        nearbySeeksSection
                            .padding(.horizontal, 20)
                            .padding(.top, 30)

                        // Featured Banner Carousel
                        if !viewModel.featuredListings.isEmpty {
                            featuredCarouselSection
                                .padding(.top, 30)
                        }
                        
                        // Main Listings Grid
                        modernListingsGrid
                            .padding(.horizontal, 20)
                            .padding(.top, 30)
                        
                        Spacer(minLength: 120)
                    }
                }
                .refreshable {
                    await viewModel.refreshData()
                }
                
                // Floating Action Button
                floatingCreateButton
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingFilters) {
            MarketplaceFiltersView(selectedCategory: $selectedCategory) { filters in
                // Handle filters
            }
        }
        .sheet(isPresented: $showingCreateListing) {
            EnhancedCreateListingView()
        }
        .onAppear {
            viewModel.loadMarketplace()
            startAnimations()
        }
    }
    
    // MARK: - Dynamic Gradient Background
    private var dynamicGradientBackground: some View {
        LinearGradient(
            colors: animateGradient ? [
                colors.vibrantPurple.opacity(0.6),
                colors.vibrantBlue.opacity(0.4),
                colors.vibrantTeal.opacity(0.3),
                colors.vibrantPink.opacity(0.2)
            ] : [
                colors.vibrantBlue.opacity(0.4),
                colors.vibrantTeal.opacity(0.5),
                colors.vibrantPurple.opacity(0.3),
                colors.vibrantOrange.opacity(0.2)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: animateGradient)
    }
    
    // MARK: - Hero Header
    private var heroHeaderSection: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Marketplace")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    
                    Text("Discover amazing items near you")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                // Profile button with colorful ring
                Button(action: {}) {
                    ZStack {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [colors.vibrantPink, colors.vibrantOrange, colors.vibrantBlue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 50, height: 50)
                            .rotationEffect(.degrees(animateGradient ? 360 : 0))
                            .animation(.linear(duration: 8).repeatForever(autoreverses: false), value: animateGradient)
                        
                        Circle()
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "person.fill")
                            .font(.system(size: 20))
                            .foregroundColor(colors.vibrantPurple)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Modern Search Section  
    private var modernSearchSection: some View {
        HStack(spacing: 12) {
            // Search bar with glass morphism
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(colors.vibrantBlue)
                
                TextField("Search anything...", text: $searchText)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .onSubmit {
                        viewModel.performSearch(searchText)
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        viewModel.clearSearch()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.gray.opacity(0.7))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.95))
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
            )
            
            // Filter button
            Button(action: { showingFilters = true }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [colors.vibrantPink, colors.vibrantOrange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(color: colors.vibrantPink.opacity(0.4), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    // MARK: - Vibrant Category Section
    private var vibrantCategorySection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(UltraModernCategory.allCases, id: \.self) { category in
                    VibrantCategoryPill(
                        category: category,
                        isSelected: selectedCategory == category.rawValue,
                        colors: colors
                    ) {
                        selectedCategory = selectedCategory == category.rawValue ? nil : category.rawValue
                        viewModel.filterByCategory(selectedCategory)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Modern Stats Section
    private var modernStatsSection: some View {
        HStack(spacing: 12) {
            UltraModernStatCard(
                title: "Available",
                value: "\(viewModel.totalListings)",
                icon: "cube.box.fill",
                color: colors.vibrantTeal,
                animationDelay: 0.1
            )
            
            UltraModernStatCard(
                title: "Active Users",
                value: "\(viewModel.activeUsers)",
                icon: "person.2.fill",
                color: colors.vibrantPurple,
                animationDelay: 0.2
            )
            
            UltraModernStatCard(
                title: "Today's Deals",
                value: "\(viewModel.todaysDeals)",
                icon: "flame.fill",
                color: colors.vibrantOrange,
                animationDelay: 0.3
            )
        }
    }

    // MARK: - Nearby Seeks Section
    private var nearbySeeksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass.circle.fill")
                        .font(.title2)
                        .foregroundColor(colors.vibrantPink)

                    Text("🔍 Nearby Seeks")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                }

                Spacer()

                NavigationLink("View all") {
                    SeeksView()
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(colors.vibrantTeal)
            }

            if viewModel.nearbySeeks.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(colors.vibrantPink.opacity(0.6))

                    Text("No seeks nearby")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))

                    Text("Be the first to post what you're looking for!")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)

                    NavigationLink("Create Seek") {
                        ModernCreateSeekView()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(colors.vibrantPink)
                    )
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(colors.vibrantPink.opacity(0.3), lineWidth: 1)
                        )
                )
            } else {
                // Seeks horizontal scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.nearbySeeks.prefix(5), id: \.id) { seek in
                            NearbySeekCard(seek: seek, colors: colors)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    // MARK: - Featured Carousel
    private var featuredCarouselSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("✨ Featured")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                
                Spacer()
                
                Button("See all") {
                    // Handle see all
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(colors.vibrantPink)
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.featuredListings, id: \.id) { listing in
                        Button(action: {
                            ListingNavigationManager.shared.showListing(listing)
                        }) {
                            UltraModernFeaturedCard(listing: listing, colors: colors)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Modern Listings Grid
    private var modernListingsGrid: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section header
            HStack {
                Text("🔥 All Items")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                
                Spacer()
                
                // Sort menu
                Menu {
                    Button("Newest First") { viewModel.sortBy(.newest) }
                    Button("Price: Low to High") { viewModel.sortBy(.priceLowToHigh) }
                    Button("Price: High to Low") { viewModel.sortBy(.priceHighToLow) }
                    Button("Distance") { viewModel.sortBy(.distance) }
                } label: {
                    HStack(spacing: 8) {
                        Text("Sort")
                            .font(.system(size: 16, weight: .semibold))
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(colors.vibrantBlue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.9))
                    )
                }
            }
            
            // Listings grid
            if viewModel.isLoading && viewModel.listings.isEmpty {
                ModernLoadingGrid(colors: colors)
            } else if viewModel.listings.isEmpty {
                ModernEmptyState(colors: colors) {
                    showingCreateListing = true
                }
            } else {
                DynamicMarketplaceGrid(listings: viewModel.listings, colors: colors)

                // Load more button
                if viewModel.hasMore {
                    ModernLoadMoreButton(
                        isLoading: viewModel.isLoadingMore,
                        colors: colors
                    ) {
                        viewModel.loadMore()
                    }
                    .padding(.top, 20)
                }
            }
        }
    }
    
    // MARK: - Floating Action Button
    private var floatingCreateButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                
                Button(action: { showingCreateListing = true }) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [colors.vibrantPink, colors.vibrantOrange, colors.vibrantBlue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 68, height: 68)
                            .shadow(color: colors.vibrantPink.opacity(0.4), radius: 12, x: 0, y: 6)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .offset(y: floatingOffset)
                .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: floatingOffset)
                .padding(.trailing, 20)
                .padding(.bottom, 30)
            }
        }
    }
    
    // MARK: - Helper Functions
    private func startAnimations() {
        animateGradient = true
        floatingOffset = -8
    }
}

// MARK: - Dynamic Marketplace Grid
struct DynamicMarketplaceGrid: View {
    let listings: [Listing]
    let colors: UltraModernColorPalette

    // Different card types for visual variety
    enum CardType {
        case large      // 2x2 grid space
        case tall       // 1x2 grid space (vertical)
        case wide       // 2x1 grid space (horizontal)
        case regular    // 1x1 grid space
    }

    private func getCardType(for index: Int) -> CardType {
        let patterns: [CardType] = [.large, .regular, .tall, .regular, .wide, .regular, .regular]
        return patterns[index % patterns.count]
    }

    private func getCardHeight(for type: CardType) -> CGFloat {
        switch type {
        case .large: return 280
        case .tall: return 280
        case .wide: return 160
        case .regular: return 220
        }
    }

    var body: some View {
        LazyVStack(spacing: 16) {
            ForEach(Array(stride(from: 0, to: listings.count, by: 6)), id: \.self) { rowIndex in
                createRow(startingIndex: rowIndex)
            }
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func createRow(startingIndex: Int) -> some View {
        let remainingItems = min(6, listings.count - startingIndex)

        if remainingItems >= 6 {
            // Full pattern: Large + 2 Regular + Tall + Wide
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    // Large card (2x2)
                    if startingIndex < listings.count {
                        listingCard(listings[startingIndex], type: .large)
                            .frame(height: getCardHeight(for: .large))
                    }

                    VStack(spacing: 12) {
                        // Two regular cards stacked
                        if startingIndex + 1 < listings.count {
                            listingCard(listings[startingIndex + 1], type: .regular)
                                .frame(height: 134)
                        }
                        if startingIndex + 2 < listings.count {
                            listingCard(listings[startingIndex + 2], type: .regular)
                                .frame(height: 134)
                        }
                    }
                }

                HStack(spacing: 12) {
                    // Tall card
                    if startingIndex + 3 < listings.count {
                        listingCard(listings[startingIndex + 3], type: .tall)
                            .frame(width: (UIScreen.main.bounds.width - 44) * 0.35)
                            .frame(height: getCardHeight(for: .tall))
                    }

                    VStack(spacing: 12) {
                        // Wide card
                        if startingIndex + 4 < listings.count {
                            listingCard(listings[startingIndex + 4], type: .wide)
                                .frame(height: getCardHeight(for: .wide))
                        }

                        // Regular card
                        if startingIndex + 5 < listings.count {
                            listingCard(listings[startingIndex + 5], type: .regular)
                                .frame(height: 108)
                        }
                    }
                }
            }
        } else {
            // Simplified layout for remaining items
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(startingIndex..<startingIndex + remainingItems, id: \.self) { index in
                    if index < listings.count {
                        listingCard(listings[index], type: .regular)
                            .frame(height: getCardHeight(for: .regular))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func listingCard(_ listing: Listing, type: CardType) -> some View {
        Button(action: {
            ListingNavigationManager.shared.showListing(listing)
        }) {
            DynamicListingCard(listing: listing, cardType: type, colors: colors)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Dynamic Listing Card
struct DynamicListingCard: View {
    let listing: Listing
    let cardType: DynamicMarketplaceGrid.CardType
    let colors: UltraModernColorPalette

    var body: some View {
        ZStack {
            // Background with gradient based on card type
            RoundedRectangle(cornerRadius: cardType == .large ? 24 : 16)
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cardType == .large ? 24 : 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )

            // Content layout varies by card type
            cardContent
        }
        .shadow(color: .black.opacity(0.1), radius: cardType == .large ? 12 : 8, x: 0, y: 4)
    }

    private var gradientColors: [Color] {
        switch cardType {
        case .large:
            return [colors.vibrantPurple, colors.vibrantPink]
        case .tall:
            return [colors.vibrantBlue, colors.vibrantTeal]
        case .wide:
            return [colors.vibrantOrange, colors.vibrantYellow]
        case .regular:
            return [colors.vibrantTeal, colors.vibrantBlue]
        }
    }

    @ViewBuilder
    private var cardContent: some View {
        switch cardType {
        case .large:
            largeCardLayout
        case .tall:
            tallCardLayout
        case .wide:
            wideCardLayout
        case .regular:
            regularCardLayout
        }
    }

    private var largeCardLayout: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image
            BrrowAsyncImage(url: listing.firstImageUrl ?? "") { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 140)
                    .clipped()
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 140)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 30))
                            .foregroundColor(.gray.opacity(0.5))
                    )
            }
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    VStack {
                        HStack {
                            Spacer()
                            Text(listing.listingTypeDisplay)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Capsule())
                        }
                        Spacer()
                    }
                    .padding(8)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(listing.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(2)

                Text(listing.priceDisplay)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.white.opacity(0.8))
                    Text(listing.location.city)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    private var tallCardLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            BrrowAsyncImage(url: listing.firstImageUrl ?? "") { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 140)
                    .clipped()
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 140)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 30))
                            .foregroundColor(.gray.opacity(0.5))
                    )
            }
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(listing.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(2)

                Text(listing.priceDisplay)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(listing.location.city)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
    }

    private var wideCardLayout: some View {
        HStack(spacing: 12) {
            BrrowAsyncImage(url: listing.firstImageUrl ?? "") { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipped()
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 20))
                            .foregroundColor(.gray.opacity(0.5))
                    )
            }
            .frame(width: 100, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(listing.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(2)

                Text(listing.priceDisplay)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(listing.location.city)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
        }
        .padding(12)
    }

    private var regularCardLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            BrrowAsyncImage(url: listing.firstImageUrl ?? "") { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 120)
                    .clipped()
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 120)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 25))
                            .foregroundColor(.gray.opacity(0.5))
                    )
            }
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(listing.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(listing.priceDisplay)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(listing.location.city)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
    }
}