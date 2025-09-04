//
//  UltraModernMarketplaceView3.swift
//  Brrow
//
//  Ultra modern marketplace with vibrant colors and animations
//

import SwiftUI

struct UltraModernMarketplaceView3: View {
    @StateObject private var viewModel = UltraModernMarketplaceViewModel()
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
            ModernCreateListingView()
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
                        UltraModernFeaturedCard(listing: listing, colors: colors)
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
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.listings, id: \.listingId) { listing in
                        NavigationLink(destination: ListingDetailView(listing: listing)) {
                            UltraModernListingCard(listing: listing, colors: colors)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
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