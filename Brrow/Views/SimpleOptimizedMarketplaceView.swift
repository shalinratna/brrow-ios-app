//
//  SimpleOptimizedMarketplaceView.swift
//  Brrow
//
//  Created by Claude on 7/26/25.
//  Simple optimized marketplace that compiles successfully
//

import SwiftUI

struct SimpleOptimizedMarketplaceView: View {
    @StateObject private var viewModel = SimpleMarketplaceViewModel()
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    @State private var showFilters = false
    @State private var animateContent = false
    @FocusState private var isSearchFieldFocused: Bool
    @ObservedObject private var tabSelectionManager = TabSelectionManager.shared
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerSection
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.top, 10)
                    .background(Theme.Colors.background)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Search Bar
                        searchSection
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.top, Theme.Spacing.md)
                        
                        // Category Pills
                        categorySection
                            .padding(.top, Theme.Spacing.lg)
                        
                        // Listings Grid
                        listingsSection
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.top, Theme.Spacing.lg)
                        
                        Color.clear.frame(height: 100)
                    }
                }
                .refreshable {
                    await viewModel.refreshData()
                }
            }
            
            // Floating Action Button
            floatingActionButton
        }
        .navigationBarHidden(true)
        .trackSimplePerformance("SimpleOptimizedMarketplace")
        .onAppear {
            viewModel.loadMarketplace()
            withAnimation {
                animateContent = true
            }
        }
        .onChange(of: tabSelectionManager.shouldFocusMarketplaceSearch) { shouldFocus in
            if shouldFocus {
                isSearchFieldFocused = true
                tabSelectionManager.resetSearchFocus()
            }
        }
        .onChange(of: searchText) { newValue in
            viewModel.performSearch(newValue)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Text(LocalizationHelper.localizedString("marketplace"))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Theme.Colors.text)
            
            Spacer()
            
            Button(action: { showFilters = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16, weight: .medium))
                    Text(LocalizationHelper.localizedString("filters"))
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundColor(Theme.Colors.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Theme.Colors.primary.opacity(0.1))
                .cornerRadius(20)
            }
        }
    }
    
    // MARK: - Search Section
    private var searchSection: some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.Colors.secondaryText)
                
                TextField(LocalizationHelper.localizedString("search_items"), text: $searchText)
                    .font(.system(size: 16))
                    .foregroundColor(Theme.Colors.text)
                    .focused($isSearchFieldFocused)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                
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
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Theme.Colors.secondaryBackground)
            .cornerRadius(12)
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(.easeOut(duration: 0.4), value: animateContent)
    }
    
    // MARK: - Category Section
    private var categorySection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                SimpleCategoryPill(
                    title: LocalizationHelper.localizedString("all"),
                    icon: "square.grid.2x2",
                    isSelected: selectedCategory == nil,
                    action: {
                        selectedCategory = nil
                        viewModel.filterByCategory(nil)
                    }
                )
                
                ForEach(SimpleMarketplaceCategory.allCases, id: \.self) { category in
                    SimpleCategoryPill(
                        title: category.title,
                        icon: category.icon,
                        isSelected: selectedCategory == category.rawValue,
                        action: {
                            selectedCategory = category.rawValue
                            viewModel.filterByCategory(category.rawValue)
                        }
                    )
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(.easeOut(duration: 0.4).delay(0.1), value: animateContent)
    }
    
    // MARK: - Listings Section
    private var listingsSection: some View {
        Group {
            if viewModel.isLoading && viewModel.listings.isEmpty {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(0..<8, id: \.self) { _ in
                        SimpleShimmerCard(width: 160, height: 200)
                    }
                }
            } else if viewModel.listings.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text(LocalizationHelper.localizedString("no_items_found"))
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(LocalizationHelper.localizedString("try_different_search"))
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 50)
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(viewModel.listings) { listing in
                        SimpleListingCard(listing: listing) {
                            viewModel.selectListing(listing)
                        }
                    }
                }
            }
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(.easeOut(duration: 0.4).delay(0.3), value: animateContent)
    }
    
    // MARK: - Floating Action Button
    private var floatingActionButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                
                NavigationLink(destination: ModernCreateListingView()) {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(
                            Circle()
                                .fill(Theme.Colors.primary)
                                .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                }
                .scaleEffect(animateContent ? 1 : 0.8)
                .opacity(animateContent ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: animateContent)
            }
            .padding(.trailing, Theme.Spacing.lg)
            .padding(.bottom, 100)
        }
    }
}

// MARK: - Simple Components

struct SimpleCategoryPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : Theme.Colors.text)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Theme.Colors.primary : Theme.Colors.secondaryBackground)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SimpleListingCard: View {
    let listing: Listing
    let onTap: () -> Void
    
    var body: some View {
        SimpleImageCard(
            imageUrl: listing.imageUrls.first ?? "",
            title: listing.title,
            subtitle: listing.location.city,
            price: listing.price > 0 ? "$\(String(format: "%.0f", listing.price))/day" : "Free",
            onTap: onTap
        )
    }
}

// MARK: - Simple Categories
enum SimpleMarketplaceCategory: String, CaseIterable {
    case electronics = "Electronics"
    case tools = "Tools"
    case furniture = "Furniture"
    case sports = "Sports"
    case outdoor = "Outdoor"
    case kitchen = "Kitchen"
    
    var title: String {
        return LocalizationHelper.localizedString(rawValue)
    }
    
    var icon: String {
        switch self {
        case .electronics: return "tv"
        case .tools: return "hammer"
        case .furniture: return "sofa"
        case .sports: return "figure.run"
        case .outdoor: return "leaf"
        case .kitchen: return "refrigerator"
        }
    }
}

// MARK: - Simple ViewModel
class SimpleMarketplaceViewModel: ObservableObject {
    @Published var listings: [Listing] = []
    @Published var isLoading = false
    
    private var allListings: [Listing] = []
    
    func loadMarketplace() {
        isLoading = true
        
        Task {
            do {
                let fetchedListings = try await APIClient.shared.fetchListings()
                await MainActor.run {
                    self.allListings = fetchedListings
                    self.listings = fetchedListings
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    func refreshData() async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let fetchedListings = try await APIClient.shared.fetchListings()
            await MainActor.run {
                self.allListings = fetchedListings
                self.listings = fetchedListings
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    func performSearch(_ query: String) {
        if query.isEmpty {
            listings = allListings
        } else {
            listings = allListings.filter { listing in
                listing.title.localizedCaseInsensitiveContains(query) ||
                listing.description.localizedCaseInsensitiveContains(query)
            }
        }
    }
    
    func clearSearch() {
        listings = allListings
    }
    
    func filterByCategory(_ category: String?) {
        if let category = category {
            listings = allListings.filter { $0.category?.name == category }
        } else {
            listings = allListings
        }
    }
    
    func selectListing(_ listing: Listing) {
        // Handle listing selection
    }
}

#Preview {
    SimpleOptimizedMarketplaceView()
}