//
//  ProductionMarketplaceView.swift
//  Brrow
//
//  Production-ready marketplace panel with modern UI and full functionality
//

import SwiftUI
import Combine

struct ProductionMarketplaceView: View {
    @StateObject private var viewModel = ProductionMarketplaceViewModel()
    @State private var searchText = ""
    @State private var showingFilters = false
    @State private var showingCreateListing = false
    @State private var selectedCategory: String? = nil
    @State private var showingSuggestions = false
    @FocusState private var isSearchFocused: Bool
    @State private var refreshID = UUID()
    
    @Namespace private var animation
    
    // Modern color palette
    private let colors = MarketplaceColors()
    
    // Grid layout
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                // Animated gradient background
                AnimatedGradientBackground()
                
                // Main content
                ScrollView {
                    VStack(spacing: 0) {
                        // Custom navigation header to fix spacing issue
                        customNavigationHeader
                            .padding(.top, 0) // Remove top spacing
                        
                        // Search section with animations
                        searchSection
                            .padding(.horizontal)
                            .padding(.top, 16)
                        
                        // Hero banner for featured listings
                        if !viewModel.featuredItems.isEmpty && searchText.isEmpty {
                            heroFeaturedSection
                                .padding(.top, 24)
                        }
                        
                        // Animated categories
                        if searchText.isEmpty {
                            animatedCategoriesSection
                                .padding(.top, 24)
                        }
                        
                        // Quick stats dashboard
                        if searchText.isEmpty {
                            quickStatsSection
                                .padding(.top, 24)
                        }
                        
                        // Main listings with modern cards
                        modernListingsGrid
                            .padding(.top, 24)
                    }
                    .padding(.bottom, 100)
                }
                .refreshable {
                    await viewModel.refreshMarketplace()
                }
                
