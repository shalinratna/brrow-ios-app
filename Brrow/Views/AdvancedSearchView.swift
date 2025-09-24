//
//  AdvancedSearchView.swift
//  Brrow
//
//  Advanced search interface with filters, location search, and faceted results
//

import SwiftUI
import CoreLocation

struct AdvancedSearchView: View {
    @StateObject private var searchService = AdvancedSearchService.shared
    @State private var searchText = ""
    @State private var showingFilters = false
    @State private var showingMap = false
    @State private var showingSavedSearches = false
    @State private var searchFilters = AdvancedSearchFilters()
    @State private var selectedLocation: LocationResult?
    @State private var sortOption: SortField = .relevance
    @State private var suggestions: [SearchSuggestion] = []
    @State private var showingSuggestions = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Header
                searchHeaderView

                // Search Results
                searchResultsView
            }
            .navigationTitle("Advanced Search")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingSavedSearches = true
                    } label: {
                        Image(systemName: "bookmark.fill")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingMap = true
                    } label: {
                        Image(systemName: "map.fill")
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                SearchFiltersView(filters: $searchFilters) {
                    performSearch()
                }
            }
            .sheet(isPresented: $showingMap) {
                SearchMapView()
            }
            .sheet(isPresented: $showingSavedSearches) {
                SavedSearchesView()
            }
            .onAppear {
                searchService.requestLocationPermission()
            }
        }
    }

    private var searchHeaderView: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)

                    TextField("Search for anything...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onSubmit {
                            performSearch()
                        }

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            showingSuggestions = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(12)

                Button {
                    showingFilters = true
                } label: {
                    ZStack {
                        Image(systemName: "slider.horizontal.3")
                            .font(.title3)

                        if searchFilters.activeFilterCount > 0 {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                                .offset(x: 8, y: -8)
                        }
                    }
                }
                .foregroundColor(.blue)
            }

            // Sort Options
            sortOptionsView
        }
        .padding()
        .background(Color(.systemBackground))
    }

    private var sortOptionsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(SortField.allCases, id: \.self) { option in
                    SortChip(
                        option: option,
                        isSelected: sortOption == option
                    ) {
                        sortOption = option
                        performSearch()
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private var searchResultsView: some View {
        Group {
            if searchService.isLoading && searchService.searchResults.isEmpty {
                loadingView
            } else if searchService.searchResults.isEmpty && !searchText.isEmpty {
                emptyResultsView
            } else if searchService.searchResults.isEmpty {
                searchLandingView
            } else {
                searchResultsList
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Searching...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            VStack(spacing: 8) {
                Text("No results found")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Try adjusting your search or filters")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }

            Button("Clear all filters") {
                clearAllFilters()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var searchLandingView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Recent Searches
                if !searchService.searchHistory.isEmpty {
                    recentSearchesSection
                }

                // Popular Searches
                popularSearchesSection

                // Browse Categories
                browseCategoriesSection
            }
            .padding()
        }
    }

    private var recentSearchesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Searches")
                    .font(.headline)
                Spacer()
                Button("Clear") {
                    searchService.clearSearchHistory()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }

            ForEach(searchService.searchHistory.prefix(5)) { history in
                Button {
                    searchText = history.query
                    performSearch()
                } label: {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(.gray)
                            .frame(width: 20)

                        Text(history.query)
                            .foregroundColor(.primary)

                        Spacer()

                        Text("\(history.resultCount) results")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }

    private var popularSearchesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trending Searches")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(searchService.popularSearches.prefix(6)) { popular in
                    Button {
                        searchText = popular.query
                        performSearch()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(popular.query.capitalized)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)

                                Spacer()

                                if popular.trend == .rising {
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                            }

                            Text("\(popular.count) searches")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            }
        }
    }

    private var browseCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Browse Categories")
                .font(.headline)

            let categories = ["Electronics", "Sports", "Tools", "Home", "Fashion", "Books"]

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    Button {
                        searchFilters.categories = [category]
                        performSearch()
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: categoryIcon(for: category))
                                .font(.title2)
                                .foregroundColor(.blue)

                            Text(category)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        .frame(height: 80)
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
            }
        }
    }

    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Results header
                HStack {
                    Text("\(searchService.totalResultCount) results")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Button("Save Search") {
                        saveCurrentSearch()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding(.horizontal)

                // Results
                ForEach(searchService.searchResults) { result in
                    SearchResultCard(result: result)
                        .padding(.horizontal)
                }

                // Load More
                if searchService.hasMoreResults {
                    Button {
                        Task {
                            try await searchService.loadMoreResults()
                        }
                    } label: {
                        if searchService.isLoading {
                            ProgressView()
                        } else {
                            Text("Load More")
                        }
                    }
                    .padding()
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: - Helper Methods

    private func performSearch() {
        guard !searchText.isEmpty || !searchFilters.isEmpty else { return }

        let request = SearchRequest(
            query: searchText.isEmpty ? nil : searchText,
            location: nil,
            filters: searchFilters,
            sort: SearchSort(field: sortOption),
            pagination: SearchPagination()
        )

        Task {
            try await searchService.search(request)
        }

        showingSuggestions = false
    }

    private func saveCurrentSearch() {
        // Implementation for saving current search
    }

    private func clearAllFilters() {
        searchFilters = AdvancedSearchFilters()
        selectedLocation = nil
        performSearch()
    }

    private func categoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "electronics": return "laptopcomputer"
        case "sports": return "sportscourt"
        case "tools": return "wrench.and.screwdriver"
        case "home": return "house"
        case "fashion": return "tshirt"
        case "books": return "book"
        default: return "tag"
        }
    }
}

// MARK: - Supporting Views

struct SortChip: View {
    let option: SortField
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(option.displayName)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

// MARK: - Supporting Views (Placeholder)

struct SearchFiltersView: View {
    @Binding var filters: AdvancedSearchFilters
    let onApply: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack {
                Text("Advanced filters coming soon...")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        onApply()
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SearchMapView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack {
                Text("Map view coming soon...")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct SavedSearchesView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack {
                Text("Saved searches coming soon...")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Saved Searches")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct SearchResultCard: View {
    let result: SearchResult

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                AsyncImage(url: URL(string: result.listing.images.first?.url ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                }
                .frame(width: 80, height: 80)
                .cornerRadius(8)

                VStack(alignment: .leading, spacing: 4) {
                    Text(result.listing.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(2)

                    Text(result.listing.location.city)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let distance = result.distanceString {
                        Text(distance)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }

                    HStack {
                        Text("$\(Int(result.listing.dailyRate ?? result.listing.price))/day")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.green)

                        Spacer()

                        Text("Score: \(result.score, specifier: "%.1f")")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Preview

struct AdvancedSearchView_Previews: PreviewProvider {
    static var previews: some View {
        AdvancedSearchView()
    }
}