//
//  AdvancedSearchView.swift
//  Brrow
//
//  Created by Claude on 7/26/25.
//  Advanced search with filters, sorting, and intelligent suggestions
//

import SwiftUI
import CoreLocation

// MARK: - Search Filter Model
struct SearchFilters: Equatable {
    var categories: Set<String> = []
    var priceRange: ClosedRange<Double> = 0...1000
    var distance: Double = 10.0 // miles
    var condition: ItemCondition?
    var availability: AvailabilityFilter = .all
    var sortBy: SortOption = .relevance
    var includeGarageSales: Bool = true
    var verifiedSellersOnly: Bool = false
    var freeItemsOnly: Bool = false
    var deliveryAvailable: Bool = false
    var instantBooking: Bool = false
    
    enum AvailabilityFilter: String, CaseIterable {
        case all = "All"
        case available = "Available Now"
        case comingSoon = "Coming Soon"
        
        var displayName: String { rawValue }
    }
    
    enum SortOption: String, CaseIterable {
        case relevance = "Relevance"
        case priceLowest = "Price: Low to High"
        case priceHighest = "Price: High to Low"
        case newest = "Newest First"
        case nearest = "Nearest First"
        case highestRated = "Highest Rated"
        case mostReviews = "Most Reviews"
        
        var displayName: String { rawValue }
        var icon: String {
            switch self {
            case .relevance: return "sparkles"
            case .priceLowest: return "arrow.down.circle"
            case .priceHighest: return "arrow.up.circle"
            case .newest: return "clock"
            case .nearest: return "location"
            case .highestRated: return "star.fill"
            case .mostReviews: return "text.bubble"
            }
        }
    }
}

enum ItemCondition: String, CaseIterable {
    case new = "New"
    case likeNew = "Like New"
    case good = "Good"
    case fair = "Fair"
    case any = "Any Condition"
    
    var displayName: String { rawValue }
}

// MARK: - Advanced Search View
struct AdvancedSearchView: View {
    @StateObject private var viewModel = AdvancedSearchViewModel()
    @State private var searchText = ""
    @State private var showFilters = false
    @State private var selectedTab = 0
    @State private var animateContent = false
    @FocusState private var isSearchFocused: Bool
    @Environment(\.presentationMode) var presentationMode
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header
                customHeader
                