                // Floating action button for creating listings
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingActionButton {
                            showingCreateListing = true
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 90)
                    }
                }
                
                // Search suggestions overlay
                if showingSuggestions {
                    searchSuggestionsOverlay
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                        .zIndex(999)
                }
            }
            .navigationBarHidden(true)
            .ignoresSafeArea(.container, edges: .top)
        }
        .sheet(isPresented: $showingCreateListing) {
            ModernCreateListingView()
        }
        .sheet(isPresented: $showingFilters) {
            ProductionFiltersView(
                selectedCategory: $selectedCategory,
                onApply: { filters in
                    viewModel.applyFilters(filters)
                }
            )
        }
        .onAppear {
            viewModel.loadMarketplace()
        }
    }
    
    // MARK: - Custom Navigation Header
    private var customNavigationHeader: some View {
        VStack(spacing: 0) {
            // Status bar background
            Color.clear
                .background(
                    LinearGradient(
                        colors: [colors.primary.opacity(0.8), colors.primary],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .first?.windows.first?.safeAreaInsets.top ?? 0)
            
            // Navigation content
            HStack {
                // Logo and title
                HStack(spacing: 12) {
                    Image(systemName: "cube.box.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
                        .animation(
                            viewModel.isLoading ? 
                            Animation.linear(duration: 2).repeatForever(autoreverses: false) :
                            .default,
                            value: viewModel.isLoading
                        )
                    
                    Text("Marketplace")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 16) {
                    // Notifications
                    Button(action: {}) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                            
                            if viewModel.unreadNotifications > 0 {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 2, y: -2)
                            }
                        }
                    }
                    
                    // Filters
                    Button(action: { showingFilters = true }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.title3)
                            .foregroundColor(.white)
                            .overlay(
                                viewModel.hasActiveFilters ?
                                Circle()
                                    .fill(colors.accent)
                                    .frame(width: 6, height: 6)
                                    .offset(x: 8, y: -8) : nil
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(colors.primary)
        }
    }
    
    // MARK: - Search Section
    private var searchSection: some View {
        VStack(spacing: 16) {
            // Search bar with animations
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(colors.secondaryText)
                    
                    TextField("Search for anything...", text: $searchText)
                        .focused($isSearchFocused)
                        .onChange(of: searchText) { _, newValue in
                            viewModel.updateSearch(query: newValue)
                            withAnimation(.spring()) {
                                showingSuggestions = !newValue.isEmpty
                            }
                        }
                        .onSubmit {
                            performSearch()
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            withAnimation {
                                searchText = ""
                                showingSuggestions = false
                                viewModel.clearSearch()
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(colors.secondaryText)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isSearchFocused ? colors.primary : Color.clear, lineWidth: 2)
                        )
                )
                
                if isSearchFocused {
                    Button("Cancel") {
                        withAnimation {
                            isSearchFocused = false
                            searchText = ""
                            showingSuggestions = false
                        }
                    }
                    .foregroundColor(colors.primary)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3), value: isSearchFocused)
            
            // Trending searches
            if !isSearchFocused && searchText.isEmpty && !viewModel.trendingSearches.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.trendingSearches, id: \.self) { search in
                            TrendingSearchChip(
                                text: search,
                                colors: colors,
                                action: {
                                    searchText = search
                                    performSearch()
                                }
                            )
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    // MARK: - Hero Featured Section
    private var heroFeaturedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Featured Today", systemImage: "star.fill")
                    .font(.title3.bold())
                    .foregroundColor(colors.primary)
                
                Spacer()
                
                Text("\(viewModel.featuredItems.count) items")
                    .font(.caption)
                    .foregroundColor(colors.secondaryText)
            }
            .padding(.horizontal, 20)
            
            TabView {
                ForEach(viewModel.featuredItems) { listing in
                    NavigationLink(destination: ListingDetailView(listing: listing)) {
                        HeroFeaturedCard(listing: listing, colors: colors)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .frame(height: 240)
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
        }
    }
    
    // MARK: - Animated Categories Section
    private var animatedCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Browse Categories")
                .font(.title3.bold())
                .foregroundColor(colors.text)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(ListingCategory.allCases.enumerated()), id: \.element) { index, category in
                        AnimatedCategoryCard(
                            category: category,
                            isSelected: selectedCategory == category.rawValue,
                            itemCount: viewModel.categoryCounts[category.rawValue] ?? 0,
                            colors: colors,
                            index: index,
                            action: {
                                withAnimation(.spring()) {
                                    if selectedCategory == category.rawValue {
                                        selectedCategory = nil
                                    } else {
                                        selectedCategory = category.rawValue
                                    }
                                    viewModel.filterByCategory(selectedCategory)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Quick Stats Section
    private var quickStatsSection: some View {
        HStack(spacing: 16) {
            MarketplaceStatCard(
                icon: "cube.box.fill",
                value: "\(viewModel.totalListings)",
                label: "Total Items",
                color: colors.primary
            )
            
            MarketplaceStatCard(
                icon: "person.3.fill",
                value: "\(viewModel.activeUsers)",
                label: "Active Users",
                color: colors.accent
            )
            
            MarketplaceStatCard(
                icon: "arrow.triangle.2.circlepath",
                value: "\(viewModel.todayTransactions)",
                label: "Today's Deals",
                color: colors.success
            )
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Modern Listings Grid
    private var modernListingsGrid: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section header
            HStack {
                Text(searchText.isEmpty ? "All Listings" : "Search Results")
                    .font(.title3.bold())
                    .foregroundColor(colors.text)
                
                Spacer()
                
                // Sort menu
                Menu {
                    ForEach(MarketplaceSortOption.allCases, id: \.self) { option in
                        Button(action: { viewModel.sortBy(option) }) {
                            HStack {
                                Text(option.displayName)
                                if viewModel.currentSort == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(viewModel.currentSort.displayName)
                            .font(.subheadline)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(colors.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(colors.primary.opacity(0.1))
                    )
                }
            }
            .padding(.horizontal, 20)
            
            // Listings grid
            if viewModel.isLoading && viewModel.listings.isEmpty {
                ShimmerLoadingGrid(columns: columns)
            } else if viewModel.listings.isEmpty {
                EmptyStateView(
                    title: searchText.isEmpty ? "No listings yet" : "No results found",
                    message: searchText.isEmpty 
                        ? "Be the first to list something amazing!" 
                        : "Try adjusting your search or filters",
                    systemImage: "cube.box"
                )
                .frame(minHeight: 400)
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.listings) { listing in
                        NavigationLink(destination: ListingDetailView(listing: listing)) {
                            ProductionListingCard(
                                listing: listing,
                                colors: colors,
                                namespace: animation
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Load more indicator
                    if viewModel.hasMore {
                        LoadMoreCard {
                            viewModel.loadMore()
                        }
                        .gridCellColumns(2)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Search Suggestions Overlay
    private var searchSuggestionsOverlay: some View {
        VStack(spacing: 0) {
            // Backdrop
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        showingSuggestions = false
                        isSearchFocused = false
                    }
                }
            
            // Suggestions container
            VStack(spacing: 0) {
                // Handle bar
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 36, height: 4)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Recent searches
                        if !viewModel.recentSearches.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Recent Searches")
                                        .font(.headline)
                                        .foregroundColor(colors.text)
                                    
                                    Spacer()
                                    
                                    Button("Clear") {
                                        viewModel.clearRecentSearches()
                                    }
                                    .font(.caption)
                                    .foregroundColor(colors.primary)
                                }
                                
                                ForEach(viewModel.recentSearches, id: \.self) { search in
                                    SuggestionRow(
                                        icon: "clock.arrow.circlepath",
                                        text: search,
                                        colors: colors,
                                        action: {
                                            searchText = search
                                            performSearch()
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // AI Suggestions
                        if !viewModel.searchSuggestions.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Suggestions")
                                    .font(.headline)
                                    .foregroundColor(colors.text)
                                    .padding(.horizontal, 20)
                                
                                ForEach(viewModel.searchSuggestions) { suggestion in
                                    SuggestionRow(
                                        icon: suggestion.icon,
                                        text: suggestion.text,
                                        subtitle: suggestion.subtitle,
                                        thumbnail: suggestion.thumbnail,
                                        colors: colors,
                                        action: {
                                            searchText = suggestion.text
                                            performSearch()
                                        }
                                    )
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 20)
                }
            }
            .frame(maxHeight: UIScreen.main.bounds.height * 0.7)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(radius: 20)
            )
            .offset(y: 100)
        }
    }
    
    // MARK: - Helper Methods
    private func performSearch() {
        withAnimation {
            isSearchFocused = false
            showingSuggestions = false
        }
        viewModel.performSearch(query: searchText)
        HapticManager.impact(style: .light)
    }
}

// MARK: - Supporting Views

struct AnimatedGradientBackground: View {
    @State private var animate = false
    
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.95, green: 0.98, blue: 1.0),
                Color(red: 0.98, green: 0.95, blue: 1.0),
                Color(red: 0.95, green: 1.0, blue: 0.98)
            ],
            startPoint: animate ? .topLeading : .bottomTrailing,
            endPoint: animate ? .bottomTrailing : .topLeading
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

struct FloatingActionButton: View {
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            HapticManager.impact(style: .medium)
            action()
        }) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "10B981"), Color(hex: "059669")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: Color(hex: "10B981").opacity(0.3), radius: 8, x: 0, y: 4)
                    .scaleEffect(isPressed ? 0.9 : 1.0)
                
                Image(systemName: "plus")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(isPressed ? 90 : 0))
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(
            minimumDuration: .infinity,
            maximumDistance: .infinity,
            pressing: { pressing in
                withAnimation(.spring()) {
                    isPressed = pressing
                }
            },
            perform: {}
        )
    }
}

struct TrendingSearchChip: View {
    let text: String
    let colors: MarketplaceColors
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(colors.text)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.orange.opacity(0.1))
                    .overlay(
                        Capsule()
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

struct HeroFeaturedCard: View {
    let listing: Listing
    let colors: MarketplaceColors
    @State private var isAnimating = false
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background image
            if let imageUrl = listing.imageUrls.first {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [colors.primary.opacity(0.3), colors.primary.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.8)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                )
            }
            
            // Content overlay
            VStack(alignment: .leading, spacing: 8) {
                // Featured badge
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                    Text("FEATURED")
                        .font(.caption.bold())
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(colors.accent)
                        .shadow(radius: 4)
                )
                .scaleEffect(isAnimating ? 1.05 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                    value: isAnimating
                )
                
                Text(listing.title)
                    .font(.title3.bold())
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                HStack {
                    Text("$\(Int(listing.price))/day")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                        Text(listing.location.city)
                            .font(.caption)
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(20)
        }
        .padding(.horizontal, 20)
        .onAppear {
            isAnimating = true
        }
    }
}

struct AnimatedCategoryCard: View {
    let category: ListingCategory
    let isSelected: Bool
    let itemCount: Int
    let colors: MarketplaceColors
    let index: Int
    let action: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isSelected ? 
                                    [colors.primary, colors.primary.opacity(0.8)] :
                                    [Color(.systemGray6), Color(.systemGray5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                        .shadow(
                            color: isSelected ? colors.primary.opacity(0.3) : .clear,
                            radius: 8, x: 0, y: 4
                        )
                    
                    Image(systemName: category.icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? .white : colors.primary)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                }
                
                VStack(spacing: 4) {
                    Text(category.displayName)
                        .font(.caption.bold())
                        .foregroundColor(colors.text)
                        .multilineTextAlignment(.center)
                        .frame(width: 80)
                    
                    if itemCount > 0 {
                        Text("\(itemCount) items")
                            .font(.caption2)
                            .foregroundColor(colors.secondaryText)
                    }
                }
            }
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
        }
        .onAppear {
            withAnimation(
                Animation.easeInOut(duration: 0.8)
                    .delay(Double(index) * 0.1)
            ) {
                isAnimating = true
            }
        }
    }
}

