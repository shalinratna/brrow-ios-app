import SwiftUI
import MapKit

struct InfiniteMarketplaceView: View {
    @StateObject private var viewModel = InfiniteMarketplaceViewModel()
    @State private var searchText = ""
    @State private var showFilters = false
    @State private var showMap = false
    @State private var selectedContentType: ContentType = .all
    @State private var isSearchFocused = false
    @FocusState private var searchFieldFocused: Bool
    
    enum ContentType: String, CaseIterable {
        case all = "All"
        case listings = "Items"
        case garageSales = "Garage Sales"
        
        var icon: String {
            switch self {
            case .all: return "square.grid.3x3"
            case .listings: return "cube.box"
            case .garageSales: return "house"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom navigation header
                    customHeader
                    
                    // Search bar
                    searchSection
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    
                    // Content type selector
                    contentTypeSelector
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    
                    // Main content
                    if showMap && selectedContentType != .listings {
                        EnhancedGarageSaleMapView()
                            .ignoresSafeArea(edges: .bottom)
                    } else {
                        infiniteScrollContent
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showFilters) {
            MarketplaceFiltersView(
                selectedCategory: .constant(nil),
                onApply: { filters in
                    viewModel.applyFilters(filters)
                }
            )
        }
        .onAppear {
            viewModel.loadInitialContent()
        }
        .onChange(of: selectedContentType) { newType in
            print("🔄 DEBUG: Content type changed to: \(newType)")
            if newType == .garageSales && viewModel.garageSales.isEmpty {
                print("📍 DEBUG: Loading garage sales because array is empty")
                viewModel.loadInitialContent()
            }
        }
    }
    
    // MARK: - Custom Header
    private var customHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Discover")
                    .font(.largeTitle.bold())
                
                Text(greetingText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Map toggle button (only for garage sales)
            if selectedContentType != .listings {
                Button(action: { withAnimation { showMap.toggle() } }) {
                    Image(systemName: showMap ? "square.grid.2x2" : "map")
                        .font(.title3)
                        .foregroundColor(Theme.Colors.primary)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Theme.Colors.primary.opacity(0.1))
                        )
                }
            }
            
