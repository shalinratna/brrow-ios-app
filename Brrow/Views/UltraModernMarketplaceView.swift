import SwiftUI
import Combine

struct UltraModernMarketplaceView: View {
    @StateObject private var viewModel = MarketplaceViewModel()
    @State private var searchText = ""
    @State private var showFilters = false
    @State private var selectedCategory: String = "All"
    @State private var animateIn = false
    @State private var pulseAnimation = false
    @State private var selectedListing: Listing?
    @State private var showingListingDetail = false
    @State private var gradientRotation = 0.0
    @FocusState private var searchFocused: Bool
    
    let categories = [
        ("All", "square.grid.2x2", Color.gray),
        ("Electronics", "tv", Color.blue),
        ("Fashion", "tshirt", Color.pink),
        ("Home", "house", Color.green),
        ("Sports", "sportscourt", Color.orange),
        ("Books", "book", Color.purple),
        ("Tools", "hammer", Color.red),
        ("Other", "ellipsis.circle", Color.indigo)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Animated gradient background
                animatedBackground
                
                VStack(spacing: 0) {
                    // Custom navigation header
                    customHeader
                    
                    // Main content
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            // Search bar with effects
                            searchSection
                                .padding(.horizontal, 20)
                            
                            // Animated category pills
                            categoryPills
                            
                            // Results or listings
                            if viewModel.isSearching {
                                searchResults
                            } else {
                                // Featured section
                                if !viewModel.featuredListings.isEmpty {
                                    featuredSection
                                }
                                
                                // Main listings grid
                                mainListingsGrid
                            }
                        }
                        .padding(.bottom, 100)
                    }
                }
                
                // Loading overlay
                if viewModel.isLoading {
                    loadingOverlay
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                startAnimations()
                viewModel.loadListings()
            }
            .sheet(isPresented: $showFilters) {
                MarketplaceFiltersView(
                    selectedCategory: .constant(selectedCategory),
                    onApply: { filters in
                        // Apply filters to view model
                        viewModel.activeFiltersCount = 1 // Update based on actual filters
                        showFilters = false
                    }
                )
            }
            .sheet(item: $selectedListing) { listing in
                NavigationView {
                    ListingDetailView(listing: listing)
                }
            }
        }
    }
    
    // MARK: - Animated Background
    private var animatedBackground: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(#colorLiteral(red: 0.9725490196, green: 0.9764705882, blue: 0.9882352941, alpha: 1)),
                    Color(#colorLiteral(red: 0.9411764706, green: 0.9529411765, blue: 0.9803921569, alpha: 1))
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Floating orbs
            ForEach(0..<5) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Theme.Colors.primary.opacity(0.3),
                                Theme.Colors.primary.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 30)
                    .offset(
                        x: animateIn ? CGFloat.random(in: -150...150) : 0,
                        y: animateIn ? CGFloat.random(in: -300...300) : 0
                    )
                    .animation(
                        .easeInOut(duration: Double.random(in: 15...25))
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.5),
                        value: animateIn
                    )
            }
        }
    }
    
    // MARK: - Custom Header
    private var customHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Discover")
                    .font(.largeTitle.bold())
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.Colors.primary, Theme.Colors.primary.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("Find amazing items near you")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Notification button
            Button(action: {}) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.title2)
                        .foregroundColor(.primary)
                    
                    Circle()
                        .fill(Color.red)
                        .frame(width: 10, height: 10)
                        .offset(x: 3, y: -3)
                }
            }
            .padding(12)
            .background(
                Circle()
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 10)
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .padding(.bottom, 20)
    }
    
    // MARK: - Search Section
    private var searchSection: some View {
        HStack(spacing: 12) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.body.bold())
                
                TextField("Search for anything...", text: $searchText)
                    .focused($searchFocused)
                    .onSubmit {
                        viewModel.searchListings(query: searchText)
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        viewModel.clearSearch()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(
                        color: searchFocused ? Theme.Colors.primary.opacity(0.3) : .black.opacity(0.1),
                        radius: searchFocused ? 20 : 15,
                        y: 5
                    )
            )
            .scaleEffect(searchFocused ? 1.02 : 1.0)
            .animation(.spring(response: 0.3), value: searchFocused)
            
            // Filter button
            Button(action: { showFilters = true }) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title3)
                        .foregroundColor(Theme.Colors.primary)
                    
                    if viewModel.activeFiltersCount > 0 {
                        Text("\(viewModel.activeFiltersCount)")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .frame(width: 18, height: 18)
                            .background(Circle().fill(Color.red))
                            .offset(x: 8, y: -8)
                    }
                }
                .frame(width: 52, height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 15, y: 5)
                )
            }
            .scaleEffect(pulseAnimation ? 1.1 : 1.0)
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
        .animation(.spring(response: 0.6).delay(0.2), value: animateIn)
    }
    
    // MARK: - Category Pills
    private var categoryPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories, id: \.0) { category in
                    UltraModernCategoryPill(
                        title: category.0,
                        icon: category.1,
                        color: category.2,
                        isSelected: selectedCategory == category.0,
                        action: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedCategory = category.0
                                HapticManager.impact(style: .light)
                                
                                if category.0 == "All" {
                                    viewModel.clearCategoryFilter()
                                } else {
                                    viewModel.filterByCategory(category.0)
                                }
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
        .opacity(animateIn ? 1 : 0)
        .animation(.spring(response: 0.6).delay(0.3), value: animateIn)
    }
    
    // MARK: - Featured Section
    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Featured", systemImage: "star.fill")
                    .font(.title3.bold())
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("See all") {
                    // Show all featured
                }
                .font(.subheadline)
                .foregroundColor(Theme.Colors.primary)
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.featuredListings) { listing in
                        FeaturedListingCard(listing: listing) {
                            selectedListing = listing
                        }
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .opacity(animateIn ? 1 : 0)
        .animation(.spring(response: 0.6).delay(0.4), value: animateIn)
    }
    
    // MARK: - Search Results
    private var searchResults: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Search Results")
                    .font(.title3.bold())
                
                Text("(\(viewModel.searchResults.count) items)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            if viewModel.searchResults.isEmpty && !viewModel.isLoading {
                EmptySearchView(searchQuery: searchText)
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ],
                    spacing: 16
                ) {
                    ForEach(viewModel.searchResults) { listing in
                        ModernListingCard(listing: listing) {
                            selectedListing = listing
                        }
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Main Listings Grid
    private var mainListingsGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Near you")
                    .font(.title3.bold())
                
                Spacer()
                
                Menu {
                    Button("Newest First") {
                        viewModel.sortBy(.newest)
                    }
                    Button("Price: Low to High") {
                        viewModel.sortBy(.priceLowToHigh)
                    }
                    Button("Price: High to Low") {
                        viewModel.sortBy(.priceHighToLow)
                    }
                    Button("Distance") {
                        viewModel.sortBy(.distance)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("Sort")
                            .font(.subheadline)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(Theme.Colors.primary)
                }
            }
            .padding(.horizontal, 20)
            
            if viewModel.filteredListings.isEmpty && !viewModel.isLoading {
                EmptyListingsView()
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ],
                    spacing: 16
                ) {
                    ForEach(viewModel.filteredListings) { listing in
                        ModernListingCard(listing: listing) {
                            selectedListing = listing
                        }
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                    }
                    
                    // Load more indicator
                    if viewModel.hasMorePages {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .onAppear {
                                viewModel.loadMoreListings()
                            }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .opacity(animateIn ? 1 : 0)
        .animation(.spring(response: 0.6).delay(0.5), value: animateIn)
    }
    
    // MARK: - Loading Overlay
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(Theme.Colors.primary)
                
                Text("Loading amazing items...")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
        }
    }
    
    // MARK: - Helper Functions
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.8)) {
            animateIn = true
        }
        
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseAnimation = true
        }
        
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            gradientRotation = 360
        }
    }
}

