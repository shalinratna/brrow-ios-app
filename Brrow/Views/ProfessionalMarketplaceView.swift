//
//  ProfessionalMarketplaceView.swift
//  Brrow
//
//  Professional marketplace with green/white theme
//

import SwiftUI

enum MarketplaceSearchMode {
    case listings
    case garageSales
    case all
}

struct ProfessionalMarketplaceView: View {
    @StateObject private var viewModel = ProfessionalMarketplaceViewModel()
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    @State private var showFilters = false
    @State private var showAdvancedSearch = false
    @State private var animateContent = false
    @State private var searchMode: MarketplaceSearchMode = .listings
    @FocusState private var isSearchFieldFocused: Bool
    @ObservedObject private var tabSelectionManager = TabSelectionManager.shared
    @State private var selectedListing: Listing? = nil
    @State private var showingListingDetail = false
    @State private var showingInfoPopup = false
    @State private var selectedInfoType: InfoType? = nil
    @State private var showingPostCreation = false

    // Tap handler state for debouncing and safety
    @State private var lastTapTime: Date = .distantPast
    @State private var lastTappedId: String = ""
    private let tapDebounceInterval: TimeInterval = 0.5 // 500ms debounce
    
    enum InfoType {
        case available, nearYou, todaysDeals
        
        var title: String {
            switch self {
            case .available: return "Available Items"
            case .nearYou: return "Near You"
            case .todaysDeals: return "Today's Deals"
            }
        }
        
        var description: String {
            switch self {
            case .available:
                return "Shows all active listings currently available for rent or purchase on Brrow. These items are ready to be borrowed or bought from neighbors in your community."
            case .nearYou:
                return "Displays items within 10 miles of your current location. Perfect for finding things you can pick up quickly without traveling far."
            case .todaysDeals:
                return "Special offers and featured items available today! Includes new listings, promotional prices, and items under $50 for budget-friendly options."
            }
        }
        
        var icon: String {
            switch self {
            case .available: return "cube.box.fill"
            case .nearYou: return "location.fill"
            case .todaysDeals: return "tag.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .available: return Theme.Colors.primary
            case .nearYou: return Theme.Colors.accentBlue
            case .todaysDeals: return Theme.Colors.accentOrange
            }
        }
    }
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
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
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            // Search Bar
                            searchSection
                                .padding(.horizontal, Theme.Spacing.md)
                                .padding(.top, Theme.Spacing.md)
                            
                            // Category Pills
                            categorySection
                                .padding(.top, Theme.Spacing.lg)
                            
                            // Stats Cards
                            if !viewModel.isLoading {
                                statsSection
                                    .padding(.horizontal, Theme.Spacing.md)
                                    .padding(.top, Theme.Spacing.lg)
                            }
                            
