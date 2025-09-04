//
//  OptimizedProfessionalMarketplaceView.swift
//  Brrow
//
//  Created by Claude on 7/26/25.
//  Performance-optimized marketplace with memory management and lazy loading
//

import SwiftUI

struct OptimizedProfessionalMarketplaceView: View {
    @StateObject private var viewModel = OptimizedMarketplaceViewModel()
    @StateObject private var performanceManager = PerformanceManager.shared
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
            // Clean background
            Theme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Professional Header
                professionalHeader
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.top, 10)
                    .background(Theme.Colors.background)
                
                PerformantScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Search Bar
                        searchSection
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.top, Theme.Spacing.md)
                        
                        // Category Pills
                        categorySection
                            .padding(.top, Theme.Spacing.lg)
                        
                        // Stats Cards (only when not loading)
                        if !viewModel.isLoading {
                            statsSection
                                .padding(.horizontal, Theme.Spacing.md)
                                .padding(.top, Theme.Spacing.lg)
                        }
                        
                        // Optimized Listings Grid
                        optimizedListingsSection
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.top, Theme.Spacing.lg)
                        
                        // Bottom padding
                        Color.clear.frame(height: 100)
                    }
                }
                .refreshable {
                    await viewModel.refreshData()
                }
            }
            
            // Floating Action Button
            floatingActionButton
            
            // Performance Alert Overlay
            if performanceManager.alertLevel == .critical {
                performanceAlertOverlay
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showFilters) {
            MarketplaceFiltersView(selectedCategory: $selectedCategory) { filters in
                // Convert MarketplaceFilters to dictionary
                let filterDict: [String: Any] = [
                    "category": selectedCategory ?? "",
                    "minPrice": filters.priceRange?.lowerBound ?? 0,
                    "maxPrice": filters.priceRange?.upperBound ?? 1000,
                    "sortBy": filters.sortBy.rawValue
                ]
                viewModel.applyFilters(filterDict)
            }
        }
        .trackPerformance("OptimizedMarketplace")
        .optimizeForMemory()
        .onAppear {
            performanceManager.startMonitoring()
            viewModel.loadMarketplace()
            
            // Preload images for visible items
            preloadVisibleImages()
            
            withAnimation {
                animateContent = true
            }
        }
        .onDisappear {
            performanceManager.stopMonitoring()
        }
        .onChange(of: tabSelectionManager.shouldFocusMarketplaceSearch) { shouldFocus in
            if shouldFocus {
                isSearchFieldFocused = true
                tabSelectionManager.resetSearchFocus()
            }
        }
        .onChange(of: searchText) { newValue in
            viewModel.performSearch(newValue, debounced: true)
        }
    }
    
    // MARK: - Professional Header
    private var professionalHeader: some View {
        HStack {
            Text("marketplace".localizedString)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Theme.Colors.text)
            
            Spacer()
            
            // Performance indicator
            if performanceManager.isMonitoring {
                performanceIndicator
            }
            
            // Filter button
            Button(action: { showFilters = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16, weight: .medium))
                    Text("filters".localizedString)
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
    
    // MARK: - Performance Indicator
    private var performanceIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(colorForPerformance)
                .frame(width: 8, height: 8)
            
            Text(formatMemoryUsage(performanceManager.metrics.memoryUsage))
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var colorForPerformance: Color {
        switch performanceManager.alertLevel {
        case .normal: return .green
        case .warning: return .orange
        case .critical: return .red
        }
    }
    
    // MARK: - Search Section
    private var searchSection: some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.Colors.secondaryText)
                
                TextField("search_items".localizedString, text: $searchText)
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
                OptimizedCategoryPill(
                    title: "all".localizedString,
                    icon: "square.grid.2x2",
                    isSelected: selectedCategory == nil,
                    action: {
                        selectedCategory = nil
                        viewModel.filterByCategory(nil)
                    }
                )
                
                ForEach(OptimizedMarketplaceCategory.allCases, id: \.self) { category in
                    OptimizedCategoryPill(
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
    
    // MARK: - Stats Section
    private var statsSection: some View {
        HStack(spacing: 12) {
            OptimizedStatCard(
                title: "total_items".localizedString,
                value: "\(viewModel.totalItems)",
                icon: "bag.fill",
                color: Theme.Colors.primary
            )
            
            OptimizedStatCard(
                title: "new_today".localizedString,
                value: "\(viewModel.newItemsToday)",
                icon: "plus.circle.fill",
                color: Theme.Colors.success
            )
            
            OptimizedStatCard(
                title: "available_now".localizedString,
                value: "\(viewModel.availableItems)",
                icon: "checkmark.circle.fill",
                color: Theme.Colors.accentBlue
            )
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(.easeOut(duration: 0.4).delay(0.2), value: animateContent)
    }
    
    // MARK: - Optimized Listings Section
    private var optimizedListingsSection: some View {
        Group {
            if viewModel.isLoading && viewModel.listings.isEmpty {
                // Shimmer loading placeholders
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(0..<8, id: \.self) { _ in
                        ShimmerCard()
                    }
                }
            } else if viewModel.listings.isEmpty {
                // Empty state
                VStack(spacing: 20) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text("no_items_found".localizedString)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("try_different_search".localizedString)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 50)
            } else {
                // Memory-efficient grid with lazy loading
                MemoryEfficientGrid(items: viewModel.listings, columns: columns) { listing in
                    LightweightListingCard(listing: listing) {
                        // Handle listing tap
                        viewModel.selectListing(listing)
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
    
    // MARK: - Performance Alert Overlay
    private var performanceAlertOverlay: some View {
        VStack {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Performance Alert")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("High memory usage detected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Optimize") {
                    optimizePerformance()
                }
                .font(.caption)
                .foregroundColor(Theme.Colors.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Theme.Colors.primary.opacity(0.1))
                .cornerRadius(8)
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
            
            Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    // MARK: - Helper Methods
    
    private func preloadVisibleImages() {
        // Images are now handled by OptimizedImageView component
        // No need for separate preloading
    }
    
    private func optimizePerformance() {
        performanceManager.clearCaches()
        viewModel.optimizeMemoryUsage()
        
        HapticManager.notification(type: .success)
    }
    
    private func formatMemoryUsage(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Optimized Components

struct OptimizedCategoryPill: View {
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

struct OptimizedStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Theme.Colors.text)
                
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(12)
    }
}

struct LightweightListingCard: View {
    let listing: Listing
    let onTap: () -> Void
    
    var body: some View {
        LightweightImageCard(
            imageUrl: listing.images.first ?? "",
            title: listing.title,
            subtitle: listing.location.city,
            price: listing.price > 0 ? "$\(String(format: "%.0f", listing.price))/day" : "Free",
            onTap: onTap
        )
    }
}

// MARK: - Optimized Categories
enum OptimizedMarketplaceCategory: String, CaseIterable {
    case electronics = "Electronics"
    case tools = "Tools"
    case furniture = "Furniture"
    case sports = "Sports"
    case outdoor = "Outdoor"
    case kitchen = "Kitchen"
    
    var title: String {
        return rawValue.localizedString
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

// MARK: - Optimized ViewModel
class OptimizedMarketplaceViewModel: ObservableObject {
    @Published var listings: [Listing] = []
    @Published var isLoading = false
    @Published var totalItems = 0
    @Published var newItemsToday = 0
    @Published var availableItems = 0
    
    private var allListings: [Listing] = []
    private var searchWorkItem: DispatchWorkItem?
    
    func loadMarketplace() {
        isLoading = true
        
        Task {
            do {
                let fetchedListings = try await APIClient.shared.fetchListings()
                await MainActor.run {
                    self.allListings = fetchedListings
                    self.listings = fetchedListings
                    self.updateStats()
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
                self.updateStats()
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    func performSearch(_ query: String, debounced: Bool = false) {
        if debounced {
            searchWorkItem?.cancel()
            let workItem = DispatchWorkItem {
                self.executeSearch(query)
            }
            searchWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
        } else {
            executeSearch(query)
        }
    }
    
    private func executeSearch(_ query: String) {
        if query.isEmpty {
            listings = allListings
        } else {
            listings = allListings.filter { listing in
                listing.title.localizedCaseInsensitiveContains(query) ||
                listing.description.localizedCaseInsensitiveContains(query)
            }
        }
        updateStats()
    }
    
    func clearSearch() {
        listings = allListings
        updateStats()
    }
    
    func filterByCategory(_ category: String?) {
        if let category = category {
            listings = allListings.filter { $0.category == category }
        } else {
            listings = allListings
        }
        updateStats()
    }
    
    func applyFilters(_ filters: [String: Any]) {
        // Apply filters logic
        updateStats()
    }
    
    func selectListing(_ listing: Listing) {
        // Handle listing selection
    }
    
    func optimizeMemoryUsage() {
        // Keep only visible listings in memory
        if listings.count > 50 {
            listings = Array(listings.prefix(50))
        }
    }
    
    private func updateStats() {
        totalItems = allListings.count
        availableItems = listings.count
        newItemsToday = allListings.filter { listing in
            Calendar.current.isDateInToday(listing.createdAt)
        }.count
    }
}

#Preview {
    OptimizedProfessionalMarketplaceView()
}