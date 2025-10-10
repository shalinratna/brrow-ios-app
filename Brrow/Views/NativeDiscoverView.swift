//
//  NativeDiscoverView.swift
//  Brrow
//
//  Professional Native iOS Discovery Feed
//

import SwiftUI
import CoreLocation

struct NativeDiscoverView: View {
    @StateObject private var viewModel = DiscoverViewModel()
    @State private var searchText = ""
    @State private var selectedCategory: ListingCategory = .all
    @State private var showingFilters = false
    @State private var showingPostCreation = false
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Search bar
                    searchBar
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Category filter
                    categoryFilter
                        .padding(.vertical, 12)
                    
                    // Listings grid
                    if viewModel.isLoading && viewModel.listings.isEmpty {
                        loadingView
                    } else if viewModel.listings.isEmpty {
                        emptyStateView
                    } else {
                        listingsGrid
                    }
                }
            }
            .refreshable {
                await viewModel.refreshListings()
            }
        }
        .navigationTitle("Discover")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingFilters = true }) {
                    Image(systemName: "slider.horizontal.3")
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingPostCreation = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingFilters) {
            FilterView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingPostCreation) {
            NavigationView {
                ModernPostCreationView()
            }
        }
        .onAppear {
            Task {
                await viewModel.loadListings()
            }
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search items near you...", text: $searchText)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        Task {
                            await viewModel.searchListings(query: searchText)
                        }
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        Task {
                            await viewModel.loadListings()
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Category Filter
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ListingCategory.allCases, id: \.self) { category in
                    NativeCategoryChip(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = category
                            Task {
                                await viewModel.filterByCategory(category)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Listings Grid
    private var listingsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            ForEach(viewModel.listings) { listing in
                Button(action: {
                    ListingNavigationManager.shared.showListing(listing)
                }) {
                    NativeListingCard(listing: listing)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 100)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Finding items near you...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 400)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bag.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No items found")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Be the first to list something in your area!")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: { showingPostCreation = true }) {
                Label("Create Listing", systemImage: "plus.circle.fill")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Theme.Colors.primary)
                    .foregroundColor(.white)
                    .cornerRadius(25)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 400)
        .padding()
    }
}

// MARK: - Category Chip
struct NativeCategoryChip: View {
    let category: ListingCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: category.icon)
                    .font(.system(size: 14))
                Text(category.displayName)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Theme.Colors.primary : Color(UIColor.secondarySystemBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.clear : Color(UIColor.separator), lineWidth: 1)
            )
        }
    }
}

// MARK: - Native Listing Card
struct NativeListingCard: View {
    let listing: Listing
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image
            if let firstImage = listing.imageUrls.first {
                BrrowAsyncImage(url: firstImage) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(UIColor.secondarySystemBackground))
                        .overlay(
                            ProgressView()
                        )
                }
                .frame(height: 180)
                .clipped()
                .cornerRadius(12)
            } else {
                Rectangle()
                    .fill(Color(UIColor.secondarySystemBackground))
                    .frame(height: 180)
                    .cornerRadius(12)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                    )
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(listing.title)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                HStack {
                    Text(listing.priceDisplay)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.Colors.primary)
                    
                    if "listing" == "borrow" {
                        Text("/day")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "location")
                        .font(.system(size: 10))
                    Text(listing.distanceText ?? "Nearby")
                        .font(.system(size: 12))
                }
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Filter View
struct FilterView: View {
    @ObservedObject var viewModel: DiscoverViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Price Range") {
                    VStack {
                        HStack {
                            Text("$\(Int(viewModel.minPrice))")
                            Spacer()
                            Text("$\(Int(viewModel.maxPrice))")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        
                        NativeRangeSlider(
                            minValue: $viewModel.minPrice,
                            maxValue: $viewModel.maxPrice,
                            bounds: 0...1000
                        )
                    }
                }
                
                Section("Distance") {
                    Picker("Maximum Distance", selection: $viewModel.maxDistance) {
                        Text("1 mile").tag(1.0)
                        Text("5 miles").tag(5.0)
                        Text("10 miles").tag(10.0)
                        Text("25 miles").tag(25.0)
                        Text("50 miles").tag(50.0)
                    }
                }
                
                Section("Listing Type") {
                    Picker("Type", selection: $viewModel.listingType) {
                        Text("All").tag(ListingType?.none)
                        Text("Borrow").tag(ListingType.borrow as ListingType?)
                        Text("Buy").tag(ListingType.buy as ListingType?)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section("Sort By") {
                    Picker("Sort", selection: $viewModel.sortBy) {
                        Text("Nearest").tag(SortOption.nearest)
                        Text("Newest").tag(SortOption.newest)
                        Text("Price: Low to High").tag(SortOption.priceLowToHigh)
                        Text("Price: High to Low").tag(SortOption.priceHighToLow)
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        viewModel.resetFilters()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        Task {
                            await viewModel.applyFilters()
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Native Range Slider
struct NativeRangeSlider: View {
    @Binding var minValue: Double
    @Binding var maxValue: Double
    let bounds: ClosedRange<Double>
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                Rectangle()
                    .fill(Color(UIColor.systemGray5))
                    .frame(height: 4)
                    .cornerRadius(2)
                
                // Selected range
                Rectangle()
                    .fill(Theme.Colors.primary)
                    .frame(
                        width: CGFloat((maxValue - minValue) / (bounds.upperBound - bounds.lowerBound)) * geometry.size.width,
                        height: 4
                    )
                    .offset(x: CGFloat((minValue - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)) * geometry.size.width)
                    .cornerRadius(2)
                
                // Min handle
                Circle()
                    .fill(Color.white)
                    .frame(width: 20, height: 20)
                    .shadow(radius: 2)
                    .offset(x: CGFloat((minValue - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)) * geometry.size.width - 10)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newValue = Double(value.location.x / geometry.size.width) * (bounds.upperBound - bounds.lowerBound) + bounds.lowerBound
                                minValue = min(max(bounds.lowerBound, newValue), maxValue - 10)
                            }
                    )
                
                // Max handle
                Circle()
                    .fill(Color.white)
                    .frame(width: 20, height: 20)
                    .shadow(radius: 2)
                    .offset(x: CGFloat((maxValue - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)) * geometry.size.width - 10)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newValue = Double(value.location.x / geometry.size.width) * (bounds.upperBound - bounds.lowerBound) + bounds.lowerBound
                                maxValue = max(min(bounds.upperBound, newValue), minValue + 10)
                            }
                    )
            }
        }
        .frame(height: 20)
    }
}

#Preview {
    NavigationView {
        NativeDiscoverView()
    }
}