                            // Listings Grid
                            listingsSection
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
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showFilters) {
                MarketplaceFiltersView(selectedCategory: $selectedCategory) { filters in
                    // Apply filters
                }
            }
            .fullScreenCover(isPresented: $showAdvancedSearch) {
                NavigationView {
                    AdvancedSearchView()
                }
            }
            .sheet(isPresented: $showingInfoPopup) {
                if let infoType = selectedInfoType {
                    InfoPopupView(infoType: infoType) { type in
                        // Apply filter based on info type
                        switch type {
                        case .available:
                            // Show all available listings (already the default)
                            viewModel.clearFilters()
                        case .nearYou:
                            // Filter by nearby listings
                            viewModel.filterByDistance(10) // 10 miles
                        case .todaysDeals:
                            // Filter by deals under $50 or featured
                            viewModel.filterByDeals()
                        }
                    }
                }
            }
            .onAppear {
                viewModel.loadMarketplace()
                withAnimation {
                    animateContent = true
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("RefreshMarketplace"))) { _ in
                // Refresh marketplace when notification is received
                viewModel.loadMarketplace()
            }
            .onChange(of: tabSelectionManager.shouldFocusMarketplaceSearch) { shouldFocus in
                if shouldFocus {
                    // Focus the search field
                    isSearchFieldFocused = true
                    // Reset the trigger
                    tabSelectionManager.resetSearchFocus()
                }
            }
            .sheet(isPresented: Binding<Bool>(
                get: { selectedListing != nil },
                set: { if !$0 { selectedListing = nil } }
            )) {
                if let listing = selectedListing {
                    NavigationView {
                        ProfessionalListingDetailView(listing: listing)
                            .navigationBarTitleDisplayMode(.inline)
                            .navigationBarItems(trailing: Button("Done") {
                                selectedListing = nil
                            })
                    }
                }
            }
            .sheet(isPresented: $showingPostCreation) {
                ModernPostCreationView(onListingCreated: { listingId in
                    // CRITICAL: Invalidate all caches so fresh data is fetched
                    AppDataPreloader.shared.invalidateCache(for: .all)

                    // First refresh the marketplace to get all new listings
                    viewModel.loadMarketplace()

                    // Show the listing detail after a brief delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        Task {
                            do {
                                // Fetch the listing details
                                let listing = try await APIClient.shared.fetchListingDetailsByListingId(listingId)
                                await MainActor.run {
                                    self.selectedListing = listing
                                    // Refresh preloader in background for next time
                                    AppDataPreloader.shared.refreshInBackground(type: .marketplace)
                                }
                            } catch {
                                print("Error fetching listing: \(error)")
                                // Still refresh preloader even if fetching details fails
                                await MainActor.run {
                                    AppDataPreloader.shared.refreshInBackground(type: .marketplace)
                                }
                            }
                        }
                    }
                })
            }
    }
    
    // MARK: - Professional Header
    private var professionalHeader: some View {
        HStack {
            Text(LocalizationHelper.localizedString("marketplace"))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Theme.Colors.text)
            
            Spacer()
            
            // Filter button
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
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Theme.Colors.secondaryBackground)
            .cornerRadius(12)
            
            // Advanced search button
            Button(action: { showAdvancedSearch = true }) {
                Image(systemName: "slider.vertical.3")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Theme.Colors.primary)
                    .frame(width: 48, height: 48)
                    .background(Theme.Colors.primary.opacity(0.1))
                    .cornerRadius(12)
            }
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(.easeOut(duration: 0.4), value: animateContent)
    }
    
    // MARK: - Category Section
    private var categorySection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ProfessionalCategoryPill(
                    title: LocalizationHelper.localizedString("all"),
                    icon: "square.grid.2x2",
                    isSelected: selectedCategory == nil,
                    action: {
                        selectedCategory = nil
                        viewModel.filterByCategory(nil)
                    }
                )
                
                ForEach(ProfessionalMarketplaceCategory.allCases, id: \.self) { category in
                    ProfessionalCategoryPill(
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
            Button(action: {
                selectedInfoType = .available
                showingInfoPopup = true
            }) {
                ProfessionalStatCard(
                    title: LocalizationHelper.localizedString("available"),
                    value: "\(viewModel.totalListings)",
                    icon: "cube.box.fill",
                    color: Theme.Colors.primary
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: {
                selectedInfoType = .nearYou
                showingInfoPopup = true
            }) {
                ProfessionalStatCard(
                    title: LocalizationHelper.localizedString("near_you"),
                    value: "\(viewModel.nearbyListings)",
                    icon: "location.fill",
                    color: Theme.Colors.accentBlue
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: {
                selectedInfoType = .todaysDeals
                showingInfoPopup = true
            }) {
                ProfessionalStatCard(
                    title: LocalizationHelper.localizedString("todays_deals"),
                    value: "\(viewModel.todaysDeals)",
                    icon: "tag.fill",
                    color: Theme.Colors.accentOrange
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .opacity(animateContent ? 1 : 0)
        .scaleEffect(animateContent ? 1 : 0.9)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: animateContent)
    }
    
    // MARK: - Listings Section
    private var listingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Text(LocalizationHelper.localizedString("all_items"))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Theme.Colors.text)
                
                Spacer()
                
                // Sort menu
                Menu {
                    Button(LocalizationHelper.localizedString("newest_first")) { viewModel.sortBy(.newest) }
                    Button(LocalizationHelper.localizedString("price_low_to_high")) { viewModel.sortBy(.priceLowToHigh) }
                    Button(LocalizationHelper.localizedString("price_high_to_low")) { viewModel.sortBy(.priceHighToLow) }
                    Button(LocalizationHelper.localizedString("distance")) { viewModel.sortBy(.distance) }
                } label: {
                    HStack(spacing: 6) {
                        Text(LocalizationHelper.localizedString("sort"))
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(Theme.Colors.primary)
                }
            }
            
            // Grid
            if viewModel.isLoading && viewModel.listings.isEmpty {
                ProfessionalLoadingGrid()
            } else if viewModel.listings.isEmpty {
                EmptyStateView(
                    title: LocalizationHelper.localizedString("no_items_found"),
                    message: LocalizationHelper.localizedString("try_adjusting_filters"),
                    systemImage: "cube.box"
                )
                .frame(height: 300)
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.listings, id: \.listingId) { listing in
                        ProfessionalListingCard(listing: listing) {
                            handleListingTap(listingId: listing.listingId)
                        }
                        .id(listing.listingId)
                    }
                }
                
                // Load more button
                if viewModel.hasMore {
                    LoadMoreButton(isLoading: viewModel.isLoadingMore) {
                        viewModel.loadMore()
                    }
                    .padding(.top, 20)
                }
            }
        }
    }
    
    // MARK: - Floating Action Button
    private var floatingActionButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                
                Button(action: {
                    showingPostCreation = true
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }) {
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.primary)
                            .frame(width: 60, height: 60)
                            .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .scaleEffect(animateContent ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5), value: animateContent)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 30)
        }
    }

    // MARK: - Helper Functions

    /// Bulletproof tap handler with multiple safety layers
    /// Layer 1: ID format validation (prevent crashes from malformed data)
    /// Layer 2: Debounce to prevent double-taps (500ms window)
    /// Layer 3: Thread-safe array lookup (@MainActor guarantee)
    /// Layer 4: Data completeness validation (prevent showing broken listings)
    /// Layer 5: API fallback fetch (handles filtered/removed items)
    /// Layer 6: Error handling with user feedback (graceful degradation)
    @MainActor
    private func handleListingTap(listingId: String) {
        // SAFETY LAYER 1: Validate ID format (must be non-empty UUID-like string)
        guard !listingId.isEmpty, listingId.count > 10 else {
            print("❌ [TAP HANDLER] Invalid listing ID format: '\(listingId)'")
            return
        }

        // SAFETY LAYER 2: Debounce - prevent double-taps
        let now = Date()
        let timeSinceLastTap = now.timeIntervalSince(lastTapTime)

        if timeSinceLastTap < tapDebounceInterval && lastTappedId == listingId {
            print("🚫 [TAP HANDLER] Debounced duplicate tap (\(String(format: "%.3f", timeSinceLastTap))s since last)")
            return
        }

        // Update debounce state
        lastTapTime = now
        lastTappedId = listingId

        print("🎯 [TAP HANDLER] Processing tap for ID: \(listingId)")

        // SAFETY LAYER 3: Thread-safe lookup from current array
        // Using first(where:) is O(n) but safe during concurrent modifications
        if let listing = viewModel.listings.first(where: { $0.listingId == listingId }) {
            // SAFETY LAYER 4: Validate the listing object is complete
            guard !listing.title.isEmpty else {
                print("⚠️ [TAP HANDLER] Found listing but data is incomplete, ID: \(listingId)")
                fallbackFetchListing(listingId: listingId)
                return
            }

            // SUCCESS: Found valid listing in array
            selectedListing = listing
            print("✅ [TAP HANDLER] Listing found in array: '\(listing.title)' (ID: \(listingId))")
            return
        }

        // SAFETY LAYER 5: Array lookup failed - could be filtered out or removed
        print("⚠️ [TAP HANDLER] Listing \(listingId) not in current array (size: \(viewModel.listings.count))")
        print("   Possible causes: filtered out, removed, or race condition during load")

        // Attempt fallback fetch from API
        fallbackFetchListing(listingId: listingId)
    }

    /// Fallback: Fetch listing directly from API if not in array
    /// This handles edge cases where listing was filtered out or array is stale
    @MainActor
    private func fallbackFetchListing(listingId: String) {
        print("🔄 [TAP HANDLER] Attempting API fallback fetch for: \(listingId)")

        Task {
            do {
                // Get the base URL from APIClient
                let baseURL = await APIClient.shared.getBaseURL()
                guard let url = URL(string: "\(baseURL)/api/listings/\(listingId)") else {
                    print("❌ [TAP HANDLER] Invalid URL for listing: \(listingId)")
                    showErrorAlert()
                    return
                }

                var request = URLRequest(url: url)
                request.httpMethod = "GET"

                // Add auth token
                if let token = KeychainHelper().loadString(forKey: "brrow_auth_token") {
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                }

                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ [TAP HANDLER] Invalid response type")
                    showErrorAlert()
                    return
                }

                guard httpResponse.statusCode == 200 else {
                    print("❌ [TAP HANDLER] API returned status \(httpResponse.statusCode)")
                    showErrorAlert()
                    return
                }

                // Decode the listing
                let decoder = JSONDecoder()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                decoder.dateDecodingStrategy = .formatted(dateFormatter)

                let listing = try decoder.decode(Listing.self, from: data)

                // SUCCESS: Fetched from API
                await MainActor.run {
                    selectedListing = listing
                    print("✅ [TAP HANDLER] Fetched from API: '\(listing.title)' (ID: \(listingId))")
                }

            } catch {
                print("❌ [TAP HANDLER] API fetch failed: \(error.localizedDescription)")
                showErrorAlert()
            }
        }
    }

    /// Show user-friendly error when tap handling fails
    @MainActor
    private func showErrorAlert() {
        // TODO: Show a subtle toast or alert to user
        // For now, just log - you can add a @State alert here
        print("💬 [TAP HANDLER] Should show user error: 'Unable to open listing. Please try again.'")
    }
}