                // Search Bar with Voice
                searchBarSection
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.top, Theme.Spacing.sm)
                
                // Quick Filters
                if !viewModel.activeFilters.isEmpty {
                    activeFiltersSection
                        .padding(.top, Theme.Spacing.sm)
                }
                
                // Search Results Tabs
                searchResultsTabs
                    .padding(.top, Theme.Spacing.md)
                
                // Results Content
                TabView(selection: $selectedTab) {
                    // All Results
                    allResultsView
                        .tag(0)
                    
                    // Listings Only
                    listingsView
                        .tag(1)
                    
                    // Garage Sales Only
                    garageSalesView
                        .tag(2)
                    
                    // People
                    peopleView
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            
            // Filter Button
            filterButton
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showFilters) {
            AdvancedFiltersSheet(filters: $viewModel.filters) {
                viewModel.applyFilters()
            }
        }
        .onAppear {
            isSearchFocused = true
            withAnimation {
                animateContent = true
            }
        }
    }
    
    // MARK: - Custom Header
    private var customHeader: some View {
        HStack(spacing: 16) {
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Theme.Colors.text)
                    .frame(width: 44, height: 44)
                    .background(Theme.Colors.secondaryBackground)
                    .clipShape(Circle())
            }
            
            Text("Advanced Search")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Theme.Colors.text)
            
            Spacer()
            
            // Search History
            Button(action: { viewModel.showSearchHistory.toggle() }) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Theme.Colors.text)
                    .frame(width: 44, height: 44)
                    .background(Theme.Colors.secondaryBackground)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, 10)
        .background(Theme.Colors.background)
    }
    
    // MARK: - Search Bar Section
    private var searchBarSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.Colors.secondaryText)
                
                TextField("Search for anything...", text: $searchText)
                    .font(.system(size: 16))
                    .foregroundColor(Theme.Colors.text)
                    .focused($isSearchFocused)
                    .onSubmit {
                        viewModel.performSearch(searchText)
                    }
                    .onChange(of: searchText) { newValue in
                        viewModel.updateSuggestions(for: newValue)
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        viewModel.clearSearch()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
                
                // Voice Search
                Button(action: { viewModel.startVoiceSearch() }) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 16))
                        .foregroundColor(viewModel.isListening ? Theme.Colors.primary : Theme.Colors.secondaryText)
                        .scaleEffect(viewModel.isListening ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: viewModel.isListening)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Theme.Colors.secondaryBackground)
            .cornerRadius(12)
            
            // Search Suggestions
            if !viewModel.suggestions.isEmpty && !searchText.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.suggestions, id: \.self) { suggestion in
                            SuggestionChip(text: suggestion) {
                                searchText = suggestion
                                viewModel.performSearch(suggestion)
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.top, 8)
                }
            }
        }
    }
    
    // MARK: - Active Filters Section
    private var activeFiltersSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.activeFilters, id: \.self) { filter in
                    ActiveFilterChip(filter: filter) {
                        viewModel.removeFilter(filter)
                    }
                }
                
                Button(action: { viewModel.clearAllFilters() }) {
                    Text("Clear All")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.Colors.error)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }
    
    // MARK: - Search Results Tabs
    private var searchResultsTabs: some View {
        HStack(spacing: 0) {
            SearchTabButton(title: "All", count: viewModel.totalResults, isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            
            SearchTabButton(title: "Items", count: viewModel.listings.count, isSelected: selectedTab == 1) {
                selectedTab = 1
            }
            
            SearchTabButton(title: "Garage Sales", count: viewModel.garageSales.count, isSelected: selectedTab == 2) {
                selectedTab = 2
            }
            
            SearchTabButton(title: "People", count: viewModel.users.count, isSelected: selectedTab == 3) {
                selectedTab = 3
            }
        }
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(12)
        .padding(.horizontal, Theme.Spacing.md)
    }
    
    // MARK: - All Results View
    private var allResultsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                // Featured Results
                if !viewModel.featuredResults.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Featured")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Theme.Colors.text)
                            .padding(.horizontal, Theme.Spacing.md)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(viewModel.featuredResults) { item in
                                    FeaturedResultCard(listing: item)
                                }
                            }
                            .padding(.horizontal, Theme.Spacing.md)
                        }
                    }
                }
                
                // Mixed Results Grid
                if !viewModel.allResults.isEmpty {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(viewModel.allResults) { result in
                            SearchResultCard(result: result)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                } else if !viewModel.isSearching {
                    EmptySearchState()
                        .padding(.top, 50)
                }
                
                Color.clear.frame(height: 100)
            }
        }
        .refreshable {
            await viewModel.refreshSearch()
        }
    }
    
    // MARK: - Listings View
    private var listingsView: some View {
        ScrollView {
            if !viewModel.listings.isEmpty {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(viewModel.listings) { listing in
                        OptimizedListingCard(listing: listing)
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.md)
            } else {
                EmptySearchState()
                    .padding(.top, 50)
            }
            
            Color.clear.frame(height: 100)
        }
    }
    
    // MARK: - Garage Sales View
    private var garageSalesView: some View {
        ScrollView {
            if !viewModel.garageSales.isEmpty {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.garageSales) { sale in
                        GarageSaleSearchCard(sale: sale)
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.md)
            } else {
                EmptySearchState()
                    .padding(.top, 50)
            }
            
            Color.clear.frame(height: 100)
        }
    }
    
    // MARK: - People View
    private var peopleView: some View {
        ScrollView {
            if !viewModel.users.isEmpty {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.users) { user in
                        UserSearchCard(user: user)
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.md)
            } else {
                EmptySearchState()
                    .padding(.top, 50)
            }
            
            Color.clear.frame(height: 100)
        }
    }
    
    // MARK: - Filter Button
    private var filterButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                
                Button(action: { showFilters = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 18, weight: .medium))
                        
                        Text("Filters")
                            .font(.system(size: 16, weight: .medium))
                        
                        if viewModel.activeFiltersCount > 0 {
                            Text("\(viewModel.activeFiltersCount)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 20, height: 20)
                                .background(Theme.Colors.error)
                                .clipShape(Circle())
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Theme.Colors.primary)
                    .cornerRadius(25)
                    .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .scaleEffect(animateContent ? 1 : 0.8)
                .opacity(animateContent ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animateContent)
            }
            .padding(.trailing, Theme.Spacing.lg)
            .padding(.bottom, 100)
        }
    }
}

