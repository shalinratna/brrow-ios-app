//
//  EnhancedMarketplaceView.swift
//  Brrow
//
//  Enhanced marketplace with predictive search and realistic UI
//

import SwiftUI

struct EnhancedMarketplaceView: View {
    @StateObject private var viewModel = EnhancedMarketplaceViewModel()
    @State private var searchText = ""
    @State private var showingFilters = false
    @State private var selectedCategory: String? = nil
    @State private var showingSuggestions = false
    @FocusState private var isSearchFocused: Bool
    
    // Grid layout
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Main content
                ScrollView {
                    VStack(spacing: 0) {
                        // Search bar with predictive search
                        searchBarSection
                            .padding(.horizontal)
                            .padding(.top, 8)
                        
                        // Trending section
                        if !viewModel.trendingItems.isEmpty && searchText.isEmpty {
                            trendingSection
                                .padding(.top, 20)
                        }
                        
                        // Categories scroll
                        if searchText.isEmpty {
                            categoriesSection
                                .padding(.top, 20)
                        }
                        
                        // Featured banner
                        if searchText.isEmpty && !viewModel.featuredItems.isEmpty {
                            featuredBanner
                                .padding(.top, 20)
                        }
                        
                        // Main listings grid
                        listingsGrid
                            .padding(.top, 20)
                    }
                    .padding(.bottom, 100)
                }
                