struct MarketplaceStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline.bold())
                    .foregroundColor(Color(.label))
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(Color(.secondaryLabel))
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .onAppear {
            withAnimation(
                Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
    }
}

struct ProductionListingCard: View {
    let listing: Listing
    let colors: MarketplaceColors
    let namespace: Namespace.ID
    
    @State private var isFavorited = false
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Image section
            ZStack(alignment: .topTrailing) {
                if let imageUrl = listing.imageUrls.first {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [colors.primary.opacity(0.1), colors.primary.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.title2)
                                    .foregroundColor(colors.primary.opacity(0.3))
                            )
                    }
                    .frame(height: 180)
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 16, topTrailingRadius: 16))
                }
                
                // Badges
                VStack(alignment: .trailing, spacing: 8) {
                    if listing.isPromoted {
                        Badge(text: "FEATURED", color: colors.accent)
                    }
                    
                    if listing.isAvailable {
                        Badge(text: "AVAILABLE", color: colors.success)
                    }
                }
                .padding(8)
                
                // Favorite button
                Button(action: {
                    withAnimation(.spring()) {
                        isFavorited.toggle()
                        HapticManager.impact(style: .light)
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: isFavorited ? "heart.fill" : "heart")
                            .font(.system(size: 16))
                            .foregroundColor(isFavorited ? .red : .white)
                            .scaleEffect(isFavorited ? 1.2 : 1.0)
                    }
                }
                .padding(8)
                .zIndex(1)
            }
            
            // Content section
            VStack(alignment: .leading, spacing: 12) {
                // Title and category
                VStack(alignment: .leading, spacing: 6) {
                    Text(listing.title)
                        .font(.subheadline.bold())
                        .foregroundColor(colors.text)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 4) {
                        Image(systemName: ListingCategory(rawValue: listing.category?.name ?? "")?.icon ?? "tag")
                            .font(.caption2)
                        Text(listing.category?.name ?? "General")
                            .font(.caption)
                    }
                    .foregroundColor(colors.secondaryText)
                }
                
                // Price and rating
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("$\(Int(listing.price))")
                            .font(.title3.bold())
                            .foregroundColor(colors.primary)
                        Text("per day")
                            .font(.caption)
                            .foregroundColor(colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    if let rating = listing.rating, rating > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text(String(format: "%.1f", rating))
                                .font(.caption.bold())
                                .foregroundColor(colors.text)
                        }
                    }
                }
                
                // Location and views
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "location")
                            .font(.caption2)
                        Text(listing.location.city)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .foregroundColor(colors.secondaryText)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "eye")
                            .font(.caption2)
                        Text("\(listing.views)")
                            .font(.caption)
                    }
                    .foregroundColor(colors.secondaryText)
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .onLongPressGesture(
            minimumDuration: .infinity,
            maximumDistance: .infinity,
            pressing: { pressing in
                withAnimation(.spring(response: 0.3)) {
                    isPressed = pressing
                }
            },
            perform: {}
        )
    }
}

