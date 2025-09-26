import SwiftUI
import CoreLocation

struct ModernMarketplaceView: View {
    @StateObject private var viewModel = ModernMarketplaceViewModel()
    @State private var searchText = ""
    @State private var selectedFilter = "All"
    @State private var showingFilterSheet = false
    @State private var showingListingDetail = false
    @State private var selectedListing: Listing?
    @State private var refreshID = UUID()
    @State private var animateCards = false
    
    // Grid columns for dynamic layout
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    let filters = ["All", "Trending", "Near Me", "Free", "New"]
    
    var body: some View {
        ZStack {
                // Animated gradient background
                MarketplaceBackground()
                
                VStack(spacing: 0) {
                    // Custom navigation header
                    marketplaceHeader
                    
                    // Filters and search
                    filterSection
                    
                    // Main content
                    ScrollView {
                        VStack(spacing: 24) {
                            // Featured section
                            if viewModel.isLoading {
                                // Loading state for featured
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Label("Featured Today", systemImage: "star.fill")
                                            .font(.headline)
                                            .foregroundColor(Theme.Colors.primary)
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 16) {
                                            ForEach(0..<3, id: \.self) { _ in
                                                FeaturedCardSkeleton()
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            } else if !viewModel.featuredListings.isEmpty {
                                featuredSection
                            } else if viewModel.errorMessage == nil {
                                // Empty state for featured
                                VStack(spacing: 16) {
                                    Image(systemName: "star")
                                        .font(.system(size: 48))
                                        .foregroundColor(.secondary.opacity(0.5))
                                    
                                    Text("No Featured Items")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    
                                    Text("Check back later for featured listings")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary.opacity(0.8))
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            }
                            
                            // Categories
                            if viewModel.isLoading {
                                // Loading state for categories
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Browse by Category")
                                        .font(.headline)
                                        .padding(.horizontal)
                                    
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 16) {
                                        ForEach(0..<8, id: \.self) { _ in
                                            CategoryIconSkeleton()
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            } else if !viewModel.categories.isEmpty {
                                categoriesSection
                            } else {
                                // Empty state for categories
                                VStack(spacing: 16) {
                                    Image(systemName: "square.grid.2x2")
                                        .font(.system(size: 48))
                                        .foregroundColor(.secondary.opacity(0.5))
                                    
                                    Text("No Categories Available")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    
                                    Text("Categories will be loaded from your preferences")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary.opacity(0.8))
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            }
                            
                            // Feed
                            if viewModel.isLoading {
                                // Loading state for feed
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Text("For You")
                                            .font(.headline)
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                    
                                    LazyVStack(spacing: 16) {
                                        ForEach(0..<3, id: \.self) { _ in
                                            FeedCardSkeleton()
                                        }
                                    }
                                }
                            } else if !viewModel.feedListings.isEmpty {
                                feedSection
                            } else if viewModel.errorMessage == nil {
                                // Empty state for feed
                                VStack(spacing: 16) {
                                    Image(systemName: "tray")
                                        .font(.system(size: 48))
                                        .foregroundColor(.secondary.opacity(0.5))
                                    
                                    Text("No Items Found")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    
                                    Text("Try adjusting your filters or check back later for new listings")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary.opacity(0.8))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 40)
                                    
                                    Button("Browse All Categories") {
                                        // Reset filters and load all
                                        viewModel.resetFilters()
                                        viewModel.loadMarketplaceData()
                                    }
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Theme.Colors.primary)
                                    )
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 60)
                            }
                        }
                        .padding(.bottom, 100)
                    }
                    .refreshable {
                        await refreshContent()
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingFilterSheet) {
                FilterSheetView(viewModel: viewModel)
            }
            .sheet(item: $selectedListing) { listing in
                ListingDetailSheet(listing: listing)
            }
            .onAppear {
                startAnimations()
                if viewModel.feedListings.isEmpty && !viewModel.isLoading {
                    viewModel.loadMarketplaceData()
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
                Button("Retry") {
                    viewModel.loadMarketplaceData()
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
    }
    
    // MARK: - Header
    private var marketplaceHeader: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Marketplace")
                        .font(.largeTitle.bold())
                    
                    Text("Discover amazing items near you")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Cart/saved items indicator
                ZStack(alignment: .topTrailing) {
                    Button(action: {}) {
                        Image(systemName: "heart.fill")
                            .font(.title2)
                            .foregroundColor(Theme.Colors.primary)
                    }
                    
                    if viewModel.savedItemsCount > 0 {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 10, height: 10)
                            .offset(x: 5, y: -5)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 60)
            
            // Search bar with animations
            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search marketplace...", text: $searchText)
                        .onSubmit {
                            viewModel.search(query: searchText)
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                )
                
                Button(action: { showingFilterSheet = true }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Theme.Colors.primary.opacity(0.1))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(Theme.Colors.primary)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Filter Section
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(filters, id: \.self) { filter in
                    ModernFilterChip(
                        title: filter,
                        isSelected: selectedFilter == filter,
                        icon: filterIcon(for: filter),
                        action: {
                            withAnimation(.spring()) {
                                selectedFilter = filter
                                viewModel.applyFilter(filter)
                                HapticManager.impact(style: .light)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
    }
    
    // MARK: - Featured Section
    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Featured Today", systemImage: "star.fill")
                    .font(.headline)
                    .foregroundColor(Theme.Colors.primary)
                
                Spacer()
                
                Button("See All") {
                    // Navigate to featured
                }
                .font(.subheadline)
                .foregroundColor(Theme.Colors.primary)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.featuredListings) { listing in
                        FeaturedCard(listing: listing) {
                            selectedListing = listing
                        }
                        .scaleEffect(animateCards ? 1 : 0.9)
                        .opacity(animateCards ? 1 : 0)
                        .animation(
                            .spring()
                            .delay(Double(viewModel.featuredListings.firstIndex(where: { $0.id == listing.id }) ?? 0) * 0.1),
                            value: animateCards
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Categories Section
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Browse by Category")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 16) {
                ForEach(viewModel.categories) { category in
                    CategoryIcon(category: category) {
                        viewModel.selectCategory(category)
                    }
                    .scaleEffect(animateCards ? 1 : 0.8)
                    .opacity(animateCards ? 1 : 0)
                    .animation(
                        .spring()
                        .delay(Double(viewModel.categories.firstIndex(where: { $0.id == category.id }) ?? 0) * 0.05),
                        value: animateCards
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Feed Section
    private var feedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("For You")
                    .font(.headline)
                
                Spacer()
                
                Menu {
                    Button(action: { viewModel.sortBy(.newest) }) {
                        Label("Newest First", systemImage: "clock")
                    }
                    Button(action: { viewModel.sortBy(.priceLowest) }) {
                        Label("Price: Low to High", systemImage: "arrow.up")
                    }
                    Button(action: { viewModel.sortBy(.priceHighest) }) {
                        Label("Price: High to Low", systemImage: "arrow.down")
                    }
                    Button(action: { viewModel.sortBy(.distance) }) {
                        Label("Distance", systemImage: "location")
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
            .padding(.horizontal)
            
            // Instagram/Facebook-like feed
            LazyVStack(spacing: 0) {
                ForEach(viewModel.feedListings) { listing in
                    FeedCard(listing: listing, onLike: {
                        viewModel.toggleLike(listing)
                    }, onShare: {
                        viewModel.share(listing)
                    }, onTap: {
                        selectedListing = listing
                    })
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                    
                    Divider()
                        .padding(.vertical, 8)
                }
                
                // Load more indicator
                if viewModel.isLoadingMore {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Helpers
    private func filterIcon(for filter: String) -> String {
        switch filter {
        case "Trending": return "flame.fill"
        case "Near Me": return "location.fill"
        case "Free": return "gift.fill"
        case "New": return "sparkles"
        default: return "square.grid.2x2"
        }
    }
    
    private func startAnimations() {
        withAnimation(.spring().delay(0.2)) {
            animateCards = true
        }
    }
    
    private func refreshContent() async {
        await viewModel.refreshMarketplace()
        HapticManager.impact(style: .light)
    }
}

// MARK: - Supporting Views

struct MarketplaceBackground: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Theme.Colors.primary.opacity(0.03)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Animated shapes
            GeometryReader { geometry in
                ForEach(0..<3) { i in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Theme.Colors.primary.opacity(0.1),
                                    Theme.Colors.primary.opacity(0.02),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 150
                            )
                        )
                        .frame(width: 300, height: 300)
                        .blur(radius: 60)
                        .offset(
                            x: animate ? CGFloat.random(in: -100...geometry.size.width) : CGFloat.random(in: -100...geometry.size.width),
                            y: animate ? CGFloat.random(in: -100...geometry.size.height) : CGFloat.random(in: -100...geometry.size.height)
                        )
                        .animation(
                            .easeInOut(duration: Double.random(in: 20...30))
                                .repeatForever(autoreverses: true),
                            value: animate
                        )
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            animate = true
        }
    }
}

struct ModernFilterChip: View {
    let title: String
    let isSelected: Bool
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                
                Text(title)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundColor(isSelected ? .white : Theme.Colors.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Theme.Colors.primary : Theme.Colors.primary.opacity(0.1))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Theme.Colors.primary.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

struct FeaturedCard: View {
    let listing: Listing
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Image with gradient overlay
                ZStack(alignment: .bottomLeading) {
                    BrrowAsyncImage(url: listing.firstImageUrl ?? "") { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 280, height: 200)
                            .clipped()
                    } placeholder: {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(.systemGray5), Color(.systemGray6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 280, height: 200)
                    }
                    
                    // Gradient overlay
                    LinearGradient(
                        colors: [Color.clear, Color.black.opacity(0.6)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                    
                    // Price badge
                    HStack {
                        Text(listing.isFree ? "FREE" : (listing.listingType == "rental" ? "$\(Int(listing.price))/day" : "$\(Int(listing.price))"))
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        if listing.isPremium {
                            Label("Urgent", systemImage: "bolt.fill")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.orange))
                        }
                    }
                    .padding()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(listing.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    HStack {
                        Image(systemName: "location")
                            .font(.caption)
                        Text("\(0.0 ?? 0, specifier: "%.1f") mi away")
                            .font(.caption)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text(String(format: "%.1f", listing.rating ?? 4.5))
                                .font(.caption.bold())
                        }
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0.1, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

struct CategoryIcon: View {
    let category: MarketplaceCategory
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [category.color.opacity(0.2), category.color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: category.icon)
                        .font(.title2)
                        .foregroundColor(category.color)
                        .scaleEffect(isHovered ? 1.2 : 1.0)
                }
                
                Text(category.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .onHover { hovering in
            withAnimation(.spring()) {
                isHovered = hovering
            }
        }
    }
}

struct FeedCard: View {
    let listing: Listing
    let onLike: () -> Void
    let onShare: () -> Void
    let onTap: () -> Void
    @State private var currentImageIndex = 0
    @State private var isLiked = false
    @State private var showHeartAnimation = false
    
    private var header: some View {
        HStack {
            AsyncImage(url: URL(string: listing.ownerProfilePicture ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color(.systemGray5))
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(listing.ownerUsername ?? "User")
                    .font(.subheadline.weight(.semibold))
                
                Text(formatTime(ISO8601DateFormatter().date(from: listing.createdAt) ?? Date()))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
    
    // Header component
    private var headerView: some View {
        HStack {
            AsyncImage(url: URL(string: listing.ownerProfilePicture ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color(.systemGray5))
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(listing.ownerUsername ?? "User")
                    .font(.subheadline.weight(.semibold))
                
                Text(formatTime(ISO8601DateFormatter().date(from: listing.createdAt) ?? Date()))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
    
    // Image carousel component
    private var imageCarousel: some View {
        TabView(selection: $currentImageIndex) {
            ForEach(0..<imageCount, id: \.self) { index in
                imageView(at: index)
                    .tag(index)
                    .onTapGesture(count: 2) {
                        handleDoubleTap()
                    }
                    .onTapGesture {
                        onTap()
                    }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 400)
        .overlay(imageIndicators, alignment: .bottom)
        .overlay(heartAnimation)
    }
    
    private var imageCount: Int {
        max(1, listing.imageUrls.count)
    }
    
    private func imageView(at index: Int) -> some View {
        BrrowAsyncImage(url: listing.imageUrls[safe: index] ?? listing.firstImageUrl ?? "") { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: 400)
                .clipped()
        } placeholder: {
            Rectangle()
                .fill(Color(.systemGray6))
                .overlay(
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                )
                .frame(height: 400)
        }
    }
    
    private var imageIndicators: some View {
        HStack(spacing: 4) {
            ForEach(0..<imageCount, id: \.self) { index in
                Circle()
                    .fill(currentImageIndex == index ? Color.white : Color.white.opacity(0.5))
                    .frame(width: 6, height: 6)
            }
        }
        .padding(8)
        .background(Capsule().fill(Color.black.opacity(0.3)))
        .padding(.bottom, 16)
    }
    
    private var heartAnimation: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 80))
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.3), radius: 10)
            .scaleEffect(showHeartAnimation ? 1 : 0)
            .opacity(showHeartAnimation ? 1 : 0)
            .animation(.spring(), value: showHeartAnimation)
    }
    
    private func handleDoubleTap() {
        withAnimation(.spring()) {
            isLiked.toggle()
            showHeartAnimation = true
        }
        onLike()
        HapticManager.impact(style: .light)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            showHeartAnimation = false
        }
    }
    
    // Actions bar component
    private var actionsBar: some View {
        HStack(spacing: 20) {
            Button(action: {
                isLiked.toggle()
                onLike()
                HapticManager.impact(style: .light)
            }) {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .font(.title2)
                    .foregroundColor(isLiked ? .red : .primary)
                    .scaleEffect(isLiked ? 1.2 : 1.0)
                    .animation(.spring(), value: isLiked)
            }
            
            Button(action: {}) {
                Image(systemName: "message")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
            
            Button(action: onShare) {
                Image(systemName: "paperplane")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Text(listing.isFree ? "FREE" : (listing.listingType == "rental" ? "$\(Int(listing.price))/day" : "$\(Int(listing.price))"))
                .font(.headline)
                .foregroundColor(listing.isFree ? .green : Theme.Colors.primary)
        }
        .padding()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView
            imageCarousel
            actionsBar
            
            // Details
            VStack(alignment: .leading, spacing: 8) {
                Text(listing.title)
                    .font(.headline)
                
                Text(listing.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Label("\(listing.viewCount ?? 0) views", systemImage: "eye")
                    
                    Spacer()
                    
                    Label("\(0.0 ?? 0, specifier: "%.1f") mi", systemImage: "location")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(Color(.systemBackground))
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct ListingDetailSheet: View {
    let listing: Listing
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Image carousel
                    TabView {
                        ForEach(listing.imageUrls ?? [listing.firstImageUrl ?? ""], id: \.self) { imageUrl in
                            AsyncImage(url: URL(string: imageUrl)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle()
                                    .fill(Color(.systemGray6))
                            }
                            .frame(height: 300)
                            .clipped()
                        }
                    }
                    .tabViewStyle(.page)
                    .frame(height: 300)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Title and price
                        HStack {
                            Text(listing.title)
                                .font(.largeTitle.bold())
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text(listing.isFree ? "FREE" : "$\(Int(listing.price))")
                                    .font(.title.bold())
                                    .foregroundColor(listing.isFree ? .green : Theme.Colors.primary)
                                
                                if !listing.isFree && listing.listingType == "rental" {
                                    Text("per day")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        // Owner info
                        HStack {
                            AsyncImage(url: URL(string: listing.ownerProfilePicture ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(Color(.systemGray5))
                            }
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                            
                            VStack(alignment: .leading) {
                                Text(listing.ownerUsername ?? "User")
                                    .font(.headline)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                    Text(String(format: "%.1f", listing.rating ?? 4.5))
                                        .font(.caption.bold())
                                    Text("(\(listing.reviewCount ?? 0) reviews)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Button("View Profile") {
                                // Navigate to profile
                            }
                            .font(.subheadline)
                            .foregroundColor(Theme.Colors.primary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray6))
                        )
                        
                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                            
                            Text(listing.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        // Location
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Location", systemImage: "location.fill")
                                .font(.headline)
                            
                            Text("\(0.0, specifier: "%.1f") miles away")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // Action buttons
                        HStack(spacing: 16) {
                            Button(action: {}) {
                                Label("Message", systemImage: "message.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                            
                            Button(action: {}) {
                                Label("Request", systemImage: "hand.raised.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: {}) {
                            Image(systemName: "heart")
                        }
                        
                        Button(action: {}) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
        }
    }
}

struct FilterSheetView: View {
    @ObservedObject var viewModel: ModernMarketplaceViewModel
    @Environment(\.dismiss) private var dismiss
    
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
                        
                        ModernMarketplaceRangeSlider(
                            minValue: $viewModel.minPrice,
                            maxValue: $viewModel.maxPrice,
                            range: 0...1000
                        )
                    }
                    
                    Toggle("Include Free Items", isOn: $viewModel.includeFree)
                }
                
                Section("Distance") {
                    Picker("Maximum Distance", selection: $viewModel.maxDistance) {
                        Text("1 mile").tag(1.0)
                        Text("5 miles").tag(5.0)
                        Text("10 miles").tag(10.0)
                        Text("25 miles").tag(25.0)
                        Text("Any distance").tag(100.0)
                    }
                }
                
                Section("Categories") {
                    ForEach(viewModel.allCategories, id: \.self) { category in
                        HStack {
                            Text(category)
                            Spacer()
                            if viewModel.selectedCategories.contains(category) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Theme.Colors.primary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.toggleCategory(category)
                        }
                    }
                }
                
                Section("Condition") {
                    ForEach(["New", "Like New", "Good", "Fair"], id: \.self) { condition in
                        HStack {
                            Text(condition)
                            Spacer()
                            if viewModel.selectedConditions.contains(condition) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Theme.Colors.primary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.toggleCondition(condition)
                        }
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
                        viewModel.applyFilters()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Custom Range Slider
struct ModernMarketplaceRangeSlider: View {
    @Binding var minValue: Double
    @Binding var maxValue: Double
    let range: ClosedRange<Double>
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(height: 4)
                
                // Active range
                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.Colors.primary)
                    .frame(
                        width: CGFloat((maxValue - minValue) / (range.upperBound - range.lowerBound)) * geometry.size.width,
                        height: 4
                    )
                    .offset(x: CGFloat((minValue - range.lowerBound) / (range.upperBound - range.lowerBound)) * geometry.size.width)
                
                // Min thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: 20, height: 20)
                    .shadow(radius: 2)
                    .offset(x: CGFloat((minValue - range.lowerBound) / (range.upperBound - range.lowerBound)) * geometry.size.width - 10)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newValue = Double(value.location.x / geometry.size.width) * (range.upperBound - range.lowerBound) + range.lowerBound
                                minValue = min(max(range.lowerBound, newValue), maxValue - 10)
                            }
                    )
                
                // Max thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: 20, height: 20)
                    .shadow(radius: 2)
                    .offset(x: CGFloat((maxValue - range.lowerBound) / (range.upperBound - range.lowerBound)) * geometry.size.width - 10)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newValue = Double(value.location.x / geometry.size.width) * (range.upperBound - range.lowerBound) + range.lowerBound
                                maxValue = max(min(range.upperBound, newValue), minValue + 10)
                            }
                    )
            }
        }
        .frame(height: 20)
    }
}

// MARK: - View Model
class ModernMarketplaceViewModel: ObservableObject {
    @Published var featuredListings: [Listing] = []
    @Published var feedListings: [Listing] = []
    @Published var categories: [MarketplaceCategory] = []
    @Published var savedItemsCount = 0
    @Published var isLoadingMore = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Filters
    @Published var minPrice: Double = 0
    @Published var maxPrice: Double = 1000
    @Published var includeFree = true
    @Published var maxDistance: Double = 10
    @Published var selectedCategories: Set<String> = []
    @Published var selectedConditions: Set<String> = []
    
    let allCategories = ["Electronics", "Tools", "Sports", "Home", "Fashion", "Books", "Toys", "Other"]
    
    enum SortOption {
        case newest, priceLowest, priceHighest, distance
    }
    
    init() {
        // Initialize with default categories
        categories = [
            MarketplaceCategory(id: "1", name: "Tools", icon: "wrench.fill", color: .orange),
            MarketplaceCategory(id: "2", name: "Electronics", icon: "tv.fill", color: .blue),
            MarketplaceCategory(id: "3", name: "Sports", icon: "sportscourt.fill", color: .green),
            MarketplaceCategory(id: "4", name: "Home", icon: "house.fill", color: .purple),
            MarketplaceCategory(id: "5", name: "Fashion", icon: "tshirt.fill", color: .pink),
            MarketplaceCategory(id: "6", name: "Books", icon: "book.fill", color: .brown),
            MarketplaceCategory(id: "7", name: "Toys", icon: "gift.fill", color: .red),
            MarketplaceCategory(id: "8", name: "More", icon: "ellipsis", color: .gray)
        ]
    }
    
    func loadMarketplaceData() {
        Task {
            do {
                // Fetch featured listings
                featuredListings = try await APIClient.shared.fetchTrendingListings()
                
                // Fetch regular feed
                feedListings = try await APIClient.shared.fetchListings(
                    category: nil,
                    search: nil,
                    location: nil,
                    radius: nil
                )
            } catch {
                print("Error loading marketplace data: \(error)")
            }
        }
    }
    
    func search(query: String) {
        Task {
            do {
                feedListings = try await APIClient.shared.searchListings(
                    query: query,
                    category: selectedCategories.first ?? ""
                )
            } catch {
                print("Error searching: \(error)")
            }
        }
    }
    
    func applyFilter(_ filter: String) {
        // Apply the selected filter
        switch filter {
        case "Trending":
            loadTrending()
        case "Near Me":
            loadNearby()
        case "Free":
            loadFreeItems()
        case "New":
            loadNewItems()
        default:
            loadMarketplaceData()
        }
    }
    
    func selectCategory(_ category: MarketplaceCategory) {
        selectedCategories = [category.name]
        applyFilters()
    }
    
    func sortBy(_ option: SortOption) {
        // Sort the current feed
        switch option {
        case .newest:
            feedListings.sort { $0.createdAt > $1.createdAt }
        case .priceLowest:
            feedListings.sort { $0.price < $1.price }
        case .priceHighest:
            feedListings.sort { $0.price > $1.price }
        case .distance:
            feedListings.sort { _, _ in true }
        }
    }
    
    func toggleLike(_ listing: Listing) {
        // Toggle like status
        Task {
            do {
                try await APIClient.shared.toggleSavedListing(listingId: Int(listing.id) ?? 0)
            } catch {
                print("Error toggling like: \(error)")
            }
        }
    }
    
    func share(_ listing: Listing) {
        // Share listing
        // Implementation depends on share sheet
    }
    
    func refreshMarketplace() async {
        loadMarketplaceData()
    }
    
    // Filter helpers
    func toggleCategory(_ category: String) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }
    
    func toggleCondition(_ condition: String) {
        if selectedConditions.contains(condition) {
            selectedConditions.remove(condition)
        } else {
            selectedConditions.insert(condition)
        }
    }
    
    func resetFilters() {
        minPrice = 0
        maxPrice = 1000
        includeFree = true
        maxDistance = 10
        selectedCategories = []
        selectedConditions = []
    }
    
    func applyFilters() {
        // Apply all filters
        Task {
            // In a real app, send filter parameters to API
            loadMarketplaceData()
        }
    }
    
    private func loadTrending() {
        Task {
            do {
                feedListings = try await APIClient.shared.fetchTrendingListings()
            } catch {
                print("Error loading trending: \(error)")
            }
        }
    }
    
    private func loadNearby() {
        Task {
            do {
                feedListings = try await APIClient.shared.fetchNearbyListings(radius: 5)
            } catch {
                print("Error loading nearby: \(error)")
            }
        }
    }
    
    private func loadFreeItems() {
        Task {
            do {
                // Filter for free items on the client side since API doesn't have onlyFree parameter
                let allListings = try await APIClient.shared.fetchListings(
                    category: nil,
                    search: nil,
                    location: nil,
                    radius: nil
                )
                feedListings = allListings.filter { $0.isFree }
            } catch {
                print("Error loading free items: \(error)")
            }
        }
    }
    
    private func loadNewItems() {
        // Load items created in the last 24 hours
        loadMarketplaceData()
    }
}

// MARK: - Models
struct MarketplaceCategory: Identifiable {
    let id: String
    let name: String
    let icon: String
    let color: Color
}

// MARK: - Extensions
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Skeleton Views
struct FeaturedCardSkeleton: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(width: 280, height: 200)
                .cornerRadius(20)
                .overlay(
                    LinearGradient(
                        colors: [Color.clear, Color.white.opacity(0.4), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .offset(x: isAnimating ? 300 : -300)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
                )
                .clipped()
            
            VStack(alignment: .leading, spacing: 4) {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 20)
                    .cornerRadius(4)
                
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(width: 120, height: 16)
                    .cornerRadius(4)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct CategoryIconSkeleton: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 60, height: 60)
                .overlay(
                    Circle()
                        .fill(Color.white.opacity(0.4))
                        .scaleEffect(isAnimating ? 1.2 : 0.8)
                        .opacity(isAnimating ? 0 : 1)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isAnimating)
                )
            
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(width: 50, height: 12)
                .cornerRadius(4)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct FeedCardSkeleton: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header skeleton
            HStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(width: 120, height: 16)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(width: 80, height: 12)
                        .cornerRadius(4)
                }
                
                Spacer()
            }
            .padding()
            
            // Image skeleton  
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(height: 400)
                .overlay(
                    LinearGradient(
                        colors: [Color.clear, Color.white.opacity(0.4), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .offset(x: isAnimating ? 400 : -400)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false), value: isAnimating)
                )
                .clipped()
            
            // Content skeleton
            VStack(alignment: .leading, spacing: 8) {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 20)
                    .cornerRadius(4)
                
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 16)
                    .cornerRadius(4)
                
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(width: 200, height: 16)
                    .cornerRadius(4)
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Preview
struct ModernMarketplaceView_Previews: PreviewProvider {
    static var previews: some View {
        ModernMarketplaceView()
            .environmentObject(AuthManager.shared)
    }
}