// MARK: - Supporting Views

struct UltraModernCategoryPill: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                
                Text(title)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? color : Color(.systemGray6))
                    .overlay(
                        isSelected ? nil : Capsule().stroke(Color(.systemGray4), lineWidth: 1)
                    )
            )
            .shadow(
                color: isSelected ? color.opacity(0.3) : .clear,
                radius: 10,
                y: 5
            )
        }
    }
}

struct FeaturedListingCard: View {
    let listing: Listing
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Image with gradient overlay
                ZStack(alignment: .bottomLeading) {
                    if let imageUrl = listing.images.first {
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .shimmer()
                        }
                        .frame(width: 200, height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    // Gradient overlay
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.6),
                            Color.clear
                        ],
                        startPoint: .bottom,
                        endPoint: .center
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Price badge
                    HStack {
                        Text("$\(Int(listing.price))")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                        
                        if listing.type == "rental" {
                            Text("/day")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                    )
                    .padding(12)
                }
                
                // Title and category
                VStack(alignment: .leading, spacing: 4) {
                    Text(listing.title)
                        .font(.subheadline.bold())
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption2)
                        Text("\(listing.distance ?? 0.0, specifier: "%.1f") mi")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
                .frame(width: 200, alignment: .leading)
            }
        }
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .onTapGesture {
            withAnimation(.spring(response: 0.3)) {
                isHovered = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3)) {
                    isHovered = false
                }
                action()
            }
        }
    }
}

struct ModernListingCard: View {
    let listing: Listing
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                // Image
                ZStack(alignment: .topTrailing) {
                    if let imageUrl = listing.images.first {
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .shimmer()
                        }
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    
                    // Like button
                    Button(action: {
                        // Toggle favorite
                        HapticManager.impact(style: .light)
                    }) {
                        Image(systemName: listing.isFavorite ? "heart.fill" : "heart")
                            .font(.title3)
                            .foregroundColor(listing.isFavorite ? .red : .white)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                            )
                    }
                    .padding(8)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    Text(listing.title)
                        .font(.subheadline.bold())
                        .lineLimit(2)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        Text("$\(Int(listing.price))")
                            .font(.headline)
                            .foregroundColor(Theme.Colors.primary)
                        