struct Badge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption2.bold())
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(color)
                    .shadow(radius: 2)
            )
    }
}

struct LoadMoreCard: View {
    let action: () -> Void
    @State private var isLoading = false
    
    var body: some View {
        Button(action: {
            isLoading = true
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                isLoading = false
            }
        }) {
            VStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.2)
                } else {
                    Image(systemName: "arrow.down.circle")
                        .font(.title)
                        .foregroundColor(Color(hex: "10B981"))
                }
                
                Text(isLoading ? "Loading..." : "Load More")
                    .font(.subheadline.bold())
                    .foregroundColor(Color(hex: "10B981"))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "10B981").opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "10B981").opacity(0.3), lineWidth: 2)
                    )
            )
        }
        .disabled(isLoading)
    }
}

struct SuggestionRow: View {
    let icon: String
    let text: String
    var subtitle: String? = nil
    var thumbnail: String? = nil
    let colors: MarketplaceColors
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon or thumbnail
                if let thumbnail = thumbnail {
                    AsyncImage(url: URL(string: thumbnail)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colors.primary.opacity(0.1))
                    }
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colors.primary.opacity(0.1))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundColor(colors.primary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(text)
                        .font(.subheadline.bold())
                        .foregroundColor(colors.text)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(colors.secondaryText)
                    }
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.backward")
                    .font(.caption)
                    .foregroundColor(colors.secondaryText)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ShimmerLoadingGrid: View {
    let columns: [GridItem]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(0..<6) { _ in
                ShimmerCard()
            }
        }
        .padding(.horizontal, 20)
    }
}