            // Filter button
            Button(action: { showFilters = true }) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title3)
                        .foregroundColor(Theme.Colors.primary)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Theme.Colors.primary.opacity(0.1))
                        )
                    
                    if viewModel.activeFiltersCount > 0 {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .offset(x: 5, y: -5)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 60)
        .padding(.bottom, 16)
    }
    
    // MARK: - Search Section
    private var searchSection: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search items, garage sales...", text: $searchText)
                    .focused($searchFieldFocused)
                    .onSubmit {
                        viewModel.search(query: searchText)
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        viewModel.clearSearch()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            
            if searchFieldFocused {
                Button("Cancel") {
                    searchFieldFocused = false
                    searchText = ""
                    viewModel.clearSearch()
                }
                .foregroundColor(Theme.Colors.primary)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: searchFieldFocused)
    }
    
    // MARK: - Content Type Selector
    private var contentTypeSelector: some View {
        HStack(spacing: 12) {
            ForEach(ContentType.allCases, id: \.self) { type in
                ContentTypeChip(
                    type: type,
                    isSelected: selectedContentType == type,
                    count: viewModel.getCount(for: type)
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedContentType = type
                        viewModel.filterByType(type)
                    }
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Infinite Scroll Content
    private var infiniteScrollContent: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Featured section
                if !viewModel.featuredItems.isEmpty && searchText.isEmpty {
                    featuredSection
                }
                
                // Main content grid
                if selectedContentType == .garageSales {
                    // Garage sales list
                    ForEach(viewModel.garageSales) { sale in
                        NavigationLink(destination: GarageSaleDetailView(sale: sale)) {
                            MarketplaceGarageSaleCard(garageSale: sale)
                                .padding(.horizontal)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                } else {
                    // Mixed content or listings only
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(Array(viewModel.items.enumerated()), id: \.offset) { index, item in
                            Group {
                                if let listing = item as? Listing {
                                    Button(action: {
                                        ListingNavigationManager.shared.showListing(listing)
                                    }) {
                                        InfiniteListingCard(listing: listing)
                                    }
                                } else if let sale = item as? GarageSale {
                                    NavigationLink(destination: GarageSaleDetailView(sale: sale)) {
                                        InfiniteGarageSaleCard(garageSale: sale)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .onAppear {
                                // Load more when reaching the end
                                if viewModel.shouldLoadMore(item: item) {
                                    viewModel.loadMore()
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Loading indicator
                if viewModel.isLoadingMore {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading more...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                
                // Empty state
                if viewModel.items.isEmpty && !viewModel.isLoading {
                    EmptyStateView(
                        title: "No items found",
                        message: "Try adjusting your filters or search",
                        systemImage: "magnifyingglass"
                    )
                    .frame(minHeight: 400)
                }
            }
            .padding(.bottom, 100)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
    
    // MARK: - Featured Section
    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Featured", systemImage: "star.fill")
                    .font(.headline)
                    .foregroundColor(.orange)
                
                Spacer()
                
                NavigationLink(destination: Text("All Featured")) {
                    Text("See all")
                        .font(.subheadline)
                        .foregroundColor(Theme.Colors.primary)
                }
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(viewModel.featuredItems.enumerated()), id: \.offset) { index, item in
                        if let listing = item as? Listing {
                            Button(action: {
                                ListingNavigationManager.shared.showListing(listing)
                            }) {
                                InfiniteFeaturedCard(listing: listing)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }
}

// MARK: - Supporting Views

struct ContentTypeChip: View {
    let type: InfiniteMarketplaceView.ContentType
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.caption)
                
                Text(type.rawValue)
                    .font(.subheadline.weight(.medium))
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white.opacity(0.3) : Theme.Colors.primary.opacity(0.1))
                        )
                }
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Theme.Colors.primary : Color(.systemGray6))
            )
        }
    }
}

struct InfiniteListingCard: View {
    let listing: Listing
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image with badges
            ZStack(alignment: .topLeading) {
                if let imageUrl = listing.imageUrls.first {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )
                    }
                    .frame(height: 160)
                    .clipped()
                }
                
                // Badges
                VStack(alignment: .leading, spacing: 4) {
                    if listing.isPromoted {
                        Label("Featured", systemImage: "star.fill")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.orange)
                            )
                    }
                    
                    if "listing" == "rental" {
                        Label("Rental", systemImage: "arrow.triangle.2.circlepath")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.blue)
                            )
                    }
                }
                .padding(8)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(listing.title)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                
                HStack {
                    Text("$\(Int(listing.price))")
                        .font(.headline)
                        .foregroundColor(Theme.Colors.primary)
                    
                    if "listing" == "rental" {
                        Text("/day")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Text(String(format: "%.1f", listing.rating ?? 0))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "location")
                        .font(.caption2)
                    Text(listing.location.city)
                        .font(.caption)
                        .lineLimit(1)
                }
                .foregroundColor(.secondary)
            }
            .padding(12)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

struct InfiniteGarageSaleCard: View {
    let garageSale: GarageSale
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            ZStack(alignment: .topTrailing) {
                if let imageUrl = garageSale.images.first {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .overlay(
                                Image(systemName: "house.fill")
                                    .foregroundColor(.gray)
                            )
                    }
                    .frame(height: 160)
                    .clipped()
                }
                
                // Live indicator
                if garageSale.isActive {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                        Text("LIVE")
                            .font(.caption2.bold())
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.7))
                    )
                    .padding(8)
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "house.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text("Garage Sale")
                        .font(.caption.bold())
                        .foregroundColor(.orange)
                }
                
                Text(garageSale.title)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text(formatDate(garageSale.startDate))
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            .padding(12)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    private func formatDate(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        guard let date = inputFormatter.date(from: dateString) else { return dateString }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}

struct InfiniteFeaturedCard: View {
    let listing: Listing
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            if let imageUrl = listing.imageUrls.first {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                }
                .frame(width: 200, height: 150)
                .clipped()
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(listing.title)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                
                Text("$\(Int(listing.price))")
                    .font(.headline)
                    .foregroundColor(Theme.Colors.primary)
            }
            .padding(12)
        }
        .frame(width: 200)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

struct MarketplaceGarageSaleCard: View {
    let garageSale: GarageSale
    