                // Search suggestions overlay
                if showingSuggestions && !viewModel.searchSuggestions.isEmpty {
                    searchSuggestionsOverlay
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Image(systemName: "cube.box.fill")
                            .foregroundColor(Theme.Colors.primary)
                        Text("Marketplace")
                            .font(.headline)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingFilters = true }) {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(Theme.Colors.primary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingFilters) {
            MarketplaceFiltersView(
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
    
    // MARK: - Search Bar Section
    private var searchBarSection: some View {
        VStack(spacing: 12) {
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search for anything...", text: $searchText)
                        .focused($isSearchFocused)
                        .onChange(of: searchText) { _, newValue in
                            viewModel.updateSearch(query: newValue)
                            showingSuggestions = !newValue.isEmpty
                        }
                        .onSubmit {
                            performSearch()
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            showingSuggestions = false
                            viewModel.clearSearch()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                if isSearchFocused {
                    Button("Cancel") {
                        isSearchFocused = false
                        searchText = ""
                        showingSuggestions = false
                    }
                    .foregroundColor(Theme.Colors.primary)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3), value: isSearchFocused)
            
            // Quick filters
            if !isSearchFocused && searchText.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.quickFilters, id: \.self) { filter in
                            QuickFilterChip(
                                title: filter,
                                isSelected: viewModel.activeQuickFilter == filter,
                                action: {
                                    viewModel.toggleQuickFilter(filter)
                                }
                            )
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Search Suggestions Overlay
    private var searchSuggestionsOverlay: some View {
        VStack(spacing: 0) {
            // Background blur
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    showingSuggestions = false
                    isSearchFocused = false
                }
            
            // Suggestions container
            VStack(alignment: .leading, spacing: 0) {
                // Recent searches
                if !viewModel.recentSearches.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Recent")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                            Button("Clear") {
                                viewModel.clearRecentSearches()
                            }
                            .font(.caption)
                            .foregroundColor(Theme.Colors.primary)
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                        
                        ForEach(viewModel.recentSearches, id: \.self) { search in
                            SearchSuggestionRow(
                                icon: "clock.arrow.circlepath",
                                text: search,
                                action: {
                                    searchText = search
                                    performSearch()
                                }
                            )
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                }
                
                // Smart suggestions
                if !viewModel.searchSuggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Suggestions")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        
                        ForEach(viewModel.searchSuggestions) { suggestion in
                            SearchSuggestionRow(
                                icon: suggestion.icon,
                                text: suggestion.text,
                                subtitle: suggestion.subtitle,
                                thumbnail: suggestion.thumbnail,
                                action: {
                                    searchText = suggestion.text
                                    performSearch()
                                }
                            )
                        }
                    }
                }
                
                Spacer()
            }
            .background(Color(.systemBackground))
            .cornerRadius(16, corners: [.topLeft, .topRight])
            .shadow(radius: 10)
            .offset(y: 100)
            .transition(.move(edge: .bottom))
        }
        .animation(.spring(), value: showingSuggestions)
    }
    
    // MARK: - Trending Section
    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Trending Now", systemImage: "flame.fill")
                    .font(.headline)
                    .foregroundColor(.orange)
                
                Spacer()
                
                NavigationLink(destination: TrendingItemsView()) {
                    Text("See all")
                        .font(.subheadline)
                        .foregroundColor(Theme.Colors.primary)
                }
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.trendingItems) { item in
                        TrendingItemCard(listing: item)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Categories Section
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Browse by Category")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ListingCategory.allCases, id: \.self) { category in
                        MarketplaceCategoryCard(
                            category: category,
                            isSelected: selectedCategory == category.rawValue,
                            itemCount: viewModel.categoryCounts[category.rawValue] ?? 0,
                            action: {
                                if selectedCategory == category.rawValue {
                                    selectedCategory = nil
                                } else {
                                    selectedCategory = category.rawValue
                                }
                                viewModel.filterByCategory(selectedCategory)
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Featured Banner
    private var featuredBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Featured Items")
                .font(.headline)
                .padding(.horizontal)
            
            TabView {
                ForEach(viewModel.featuredItems) { item in
                    FeaturedItemBanner(listing: item)
                        .padding(.horizontal)
                }
            }
            .frame(height: 200)
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
        }
    }
    
    // MARK: - Listings Grid
    private var listingsGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(searchText.isEmpty ? "All Items" : "Search Results")
                    .font(.headline)
                
                Spacer()
                
                // Sort options
                Menu {
                    Button(action: { viewModel.sortBy(.newest) }) {
                        Label("Newest First", systemImage: "clock")
                    }
                    Button(action: { viewModel.sortBy(.priceLowToHigh) }) {
                        Label("Price: Low to High", systemImage: "arrow.up")
                    }
                    Button(action: { viewModel.sortBy(.priceHighToLow) }) {
                        Label("Price: High to Low", systemImage: "arrow.down")
                    }
                    Button(action: { viewModel.sortBy(.distance) }) {
                        Label("Distance", systemImage: "location")
                    }
                    Button(action: { viewModel.sortBy(.popularity) }) {
                        Label("Most Popular", systemImage: "star")
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(viewModel.currentSort.displayName)
                            .font(.subheadline)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(Theme.Colors.primary)
                }
            }
            .padding(.horizontal)
            
            if viewModel.isLoading {
                LoadingGrid()
            } else if viewModel.listings.isEmpty {
                EmptyStateView(
                    title: searchText.isEmpty ? "No items available" : "No results found",
                    message: searchText.isEmpty 
                        ? "Be the first to list something!" 
                        : "Try adjusting your search or filters",
                    systemImage: "magnifyingglass"
                )
                .frame(minHeight: 300)
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.listings) { listing in
                        NavigationLink(destination: ListingDetailView(listing: listing)) {
                            EnhancedListingCard(listing: listing)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
                
                // Load more button
                if viewModel.hasMore {
                    Button(action: {
                        viewModel.loadMore()
                    }) {
                        HStack {
                            if viewModel.isLoadingMore {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Text("Load More")
                                Image(systemName: "arrow.down.circle")
                            }
                        }
                        .foregroundColor(Theme.Colors.primary)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func performSearch() {
        isSearchFocused = false
        showingSuggestions = false
        viewModel.performSearch(query: searchText)
    }
}

// MARK: - Supporting Views

struct QuickFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon(for: title))
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Theme.Colors.primary : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : Theme.Colors.text)
            .cornerRadius(20)
        }
    }
    
    private func icon(for filter: String) -> String {
        switch filter {
        case "Near Me": return "location.fill"
        case "Available Now": return "checkmark.circle.fill"
        case "Free Items": return "gift.fill"
        case "New Listings": return "sparkles"
        case "Top Rated": return "star.fill"
        default: return "tag.fill"
        }
    }
}

struct SearchSuggestionRow: View {
    let icon: String
    let text: String
    var subtitle: String? = nil
    var thumbnail: String? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon or thumbnail
                if let thumbnail = thumbnail {
                    AsyncImage(url: URL(string: thumbnail)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray5))
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: icon)
                        .foregroundColor(.gray)
                        .frame(width: 40, height: 40)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(text)
                        .foregroundColor(Theme.Colors.text)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.left")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TrendingItemCard: View {
    let listing: Listing
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image
            if let imageUrl = listing.imageUrls.first {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray5))
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 150, height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(listing.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .foregroundColor(Theme.Colors.text)
                
                HStack {
                    Text("$\(Int(listing.price))/day")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.Colors.primary)
                    
                    Spacer()
                    
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                        Text("\(listing.views)")
                            .font(.caption2)
                    }
                    .foregroundColor(.orange)
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(width: 150)
    }
}