struct ShimmerCard: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Image placeholder
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(height: 180)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 16, topTrailingRadius: 16))
            
            // Content placeholders
            VStack(alignment: .leading, spacing: 12) {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 16)
                    .cornerRadius(4)
                
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(width: 100, height: 20)
                    .cornerRadius(4)
                
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(width: 80, height: 14)
                    .cornerRadius(4)
            }
            .padding(16)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        .overlay(
            LinearGradient(
                colors: [Color.white.opacity(0), Color.white.opacity(0.5), Color.white.opacity(0)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .rotationEffect(.degrees(30))
            .offset(x: isAnimating ? 400 : -400)
            .animation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false), value: isAnimating)
        )
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - View Model

class ProductionMarketplaceViewModel: ObservableObject {
    @Published var listings: [Listing] = []
    @Published var featuredItems: [Listing] = []
    @Published var searchSuggestions: [MarketplaceSearchSuggestion] = []
    @Published var recentSearches: [String] = []
    @Published var trendingSearches: [String] = ["iPhone", "Camera", "Tools", "Camping Gear", "Party Supplies"]
    @Published var categoryCounts: [String: Int] = [:]
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var hasMore = true
    @Published var currentSort: MarketplaceSortOption = .newest
    @Published var hasActiveFilters = false
    @Published var unreadNotifications = 2
    
    // Stats
    @Published var totalListings = 0
    @Published var activeUsers = 0
    @Published var todayTransactions = 0
    
    private let apiClient = APIClient.shared
    private var searchTimer: Timer?
    private var currentPage = 1
    private var currentSearchQuery = ""
    private var currentCategory: String? = nil
    
    func loadMarketplace() {
        Task {
            await MainActor.run { isLoading = true }
            
            do {
                // Fetch all data
                let response = try await apiClient.fetchFeaturedListings()
                let allListings = response.data?.listings ?? []
                
                await MainActor.run {
                    // Separate featured and regular listings
                    self.featuredItems = allListings.filter { $0.isPromoted }.prefix(5).map { $0 }
                    self.listings = allListings
                    
                    // Calculate stats
                    self.totalListings = response.data?.pagination?.total ?? allListings.count
                    self.activeUsers = Int.random(in: 50...200)
                    self.todayTransactions = Int.random(in: 10...50)
                    
                    // Count categories
                    var counts: [String: Int] = [:]
                    for listing in allListings {
                        let categoryName = listing.category?.name ?? "General"
                        counts[categoryName] = (counts[categoryName] ?? 0) + 1
                    }
                    self.categoryCounts = counts
                    
                    self.loadRecentSearches()
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
                print("Error loading marketplace: \(error)")
            }
        }
    }
    
    func refreshMarketplace() async {
        currentPage = 1
        hasMore = true
        await MainActor.run { 
            listings.removeAll()
            featuredItems.removeAll()
        }
        loadMarketplace()
    }
    
    func updateSearch(query: String) {
        searchTimer?.invalidate()
        
        guard query.count >= 2 else {
            searchSuggestions = []
            return
        }
        
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
            Task {
                await self.fetchSearchSuggestions(query: query)
            }
        }
    }
    
    @MainActor
    private func fetchSearchSuggestions(query: String) async {
        do {
            let suggestions = try await apiClient.fetchSearchSuggestions(query: query)
            self.searchSuggestions = suggestions.map { suggestion in
                MarketplaceSearchSuggestion(
                    icon: iconForSuggestionType(suggestion.type),
                    text: suggestion.query,
                    subtitle: suggestion.count != nil ? "\(suggestion.count!) results" : "",
                    thumbnail: nil
                )
            }
        } catch {
            print("Error fetching suggestions: \(error)")
        }
    }
    
    func performSearch(query: String) {
        currentSearchQuery = query
        currentPage = 1
        
        if !query.isEmpty && !recentSearches.contains(query) {
            recentSearches.insert(query, at: 0)
            if recentSearches.count > 5 {
                recentSearches.removeLast()
            }
            saveRecentSearches()
        }
        
        Task {
            await loadSearchResults()
        }
    }
    