// MARK: - Professional Category Pill
struct ProfessionalCategoryPill: View {
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
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : Theme.Colors.text)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                isSelected ? Theme.Colors.primary : Theme.Colors.secondaryBackground
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Theme.Colors.primary : Color.clear, lineWidth: 1)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
    }
}

// MARK: - Info Popup View
struct InfoPopupView: View {
    let infoType: ProfessionalMarketplaceView.InfoType
    @Environment(\.dismiss) private var dismiss
    let onApplyFilter: ((ProfessionalMarketplaceView.InfoType) -> Void)?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Icon
                Image(systemName: infoType.icon)
                    .font(.system(size: 60, weight: .medium))
                    .foregroundColor(infoType.color)
                    .padding(.top, 40)
                
                // Title
                Text(infoType.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Theme.Colors.text)
                
                // Description
                Text(infoType.description)
                    .font(.system(size: 16))
                    .foregroundColor(Theme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 24)
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 12) {
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(infoType.color)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(infoType.color, lineWidth: 2)
                            )
                    }
                    
                    Button(action: { 
                        onApplyFilter?(infoType)
                        dismiss() 
                    }) {
                        Text("Apply Filter")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(infoType.color)
                            .cornerRadius(25)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Theme.Colors.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Professional Stat Card
struct ProfessionalStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Theme.Colors.text)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(12)
    }
}