// MARK: - Supporting Views

struct SuggestionChip: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.Colors.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Theme.Colors.secondaryBackground)
                .cornerRadius(20)
        }
    }
}

struct ActiveFilterChip: View {
    let filter: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Text(filter)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.Colors.primary)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Theme.Colors.primary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Theme.Colors.primary.opacity(0.1))
        .cornerRadius(15)
    }
}

struct SearchTabButton: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? Theme.Colors.primary : Theme.Colors.secondaryText)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isSelected ? Theme.Colors.primary : Theme.Colors.tertiaryText)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                VStack {
                    Spacer()
                    if isSelected {
                        Rectangle()
                            .fill(Theme.Colors.primary)
                            .frame(height: 3)
                            .cornerRadius(1.5)
                    }
                }
            )
        }
    }
}

struct FeaturedResultCard: View {
    let listing: Listing
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SimpleOptimizedAsyncImage(url: listing.imageUrls.first ?? "", targetSize: CGSize(width: 200, height: 150))
                .frame(width: 200, height: 150)
                .clipped()
                .cornerRadius(12)
                .overlay(
                    VStack {
                        HStack {
                            Spacer()
                            Text("Featured")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Theme.Colors.primary)
                                .cornerRadius(6)
                                .padding(8)
                        }
                        Spacer()
                    }
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(listing.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.text)
                    .lineLimit(1)
                
                Text(listing.price > 0 ? "$\(String(format: "%.0f", listing.price))/day" : "Free")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Theme.Colors.primary)
            }
        }
        .frame(width: 200)
    }
}

struct SearchResultCard: View {
    let result: SearchResult
    
    var body: some View {
        // Implement based on result type
        Text(result.title)
            .padding()
            .background(Theme.Colors.secondaryBackground)
            .cornerRadius(12)
    }
}

struct OptimizedListingCard: View {
    let listing: Listing
    
    var body: some View {
        SimpleImageCard(
            imageUrl: listing.imageUrls.first ?? "",
            title: listing.title,
            subtitle: listing.location.city,
            price: listing.price > 0 ? "$\(String(format: "%.0f", listing.price))/day" : "Free",
            onTap: {}
        )
    }
}

struct GarageSaleSearchCard: View {
    let sale: GarageSale
    
    var body: some View {
        HStack(spacing: 12) {
            SimpleOptimizedAsyncImage(url: sale.images.first ?? "", targetSize: CGSize(width: 80, height: 80))
                .frame(width: 80, height: 80)
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(sale.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.Colors.text)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Label(sale.location, systemImage: "location.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.secondaryText)
                    
                    Text("•")
                        .foregroundColor(Theme.Colors.tertiaryText)
                    
                    Text(sale.dateString)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                
                HStack {
                    ForEach(sale.categories.prefix(3), id: \.self) { category in
                        Text(category)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Theme.Colors.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.Colors.primary.opacity(0.1))
                            .cornerRadius(6)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(Theme.Colors.tertiaryText)
        }
        .padding()
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(12)
    }
}

struct UserSearchCard: View {
    let user: User
    
    var body: some View {
        HStack(spacing: 12) {
            if let profilePicture = user.profilePicture {
                SimpleOptimizedAsyncImage(url: profilePicture, targetSize: CGSize(width: 60, height: 60))
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Theme.Colors.primary.opacity(0.1))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(user.username.prefix(1).uppercased())
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Theme.Colors.primary)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.username)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.Colors.text)
                
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.accentOrange)
                    
                    Text(String(format: "%.1f", ((user.listerRating ?? 0) + (user.renteeRating ?? 0)) / 2))
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.secondaryText)
                    
                    if user.emailVerified ?? false {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.success)
                    }
                }
            }
            
            Spacer()
            
            Button(action: {}) {
                Text("View Profile")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.Colors.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.Colors.primary.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(12)
    }
}

struct EmptySearchState: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No results found")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text("Try adjusting your filters or search terms")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Search Result Model
struct SearchResult: Identifiable {
    let id = UUID()
    let title: String
    let type: ResultType
    let imageUrl: String?
    let price: Double?
    let location: String?
    let rating: Double?
    
    enum ResultType {
        case listing
        case garageSale
        case user
    }
}

#Preview {
    AdvancedSearchView()
}