struct MarketplaceCategoryCard: View {
    let category: ListingCategory
    let isSelected: Bool
    let itemCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Theme.Colors.primary : Color(.systemGray6))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: category.icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? .white : Theme.Colors.primary)
                }
                
                Text(category.displayName)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Theme.Colors.text)
                    .frame(width: 80)
                
                if itemCount > 0 {
                    Text("\(itemCount)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FeaturedItemBanner: View {
    let listing: Listing
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background image
            if let imageUrl = listing.imageUrls.first {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray5))
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                )
            }
            
            // Content overlay
            VStack(alignment: .leading, spacing: 8) {
                Label("Featured", systemImage: "star.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(12)
                
                Text(listing.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                HStack {
                    Text("$\(Int(listing.price))/day")
                        .font(.subheadline)
                        .fontWeight(.semibold)
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
            .padding()
        }
    }
}

struct EnhancedListingCard: View {
    let listing: Listing
    @State private var isFavorited = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Image with overlay
            ZStack(alignment: .topTrailing) {
                // Promoted badge
                if listing.isPromoted {
                    VStack {
                        HStack {
                            Label("Featured", systemImage: "star.fill")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.orange)
                                        .shadow(radius: 4)
                                )
                                .padding(8)
                            Spacer()
                        }
                        Spacer()
                    }
                    .zIndex(2)
                }
                if let imageUrl = listing.imageUrls.first {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray5))
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )
                    }
                    .frame(height: 180)
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 12, topTrailingRadius: 12))
                }
                
                // Favorite button
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        isFavorited.toggle()
                    }
                }) {
                    Image(systemName: isFavorited ? "heart.fill" : "heart")
                        .foregroundColor(isFavorited ? .red : .white)
                        .padding(8)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }
                .padding(8)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Title
                Text(listing.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .foregroundColor(Theme.Colors.text)
                
                // Price and rating
                HStack {
                    Text("$\(Int(listing.price))")
                        .font(.headline)
                        .foregroundColor(Theme.Colors.primary)
                    Text("/day")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    if let rating = listing.rating, rating > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text(String(format: "%.1f", rating))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // Location and availability
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "location")
                            .font(.caption2)
                        Text(listing.location.city)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .foregroundColor(.gray)
                    
                    Spacer()
                    
                    if listing.isAvailable {
                        Label("Available", systemImage: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
            }
            .padding(12)
            .background(Color(.systemBackground))
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

struct LoadingGrid: View {
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(0..<6) { _ in
                EnhancedShimmerCard()
            }
        }
        .padding(.horizontal)
    }
}

struct EnhancedShimmerCard: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray5))
                .frame(height: 180)
            
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(height: 16)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 100, height: 20)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 80, height: 14)
            }
            .padding(12)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        .overlay(
            LinearGradient(
                colors: [Color.white.opacity(0), Color.white.opacity(0.3), Color.white.opacity(0)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .rotationEffect(.degrees(30))
            .offset(x: isAnimating ? 300 : -300)
            .animation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false), value: isAnimating)
        )
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - View Model

class EnhancedMarketplaceViewModel: ObservableObject {
    @Published var listings: [Listing] = []
    @Published var featuredItems: [Listing] = []
    @Published var trendingItems: [Listing] = []
    @Published var searchSuggestions: [MarketplaceSearchSuggestion] = []
    @Published var recentSearches: [String] = []
    @Published var categoryCounts: [String: Int] = [:]
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var hasMore = true
    @Published var currentSort: MarketplaceSortOption = .newest
    @Published var activeQuickFilter: String? = nil
    
    let quickFilters = ["Near Me", "Available Now", "Free Items", "New Listings", "Top Rated"]
    
    private let apiClient = APIClient.shared
    private var searchTimer: Timer?
    private var currentPage = 1
    private var currentSearchQuery = ""
    
    // Using MarketplaceSortOption from SharedTypes
    