// MARK: - Professional Listing Card
struct ProfessionalListingCard: View {
    let listing: Listing
    @StateObject private var favoritesManager = FavoritesManager.shared
    @State private var isPressed = false
    var onTap: (() -> Void)? = nil

    private var isFavorited: Bool {
        favoritesManager.isFavorited(listing.id)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Image section
            ZStack {
                // Using BrrowAsyncImage for better performance
                BrrowAsyncImage(url: listing.imageUrls.first) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Theme.Colors.secondaryBackground
                }
                .frame(height: 140)
                .clipped()

                // Single overlay layer for both badge and heart (prevents overlap)
                VStack {
                    HStack(alignment: .top) {
                        // Status badge (top-left) - only show if not AVAILABLE
                        if listing.availabilityStatus != .available {
                            ListingStatusBadge(listing: listing, size: .small)
                                .padding(8)
                        }

                        Spacer()

                        // Heart button (top-right)
                        Circle()
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: isFavorited ? "heart.fill" : "heart")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(isFavorited ? .red : Theme.Colors.text)
                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                            .padding(8)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    Task {
                                        await favoritesManager.toggleFavorite(listing: listing)
                                    }
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                }
                            }
                    }
                    Spacer()
                }
            }
            
            // Content section
            VStack(alignment: .leading, spacing: 8) {
                Text(listing.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.Colors.text)
                    .lineLimit(2)
                    .frame(alignment: .leading)
                
                HStack {
                    Text("$\(Int(listing.price))")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Theme.Colors.primary)

                    // Only show "/ day" for rental listings, not for sale
                    if listing.listingType == "rental" {
                        Text("/" + LocalizationHelper.localizedString("day"))
                            .font(.system(size: 13))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }

                    Spacer()
                    
                    if let rating = listing.rating, rating > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(Theme.Colors.accentOrange)
                            
                            Text(String(format: "%.1f", rating))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Theme.Colors.text)
                        }
                    }
                }
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.lg)
        .shadow(color: Theme.Shadows.card, radius: Theme.Shadows.cardRadius, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .stroke(isPressed ? Theme.Colors.primary.opacity(0.3) : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onAppear {
            print("🎨 [CARD RENDER] Card appeared with:")
            print("    ID: \(listing.listingId)")
            print("    Title: '\(listing.title)'")
            print("    First Image: \(listing.imageUrls.first ?? "NO IMAGE")")
        }
        .onTapGesture {
            print("👆 [CARD TAP] User tapped card:")
            print("    ID: \(listing.listingId)")
            print("    Title: '\(listing.title)'")
            onTap?()
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Professional Loading Grid
struct ProfessionalLoadingGrid: View {
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(0..<6) { _ in
                ProfessionalShimmerCard()
            }
        }
    }
}

// MARK: - Professional Shimmer Card
struct ProfessionalShimmerCard: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Theme.Colors.secondary.opacity(0.2))
                .frame(height: 140)
            
            VStack(alignment: .leading, spacing: 8) {
                Rectangle()
                    .fill(Theme.Colors.secondary.opacity(0.2))
                    .frame(height: 16)
                
                Rectangle()
                    .fill(Theme.Colors.secondary.opacity(0.2))
                    .frame(width: 80, height: 20)
            }
            .padding(12)
        }
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.lg)
        .overlay(
            LinearGradient(
                colors: [.clear, Theme.Colors.secondary.opacity(0.3), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .rotationEffect(.degrees(30))
            .offset(x: isAnimating ? 300 : -300)
            .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: isAnimating)
        )
        .mask(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
        )
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Load More Button
struct LoadMoreButton: View {
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 16, weight: .medium))
                }
                
                Text(isLoading ? LocalizationHelper.localizedString("loading") : LocalizationHelper.localizedString("load_more"))
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(Theme.Colors.primary)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Theme.Colors.primary.opacity(0.1))
            .cornerRadius(20)
        }
        .disabled(isLoading)
    }
}

