//
//  SearchView.swift
//  Brrow
//
//  Advanced Search & Browse Experience
//

import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @State private var searchText = ""
    @State private var showingFilters = false
    @State private var selectedCategory = "All"
    
    private let categories = ["All", "Electronics", "Tools", "Sports", "Kitchen", "Books", "Garden", "Furniture"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search header
                searchHeader
                
                // Category pills
                categoryPills
                
                // Results
                searchResults
            }
            .background(Theme.Colors.background)
            .navigationBarHidden(true)
            .sheet(isPresented: $showingFilters) {
                AdvancedFiltersView()
            }
        }
        .searchable(text: $searchText, prompt: "Search for items to borrow...")
        .onSubmit(of: .search) {
            viewModel.search(query: searchText, category: selectedCategory)
        }
        .onChange(of: searchText) { _, newValue in
            if newValue.isEmpty {
                viewModel.clearSearch()
            }
        }
    }
    
    // MARK: - Search Header
    private var searchHeader: some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack {
                Text("Search")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Theme.Colors.text)
                
                Spacer()
                
                Button(action: { showingFilters = true }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 18))
                        .foregroundColor(Theme.Colors.primary)
                }
            }
            
            // Quick suggestions
            if searchText.isEmpty && viewModel.suggestions.isEmpty == false {
                quickSuggestions
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.sm)
    }
    
    // MARK: - Category Pills
    private var categoryPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(categories, id: \.self) { category in
                    Text(category)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(selectedCategory == category ? .white : Theme.Colors.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedCategory == category ? Theme.Colors.primary : Theme.Colors.primary.opacity(0.1))
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedCategory = category
                                viewModel.search(query: searchText, category: category)
                            }
                        }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
        .padding(.vertical, Theme.Spacing.sm)
    }
    
    // MARK: - Quick Suggestions
    private var quickSuggestions: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Popular Searches")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.Colors.text)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(viewModel.suggestions, id: \.self) { suggestion in
                    Button(action: {
                        searchText = suggestion
                        viewModel.search(query: suggestion, category: selectedCategory)
                    }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.Colors.secondaryText)
                            
                            Text(suggestion)
                                .font(.system(size: 14))
                                .foregroundColor(Theme.Colors.text)
                                .lineLimit(1)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Theme.Colors.surface)
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    // MARK: - Search Results
    private var searchResults: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.md) {
                if viewModel.isLoading {
                    ForEach(0..<5, id: \.self) { _ in
                        SearchResultSkeleton()
                    }
                } else if viewModel.searchResults.isEmpty && !searchText.isEmpty {
                    emptySearchState
                } else {
                    ForEach(viewModel.searchResults, id: \.id) { listing in
                        BasicSearchResultCard(listing: listing)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }
    
    // MARK: - Empty Search State
    private var emptySearchState: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(Theme.Colors.secondaryText)
            
            Text("No results found")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Theme.Colors.text)
            
            Text("Try adjusting your search or browse by category")
                .font(.system(size: 16))
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
            
            Button("Browse All Items") {
                selectedCategory = "All"
                searchText = ""
                viewModel.loadAllItems()
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Theme.Colors.primary)
            .cornerRadius(24)
        }
        .padding(.vertical, Theme.Spacing.xl)
    }
}

// MARK: - Search Result Card
struct BasicSearchResultCard: View {
    let listing: Listing
    
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            AsyncImage(url: URL(string: listing.firstImageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Theme.Colors.secondary.opacity(0.3))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(Theme.Colors.secondaryText)
                    )
            }
            .frame(width: 80, height: 80)
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(listing.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
                    .lineLimit(1)
                
                Text(listing.description)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.secondaryText)
                    .lineLimit(2)
                
                HStack {
                    Text(listing.isFree ? "FREE" : "$\(Int(listing.price))/day")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(listing.isFree ? Theme.Colors.success : Theme.Colors.primary)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "location")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.secondaryText)
                        
                        Text("0.5 mi")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
            }
            
            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface)
        .cornerRadius(Theme.CornerRadius.card)
        .shadow(color: Theme.Shadows.card.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Search Result Skeleton
struct SearchResultSkeleton: View {
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Rectangle()
                .fill(Theme.Colors.surface)
                .frame(width: 80, height: 80)
                .cornerRadius(12)
                .shimmerLoading()
            
            VStack(alignment: .leading, spacing: 8) {
                Rectangle()
                    .fill(Theme.Colors.surface)
                    .frame(height: 16)
                    .shimmerLoading()
                
                Rectangle()
                    .fill(Theme.Colors.surface)
                    .frame(height: 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .shimmerLoading()
                
                Rectangle()
                    .fill(Theme.Colors.surface)
                    .frame(width: 60, height: 12)
                    .shimmerLoading()
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface)
        .cornerRadius(Theme.CornerRadius.card)
    }
}

#Preview {
    SearchView()
}