    var body: some View {
        HStack(spacing: 16) {
            // Image
            if let imageUrl = garageSale.images.first {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay(
                            Image(systemName: "house.fill")
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                if garageSale.isActive {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                        Text("LIVE NOW")
                            .font(.caption.bold())
                            .foregroundColor(.red)
                    }
                }
                
                Text(garageSale.title)
                    .font(.headline)
                    .lineLimit(2)
                
                HStack {
                    Image(systemName: "location.fill")
                        .font(.caption)
                    Text(garageSale.address ?? garageSale.location)
                        .font(.caption)
                        .lineLimit(1)
                }
                .foregroundColor(.secondary)
                
                HStack {
                    Label("\(garageSale.photos.count) items", systemImage: "cube.box")
                    Spacer()
                    Text(formatDistance(garageSale.distance))
                        .foregroundColor(.secondary)
                }
                .font(.caption)
            }
            
            Spacer()
            
            // Arrow
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    private func formatDistance(_ distance: Double?) -> String {
        guard let distance = distance else { return "" }
        if distance < 1 {
            return String(format: "%.0f ft", distance * 5280)
        } else {
            return String(format: "%.1f mi", distance)
        }
    }
}

// MARK: - View Model

class InfiniteMarketplaceViewModel: ObservableObject {
    @Published var items: [Any] = []
    @Published var featuredItems: [Any] = []
    @Published var garageSales: [GarageSale] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var activeFiltersCount = 0
    
    private var currentPage = 1
    private var hasMorePages = true
    private var currentType: InfiniteMarketplaceView.ContentType = .all
    
    private let apiClient = APIClient.shared
    
    func loadInitialContent() {
        Task {
            await MainActor.run { isLoading = true }
            
            do {
                // Load featured items
                let featuredResponse = try await apiClient.fetchFeaturedListings(limit: 10)
                
                // Load regular items
                let listingsResponse = try await apiClient.fetchListings()
                
                // Load garage sales
                let garageSalesResponse = try await apiClient.fetchGarageSales()
                print("📍 DEBUG: Fetched \(garageSalesResponse.count) garage sales from API")
                
                await MainActor.run {
                    self.featuredItems = featuredResponse.data?.listings ?? []
                    self.items = self.mixContent(
                        listings: listingsResponse,
                        garageSales: garageSalesResponse
                    )
                    self.garageSales = garageSalesResponse
                    print("🎯 DEBUG: Set viewModel.garageSales to \(garageSalesResponse.count) items")
                    self.isLoading = false
                }
            } catch {
                await MainActor.run { isLoading = false }
                print("Error loading content: \(error)")
            }
        }
    }
    
    func loadMore() {
        guard !isLoadingMore && hasMorePages else { return }
        
        Task {
            await MainActor.run { isLoadingMore = true }
            
            do {
                currentPage += 1
                let moreListings = try await apiClient.fetchListings()
                
                await MainActor.run {
                    self.items.append(contentsOf: moreListings)
                    self.hasMorePages = moreListings.count >= 20
                    self.isLoadingMore = false
                }
            } catch {
                await MainActor.run {
                    self.isLoadingMore = false
                    self.currentPage -= 1
                }
            }
        }
    }
    
    func refresh() async {
        currentPage = 1
        hasMorePages = true
        loadInitialContent()
    }
    
    func search(query: String) {
        // Implement search
    }
    
    func clearSearch() {
        loadInitialContent()
    }
    
    func filterByType(_ type: InfiniteMarketplaceView.ContentType) {
        currentType = type
        currentPage = 1
        
        // Filter existing content immediately for better UX
        switch type {
        case .all:
            loadInitialContent()
        case .listings:
            items = items.filter { $0 is Listing }
        case .garageSales:
            items = garageSales
        }
    }
    
    func applyFilters(_ filters: MarketplaceFilters) {
        // Apply filters and reload
        activeFiltersCount = 1 // Count actual filters
        loadInitialContent()
    }
    
    func shouldLoadMore(item: Any) -> Bool {
        guard let lastItem = items.last else { return false }
        
        if let listing = item as? Listing, let lastListing = lastItem as? Listing {
            return listing.id == lastListing.id
        } else if let sale = item as? GarageSale, let lastSale = lastItem as? GarageSale {
            return sale.id == lastSale.id
        }
        
        return false
    }
    
    func getCount(for type: InfiniteMarketplaceView.ContentType) -> Int {
        switch type {
        case .all: return items.count
        case .listings: return items.filter { $0 is Listing }.count
        case .garageSales: return garageSales.count
        }
    }
    
    private func mixContent(listings: [Listing], garageSales: [GarageSale]) -> [Any] {
        var mixed: [Any] = []
        
        // Mix listings and garage sales
        mixed.append(contentsOf: listings)
        
        // Insert garage sales every 6 items
        for (index, sale) in garageSales.enumerated() {
            let insertIndex = min((index + 1) * 6, mixed.count)
            mixed.insert(sale, at: insertIndex)
        }
        
        return mixed
    }
}