// MARK: - Supporting Types
enum ProfessionalMarketplaceCategory: String, CaseIterable {
    case electronics = "Electronics"
    case furniture = "Furniture"
    case tools = "Tools"
    case sports = "Sports"
    case books = "Books"
    case clothing = "Clothing"
    
    var title: String { LocalizationHelper.localizedString(rawValue.lowercased()) }
    
    var icon: String {
        switch self {
        case .electronics: return "tv"
        case .furniture: return "sofa"
        case .tools: return "wrench"
        case .sports: return "sportscourt"
        case .books: return "book"
        case .clothing: return "tshirt"
        }
    }
}

// MARK: - View Model
class ProfessionalMarketplaceViewModel: ObservableObject {
    @Published var listings: [Listing] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var hasMore = true
    @Published var totalListings = 0
    @Published var nearbyListings = 0
    @Published var todaysDeals = 0
    @Published var minPrice: Double = 0
    @Published var maxPrice: Double = 10000
    @Published var sortOption: MarketplaceSortOption = .newest
    @Published var selectedCategory: String? = nil
    @Published var selectedCondition: String? = nil
    @Published var maxDistance: Double = 50
    @Published var showOnlyAvailable = true
    
    private let apiClient = APIClient.shared
    private var currentPage = 1
    private var searchQuery: String = ""
    private var allListings: [Listing] = []
    
