//
//  BrowseView.swift
//  Brrow
//
//  Created by Claude Code on 7/19/25.
//

import SwiftUI

struct BrowseView: View {
    @EnvironmentObject var viewModel: HomeViewModel
    @StateObject private var categoryService = CategoryService.shared
    @State private var selectedFilter = "All"
    @State private var showingFilters = false

    private var filterOptions: [String] {
        categoryService.getCategoryNamesWithAll()
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with search and filters
                headerView
                
                // Filter pills
                filterPills
                
                // Listings grid
                listingsGrid
            }
            .background(Theme.Colors.background)
            .navigationTitle("Browse")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var headerView: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Search bar placeholder
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Theme.Colors.secondaryText)
                Text("Search items...")
                    .foregroundColor(Theme.Colors.secondaryText)
                Spacer()
                Button(action: { showingFilters.toggle() }) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(Theme.Colors.primary)
                }
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.surface)
            .cornerRadius(Theme.CornerRadius.card)
            .shadow(color: Theme.Shadows.subtle, radius: 2, x: 0, y: 1)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.sm)
    }
    
    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.gutter) {
                ForEach(filterOptions, id: \.self) { filter in
                    Text(filter)
                        .pillButton(isSelected: selectedFilter == filter)
                        .onTapGesture {
                            selectedFilter = filter
                            viewModel.selectedCategory = filter
                        }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
        .padding(.vertical, Theme.Spacing.sm)
    }
    
    private var listingsGrid: some View {
        Group {
            if viewModel.listings.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: Theme.Spacing.gutter),
                        GridItem(.flexible(), spacing: Theme.Spacing.gutter)
                    ], spacing: Theme.Spacing.gutter) {
                        ForEach(viewModel.listings, id: \.listingId) { listing in
                            BrowseListingCard(listing: listing)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                }
            }
        }
    }
    
    
    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(Theme.Colors.secondaryText)
            
            Text("No items found")
                .font(Theme.Typography.title)
                .foregroundColor(Theme.Colors.text)
            
            Text("Try adjusting your filters or search terms")
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.Spacing.xl)
    }
}

// Browse listing card component  
struct BrowseListingCard: View {
    let listing: Listing
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Image placeholder
            RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                .fill(Theme.Colors.secondary.opacity(0.2))
                .frame(height: 120)
                .overlay(
                    Image(systemName: "photo")
                        .foregroundColor(Theme.Colors.secondaryText)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(listing.title)
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.text)
                    .lineLimit(2)
                
                Text(listing.listingType == "rental" ? "$\(Int(listing.price))/day" : "$\(Int(listing.price))")
                    .font(Theme.Typography.label)
                    .foregroundColor(Theme.Colors.primary)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.bottom, Theme.Spacing.sm)
        }
        .background(Theme.Colors.surface)
        .cornerRadius(Theme.CornerRadius.card)
        .shadow(color: Theme.Shadows.card, radius: Theme.Shadows.cardRadius, x: 0, y: 2)
    }
}

struct BrowseView_Previews: PreviewProvider {
    static var previews: some View {
        BrowseView()
            .environmentObject(HomeViewModel())
    }
}