                        if listing.type == "rental" {
                            Text("/day")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundColor(.orange)
                            Text("4.8")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Location
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(listing.distance ?? 0.0, specifier: "%.1f") miles away")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
                    .shadow(
                        color: isPressed ? Theme.Colors.primary.opacity(0.2) : .black.opacity(0.08),
                        radius: isPressed ? 20 : 12,
                        y: isPressed ? 10 : 5
                    )
            )
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onTapGesture {
            withAnimation(.spring(response: 0.3)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3)) {
                    isPressed = false
                }
                action()
            }
        }
    }
}

struct EmptySearchView: View {
    let searchQuery: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.Colors.primary, Theme.Colors.primary.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("No results for \"\(searchQuery)\"")
                .font(.title3.bold())
                .foregroundColor(.primary)
            
            Text("Try searching with different keywords")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(60)
    }
}

struct EmptyListingsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "cube.box.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.Colors.primary, Theme.Colors.primary.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("No items found")
                .font(.title3.bold())
                .foregroundColor(.primary)
            
            Text("Check back later for new listings")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(60)
    }
}

// MARK: - View Model

class MarketplaceViewModel: ObservableObject {
    @Published var listings: [Listing] = []
    @Published var filteredListings: [Listing] = []
    @Published var featuredListings: [Listing] = []
    @Published var searchResults: [Listing] = []
    @Published var isLoading = false
    @Published var isSearching = false
    @Published var activeFiltersCount = 0
    @Published var hasMorePages = true
    
    private var currentPage = 1
    private var searchQuery = ""
    private var selectedCategory: String?
    private var sortOption: SortOption = .newest
    private var cancellables = Set<AnyCancellable>()
    
    private let apiClient = APIClient.shared
    
    enum SortOption {
        case newest, priceLowToHigh, priceHighToLow, distance
    }
    
    init() {
        setupSearchDebounce()
    }
    
    private func setupSearchDebounce() {
        // Auto-search after user stops typing
        $isSearching
            .removeDuplicates()
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                // Handled in searchListings
            }
            .store(in: &cancellables)
    }
    
    func loadListings() {
        guard !isLoading else { return }
        
        isLoading = true
        currentPage = 1
        
        Task {
            do {
                // Load featured listings
                async let featured = apiClient.fetchFeaturedListings(limit: 10)
                
                // Load regular listings
                async let regular = apiClient.fetchListings()
                
                let (featuredResponse, regularResponse) = try await (featured, regular)
                
                await MainActor.run {
                    self.featuredListings = featuredResponse.data?.listings ?? []
                    self.listings = regularResponse
                    self.filteredListings = regularResponse
                    self.hasMorePages = regularResponse.count >= 20
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    print("Error loading listings: \(error)")
                }
            }
        }
    }
    
    func loadMoreListings() {
        guard !isLoading && hasMorePages else { return }
        
        currentPage += 1
        
        Task {
            do {
                let moreListings = try await apiClient.fetchListings()
                
                await MainActor.run {
                    self.listings.append(contentsOf: moreListings)
                    self.applyFiltersAndSort()
                    self.hasMorePages = moreListings.count >= 20
                }
            } catch {
                print("Error loading more listings: \(error)")
            }
        }
    }
    
    func searchListings(query: String) {
        guard !query.isEmpty else {
            clearSearch()
            return
        }
        
        searchQuery = query
        isSearching = true
        isLoading = true
        
        Task {
            do {
                let results = try await apiClient.searchListings(query: query)
                
                await MainActor.run {
                    self.searchResults = results
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    print("Search error: \(error)")
                }
            }
        }
    }
    
    func clearSearch() {
        searchQuery = ""
        isSearching = false
        searchResults = []
    }
    
    func filterByCategory(_ category: String) {
        selectedCategory = category
        applyFiltersAndSort()
    }
    
    func clearCategoryFilter() {
        selectedCategory = nil
        applyFiltersAndSort()
    }
    
    func sortBy(_ option: SortOption) {
        sortOption = option
        applyFiltersAndSort()
    }
    
    private func applyFiltersAndSort() {
        var filtered = listings
        
        // Apply category filter
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category.lowercased() == category.lowercased() }
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
            filtered.sort { ($0.distance ?? 999) < ($1.distance ?? 999) }
        }
        
        withAnimation {
            filteredListings = filtered
        }
    }
}

// MARK: - Shimmer Effect
extension View {
    func shimmer() -> some View {
        self
            .redacted(reason: .placeholder)
            .overlay(
                GeometryReader { geometry in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0.8),
                                    Color.white.opacity(0.4)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .rotationEffect(.degrees(30))
                        .offset(x: -geometry.size.width)
                        .animation(
                            .linear(duration: 1.5)
                            .repeatForever(autoreverses: false),
                            value: true
                        )
                }
                .mask(self)
            )
    }
}

// Preview
struct UltraModernMarketplaceView_Previews: PreviewProvider {
    static var previews: some View {
        UltraModernMarketplaceView()
    }
}