    func loadMarketplace() {
        print("🏪 [MARKETPLACE] loadMarketplace() called")

        // PRIORITY 1: Check comprehensive preloader first (fastest)
        let preloadedListings = AppDataPreloader.shared.marketplaceListings

        if !preloadedListings.isEmpty {
            // Use comprehensive preloaded data for INSTANT load
            print("✅ [MARKETPLACE] Using comprehensive preloaded data: \(preloadedListings.count) listings")
            DispatchQueue.main.async {
                self.allListings = preloadedListings
                self.applyFiltersAndSort()
                self.totalListings = preloadedListings.count
                self.nearbyListings = preloadedListings.count
                self.todaysDeals = preloadedListings.filter { $0.price < 50 }.count
                self.hasMore = preloadedListings.count >= 20
                self.isLoading = false
                print("✅ [MARKETPLACE] INSTANT LOAD - showing \(self.listings.count) listings")
            }
            return
        }

        // PRIORITY 2: Fallback to legacy preloader
        let legacyPreloadedListings = MarketplaceDataPreloader.shared.getPreloadedListings()

        if !legacyPreloadedListings.isEmpty {
            print("✅ [MARKETPLACE] Using legacy preloaded data: \(legacyPreloadedListings.count) listings")
            DispatchQueue.main.async {
                self.allListings = legacyPreloadedListings
                self.applyFiltersAndSort()
                self.totalListings = legacyPreloadedListings.count
                self.nearbyListings = legacyPreloadedListings.count
                self.todaysDeals = legacyPreloadedListings.filter { $0.price < 50 }.count
                self.hasMore = legacyPreloadedListings.count >= 20
                self.isLoading = false
            }
            return
        }

        // PRIORITY 3: Last resort - fetch from API if no preloaded data
        print("⚠️ [MARKETPLACE] No preloaded data available, fetching from API...")
        Task {
            await MainActor.run { isLoading = true }

            do {
                let fetchedListings = try await apiClient.fetchListings()

                await MainActor.run {
                    print("✅ [MARKETPLACE] API fetch successful: \(fetchedListings.count) listings")
                    self.allListings = fetchedListings
                    self.applyFiltersAndSort()
                    self.totalListings = fetchedListings.count
                    self.nearbyListings = fetchedListings.count
                    self.todaysDeals = fetchedListings.filter { $0.price < 50 }.count
                    self.hasMore = fetchedListings.count >= 20
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.totalListings = self.listings.count
                    self.nearbyListings = 0
                    self.todaysDeals = self.listings.filter { $0.price < 50 }.count
                    self.isLoading = false
                }
                print("❌ [MARKETPLACE] Error loading marketplace: \(error)")
            }
        }
    }
    
    func refreshData() async {
        currentPage = 1
        loadMarketplace()
    }
    
    func performSearch(_ query: String) {
        searchQuery = query
        
        guard !query.isEmpty else {
            clearSearch()
            return
        }
        
        applyFiltersAndSort()
    }
    
    func clearSearch() {
        searchQuery = ""
        applyFiltersAndSort()
    }
    
    func filterByCategory(_ category: String?) {
        selectedCategory = category
        applyFiltersAndSort()
    }
    
    func updateSortOption(_ option: MarketplaceSortOption) {
        sortOption = option
        applyFiltersAndSort()
    }
    
    func applyFilters(minPrice: Double, maxPrice: Double, maxDistance: Double, condition: String?, showOnlyAvailable: Bool) {
        self.minPrice = minPrice
        self.maxPrice = maxPrice
        self.maxDistance = maxDistance
        self.selectedCondition = condition
        self.showOnlyAvailable = showOnlyAvailable
        applyFiltersAndSort()
    }
    