    func loadMarketplace() {
        Task {
            await MainActor.run { isLoading = true }
            
            do {
                // Load all data - featured listings will be prioritized
                let response = try await apiClient.fetchFeaturedListings()
                let listings = response.data?.listings ?? []
                let featured = try await loadFeaturedItems()
                let trending = try await loadTrendingItems()
                let counts = try await loadCategoryCounts()
                
                await MainActor.run {
                    self.listings = listings
                    self.featuredItems = featured
                    self.trendingItems = trending
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
    
    func loadMore() {
        guard !isLoadingMore && hasMore else { return }
        
        currentPage += 1
        isLoadingMore = true
        
        Task {
            if currentSearchQuery.isEmpty {
                await loadMoreListings()
            } else {
                await loadSearchResults()
            }
            await MainActor.run {
                self.isLoadingMore = false
            }
        }
    }
    
    @MainActor
    private func loadMoreListings() async {
        do {
            let moreListings = try await apiClient.fetchListings()
            self.listings.append(contentsOf: moreListings)
            self.hasMore = moreListings.count >= 20
        } catch {
            print("Error loading more: \(error)")
        }
    }
    
    func clearSearch() {
        currentSearchQuery = ""
        currentPage = 1
        loadMarketplace()
    }
    
    func sortBy(_ option: MarketplaceSortOption) {
        currentSort = option
        currentPage = 1
        
        if currentSearchQuery.isEmpty {
            loadMarketplace()
        } else {
            Task {
                await loadSearchResults()
            }
        }
    }
    
    func filterByCategory(_ category: String?) {
        // Implement category filtering
        currentPage = 1
        Task {
            await loadFilteredListings(category: category)
        }
    }
    
    func toggleQuickFilter(_ filter: String) {
        if activeQuickFilter == filter {
            activeQuickFilter = nil
        } else {
            activeQuickFilter = filter
        }
        
        // Apply quick filter logic
        applyQuickFilter()
    }
    
    func applyFilters(_ filters: MarketplaceFilters) {
        // Apply comprehensive filters
        currentPage = 1
        Task {
            await loadFilteredListings(filters: filters)
        }
    }
    
    private func applyQuickFilter() {
        guard let filter = activeQuickFilter else {
            loadMarketplace()
            return
        }
        
        Task {
            await MainActor.run { isLoading = true }
            
            // Apply filter logic based on selected quick filter
            switch filter {
            case "Near Me":
                // Filter by distance (assuming distance is calculated elsewhere)
                listings = listings.sorted { ($0.distance ?? Double.infinity) < ($1.distance ?? Double.infinity) }
            case "Available Now":
                listings = listings.filter { $0.isAvailable }
            case "Free Items":
                listings = listings.filter { $0.price == 0 }
            case "New Listings":
                listings = listings.sorted { $0.createdAt > $1.createdAt }
            case "Top Rated":
                listings = listings.filter { ($0.rating ?? 0) >= 4.0 }
                    .sorted { ($0.rating ?? 0) > ($1.rating ?? 0) }
            default:
                break
            }
            
            await MainActor.run { isLoading = false }
        }
    }
    
    @MainActor
    private func loadFilteredListings(category: String? = nil, filters: MarketplaceFilters? = nil) async {
        isLoading = true
        
        do {
            let filteredListings = try await apiClient.fetchFilteredListings(
                category: category,
                filters: filters,
                page: currentPage
            )
            
            self.listings = filteredListings
            self.hasMore = filteredListings.count >= 20
            self.isLoading = false
        } catch {
            self.isLoading = false
            print("Filter error: \(error)")
        }
    }
    
    private func loadFeaturedItems() async throws -> [Listing] {
        // Simulate featured items - in production, this would be an API call
        return Array(listings.prefix(3))
    }
    
    private func loadTrendingItems() async throws -> [Listing] {
        // Simulate trending items based on views
        return listings.sorted { $0.views > $1.views }.prefix(5).map { $0 }
    }
    
    private func loadCategoryCounts() async throws -> [String: Int] {
        var counts: [String: Int] = [:]
        for category in ListingCategory.allCases {
            let count = listings.filter { $0.category?.name == category.rawValue }.count
            counts[category.rawValue] = count
        }
        return counts
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

struct MarketplaceSearchSuggestion: Identifiable {
    let id = UUID()
    let icon: String
    let text: String
    let subtitle: String?
    let thumbnail: String?
}

// MARK: - Helper Functions

// MARK: - Preview

struct EnhancedMarketplaceView_Previews: PreviewProvider {
    static var previews: some View {
        EnhancedMarketplaceView()
    }
}