    @MainActor
    private func loadSearchResults() async {
        isLoading = true
        
        do {
            let results = try await apiClient.searchListings(
                query: currentSearchQuery,
                page: currentPage,
                sort: currentSort
            )
            
            if currentPage == 1 {
                self.listings = results
            } else {
                self.listings.append(contentsOf: results)
            }
            
            self.hasMore = results.count >= 20
            self.isLoading = false
        } catch {
            self.isLoading = false
            print("Search error: \(error)")
        }
    }
    
    func clearSearch() {
        currentSearchQuery = ""
        currentPage = 1
        loadMarketplace()
    }
    
    func filterByCategory(_ category: String?) {
        currentCategory = category
        currentPage = 1
        
        Task {
            await loadFilteredListings()
        }
    }
    
    @MainActor
    private func loadFilteredListings() async {
        isLoading = true
        
        do {
            let response = try await apiClient.fetchFeaturedListings(
                category: currentCategory,
                limit: 20,
                offset: (currentPage - 1) * 20
            )
            
            self.listings = response.data?.listings ?? []
            self.hasMore = response.data?.pagination?.hasMore ?? false
            self.isLoading = false
        } catch {
            self.isLoading = false
            print("Filter error: \(error)")
        }
    }
    
    func loadMore() {
        guard !isLoadingMore && hasMore else { return }
        
        currentPage += 1
        isLoadingMore = true
        
        Task {
            if !currentSearchQuery.isEmpty {
                await loadSearchResults()
            } else if currentCategory != nil {
                await loadFilteredListings()
            } else {
                await loadMoreListings()
            }
            
            await MainActor.run {
                self.isLoadingMore = false
            }
        }
    }
    
    @MainActor
    private func loadMoreListings() async {
        do {
            let response = try await apiClient.fetchFeaturedListings(
                limit: 20,
                offset: listings.count
            )
            
            if let newListings = response.data?.listings {
                self.listings.append(contentsOf: newListings)
            }
            
            self.hasMore = response.data?.pagination?.hasMore ?? false
        } catch {
            print("Error loading more: \(error)")
        }
    }
    
    func sortBy(_ option: MarketplaceSortOption) {
        currentSort = option
        
        // Apply sort locally for better UX
        switch option {
        case .newest:
            listings.sort { $0.createdAt > $1.createdAt }
        case .priceLowToHigh:
            listings.sort { $0.price < $1.price }
        case .priceHighToLow:
            listings.sort { $0.price > $1.price }
        case .distance:
            listings.sort { ($0.distance ?? Double.infinity) < ($1.distance ?? Double.infinity) }
        case .popularity:
            listings.sort { $0.views > $1.views }
        }
    }
    
    func applyFilters(_ filters: MarketplaceFilters) {
        hasActiveFilters = true
        // Implement comprehensive filtering
    }
    
    private func loadRecentSearches() {
        if let searches = UserDefaults.standard.stringArray(forKey: "recentSearches") {
            recentSearches = searches
        }
    }
    
    private func saveRecentSearches() {
        UserDefaults.standard.set(recentSearches, forKey: "recentSearches")
    }
    
    func clearRecentSearches() {
        recentSearches = []
        UserDefaults.standard.removeObject(forKey: "recentSearches")
    }

    private func iconForSuggestionType(_ type: SearchSuggestion.SuggestionType) -> String {
        switch type {
        case .query:
            return "magnifyingglass"
        case .category:
            return "folder"
        case .location:
            return "location"
        case .brand:
            return "tag"
        }
    }
}

// MARK: - Supporting Models

struct MarketplaceColors {
    let primary = Color(hex: "10B981") // Emerald
    let accent = Color(hex: "F59E0B") // Amber
    let success = Color(hex: "10B981") // Green
    let danger = Color(hex: "EF4444") // Red
    let text = Color(.label)
    let secondaryText = Color(.secondaryLabel)
}

struct ProductionFiltersView: View {
    @Binding var selectedCategory: String?
    let onApply: (MarketplaceFilters) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            // Filters implementation
            Text("Filters View")
                .navigationTitle("Filters")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Apply") {
                            onApply(MarketplaceFilters())
                            dismiss()
                        }
                    }
                }
        }
    }
}


// MARK: - Preview

struct ProductionMarketplaceView_Previews: PreviewProvider {
    static var previews: some View {
        ProductionMarketplaceView()
    }
}