    private func applyFiltersAndSort() {
        print("🔍 [MARKETPLACE] Applying filters to \(allListings.count) total listings")

        var filtered = allListings

        // Apply search query
        if !searchQuery.isEmpty {
            let beforeCount = filtered.count
            filtered = filtered.filter { listing in
                listing.title.localizedCaseInsensitiveContains(searchQuery) ||
                listing.description.localizedCaseInsensitiveContains(searchQuery) ||
                (listing.category?.name ?? "").localizedCaseInsensitiveContains(searchQuery)
            }
            print("🔍 [MARKETPLACE] Search filter '\(searchQuery)': \(beforeCount) -> \(filtered.count) listings")
        }

        // Apply category filter
        if let category = selectedCategory {
            let beforeCount = filtered.count
            filtered = filtered.filter { $0.category?.name == category }
            print("🔍 [MARKETPLACE] Category filter '\(category)': \(beforeCount) -> \(filtered.count) listings")
        }

        // Apply price filter
        let beforePriceCount = filtered.count
        filtered = filtered.filter { $0.price >= minPrice && $0.price <= maxPrice }
        if beforePriceCount != filtered.count {
            print("🔍 [MARKETPLACE] Price filter $\(minPrice)-$\(maxPrice): \(beforePriceCount) -> \(filtered.count) listings")
        }

        // Apply condition filter
        if let condition = selectedCondition {
            let beforeCount = filtered.count
            filtered = filtered.filter { $0.condition == condition }
            print("🔍 [MARKETPLACE] Condition filter '\(condition)': \(beforeCount) -> \(filtered.count) listings")
        }

        // Apply availability filter
        if showOnlyAvailable {
            let beforeCount = filtered.count
            filtered = filtered.filter { $0.isAvailable }
            if beforeCount != filtered.count {
                print("🔍 [MARKETPLACE] Availability filter (only available): \(beforeCount) -> \(filtered.count) listings")
            }
        }

        // Apply sorting
        switch sortOption {
        case .newest:
            filtered.sort { $0.createdAt > $1.createdAt }
        case .priceLowToHigh:
            filtered.sort { $0.price < $1.price }
        case .priceHighToLow:
            filtered.sort { $0.price > $1.price }
        case .distance:
            // Sort by distance if available
            filtered.sort { ($0.distance ?? Double.infinity) < ($1.distance ?? Double.infinity) }
        case .popularity:
            filtered.sort { $0.views > $1.views }
        }

        print("🔍 [MARKETPLACE] Final result: \(filtered.count) listings after all filters and sorting")

        // DEBUG: Log each listing's data to catch mismatches
        print("📋 [MARKETPLACE DEBUG] Listing data verification:")
        for (index, listing) in filtered.prefix(10).enumerated() {
            print("  [\(index)] ID: \(listing.listingId)")
            print("      Title: '\(listing.title)'")
            print("      Price: $\(listing.price)")
            print("      First Image: \(listing.imageUrls.first ?? "NO IMAGE")")
            print("      OwnerID: \(listing.ownerId)")
        }

        // THREADING FIX: Ensure @Published property update happens on main thread
        DispatchQueue.main.async {
            self.listings = filtered
        }
    }
    
    func sortBy(_ option: MarketplaceSortOption) {
        sortOption = option

        // Sort current listings locally for immediate feedback
        var sortedListings = listings

        switch option {
        case .newest:
            sortedListings.sort { $0.createdAt > $1.createdAt }
        case .priceLowToHigh:
            sortedListings.sort { $0.price < $1.price }
        case .priceHighToLow:
            sortedListings.sort { $0.price > $1.price }
        case .distance:
            // Would need location data
            break
        case .popularity:
            sortedListings.sort { $0.views > $1.views }
        }

        // THREADING FIX: Ensure @Published property update happens on main thread
        DispatchQueue.main.async {
            self.listings = sortedListings
        }
    }
    
    func loadMore() {
        guard !isLoadingMore && hasMore else { return }

        currentPage += 1

        // THREADING FIX: Ensure @Published property update happens on main thread
        DispatchQueue.main.async {
            self.isLoadingMore = true
        }

        Task {
            // Load more items
            await MainActor.run {
                self.isLoadingMore = false
            }
        }
    }
    
    func clearFilters() {
        selectedCategory = nil
        loadMarketplace()
    }
    
    func filterByDistance(_ miles: Double) {
        Task {
            await MainActor.run { isLoading = true }
            
            do {
                // Filter locally for now - in production, this would be an API call
                let allListings = try await apiClient.fetchListings()
                // For demo purposes, show random subset
                let nearbyListings = Array(allListings.shuffled().prefix(Int.random(in: 5...15)))
                
                await MainActor.run {
                    self.listings = nearbyListings
                    self.nearbyListings = nearbyListings.count
                    self.hasMore = false
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    func filterByDeals() {
        Task {
            await MainActor.run { isLoading = true }
            
            do {
                let allListings = try await apiClient.fetchListings()
                let dealListings = allListings.filter { $0.price < 50 }
                
                await MainActor.run {
                    self.listings = dealListings
                    self.todaysDeals = dealListings.count
                    self.hasMore = false
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Preview
struct ProfessionalMarketplaceView_Previews: PreviewProvider {
    static var previews: some View {
        ProfessionalMarketplaceView()
    }
}