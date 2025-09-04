import SwiftUI

struct LiquidMarketplaceView: View {
    @StateObject private var viewModel = InfiniteMarketplaceViewModel()
    @State private var searchText = ""
    @State private var showFilters = false
    @State private var selectedCategory: String? = nil
    @State private var liquidAnimation = false
    @State private var waveOffset: CGFloat = 0
    @State private var shimmerAnimation = false
    @FocusState private var searchFocused: Bool
    
    let categories = [
        ("Electronics", "tv", Color.blue),
        ("Fashion", "tshirt", Color.pink),
        ("Home", "house", Color.green),
        ("Sports", "sportscourt", Color.orange),
        ("Books", "book", Color.purple),
        ("Tools", "hammer", Color.red)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Animated liquid background
                liquidBackground
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Animated header
                        animatedHeader
                            .padding(.bottom, 20)
                        
                        // Floating search bar
                        floatingSearchBar
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        
                        // Liquid category selector
                        liquidCategorySelector
                            .padding(.bottom, 20)
                        
                        // Featured section with shimmer
                        if !viewModel.featuredItems.isEmpty {
                            featuredSection
                                .padding(.bottom, 30)
                        }
                        
                        // Main content grid
                        mainContentGrid
                            .padding(.horizontal)
                            .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                startAnimations()
                viewModel.loadInitialContent()
            }
        }
    }
    
    // MARK: - Liquid Background
    private var liquidBackground: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemGray6),
                    Color(.systemGray5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated wave overlay
            GeometryReader { geometry in
                Path { path in
                    path.move(to: CGPoint(x: 0, y: geometry.size.height * 0.3))
                    
                    for x in stride(from: 0, through: geometry.size.width, by: 1) {
                        let relativeX = x / geometry.size.width
                        let y = sin(relativeX * .pi * 2 + waveOffset) * 20 + geometry.size.height * 0.3
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    
                    path.addLine(to: CGPoint(x: geometry.size.width, y: 0))
                    path.addLine(to: CGPoint(x: 0, y: 0))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [
                            Theme.Colors.primary.opacity(0.1),
                            Theme.Colors.primary.opacity(0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .animation(.linear(duration: 3).repeatForever(autoreverses: false), value: waveOffset)
            }
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Animated Header
    private var animatedHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Discover")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .overlay(
                    LinearGradient(
                        colors: [Theme.Colors.primary, Theme.Colors.primary.opacity(0.6)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .mask(
                        Text("Discover")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                    )
                    .opacity(shimmerAnimation ? 1 : 0)
                    .offset(x: shimmerAnimation ? 200 : -200)
                    .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: shimmerAnimation)
                )
            
            Text("Find amazing items near you")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top, 60)
    }
    
    // MARK: - Floating Search Bar
    private var floatingSearchBar: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.title3)
                
                TextField("Search items...", text: $searchText)
                    .focused($searchFocused)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
            )
            
            // Filter button with badge
            Button(action: { showFilters = true }) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title3)
                        .foregroundColor(Theme.Colors.primary)
                        .frame(width: 50, height: 50)
                        .background(
                            Circle()
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        )
                    
                    if viewModel.activeFiltersCount > 0 {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Text("\(viewModel.activeFiltersCount)")
                                    .font(.caption2.bold())
                                    .foregroundColor(.white)
                            )
                            .offset(x: 5, y: -5)
                    }
                }
            }
            .scaleEffect(liquidAnimation ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: liquidAnimation)
        }
    }
    
    // MARK: - Liquid Category Selector
    private var liquidCategorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(categories, id: \.0) { category in
                    LiquidCategoryCard(
                        title: category.0,
                        icon: category.1,
                        color: category.2,
                        isSelected: selectedCategory == category.0
                    ) {
                        withAnimation(.spring(response: 0.4)) {
                            selectedCategory = selectedCategory == category.0 ? nil : category.0
                        }
                        HapticManager.impact(style: .light)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Featured Section
    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Featured")
                    .font(.title2.bold())
                
                Spacer()
                
                Button("See all") {
                    // Action
                }
                .font(.subheadline)
                .foregroundColor(Theme.Colors.primary)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(viewModel.featuredItems.prefix(5).enumerated()), id: \.offset) { index, item in
                        if let listing = item as? Listing {
                            FuturisticListingCard(listing: listing, delay: Double(index) * 0.1)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Main Content Grid
    private var mainContentGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(Array(viewModel.items.enumerated()), id: \.offset) { index, item in
                if let listing = item as? Listing {
                    NavigationLink(destination: ListingDetailView(listing: listing)) {
                        AnimatedListingCard(listing: listing, index: index)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private func startAnimations() {
        liquidAnimation = true
        shimmerAnimation = true
        
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            waveOffset = .pi * 2
        }
    }
}

// MARK: - Supporting Views

struct LiquidCategoryCard: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    @State private var bubbleAnimation = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    // Liquid bubble background
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    color.opacity(isSelected ? 0.8 : 0.2),
                                    color.opacity(isSelected ? 0.4 : 0.1)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 40
                            )
                        )
                        .frame(width: 70, height: 70)
                        .scaleEffect(bubbleAnimation ? 1.1 : 1.0)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? .white : color)
                }
                
                Text(title)
                    .font(.caption.bold())
                    .foregroundColor(.primary)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                bubbleAnimation = true
            }
        }
    }
}

struct FuturisticListingCard: View {
    let listing: Listing
    let delay: Double
    @State private var appear = false
    @State private var hover = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image with parallax effect
            if let imageUrl = listing.images.first {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            ProgressView()
                                .tint(Theme.Colors.primary)
                        )
                }
                .frame(width: 220, height: 160)
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [Color.clear, Color.black.opacity(0.3)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(listing.title)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack {
                    Text("$\(Int(listing.price))")
                        .font(.title3.bold())
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
                        Text(String(format: "%.1f", listing.rating ?? 0))
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
        }
        .frame(width: 220)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(
                    color: hover ? Theme.Colors.primary.opacity(0.3) : .black.opacity(0.1),
                    radius: hover ? 20 : 10,
                    x: 0,
                    y: hover ? 15 : 5
                )
        )
        .scaleEffect(appear ? (hover ? 1.05 : 1.0) : 0.8)
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.6).delay(delay)) {
                appear = true
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.3)) {
                hover = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3)) {
                    hover = false
                }
            }
        }
    }
}

struct AnimatedListingCard: View {
    let listing: Listing
    let index: Int
    @State private var appear = false
    @State private var ripple = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Image
            if let imageUrl = listing.images.first {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ShimmerView()
                }
                .frame(height: 180)
                .clipped()
                .overlay(
                    // Ripple effect overlay
                    Circle()
                        .stroke(Theme.Colors.primary, lineWidth: 2)
                        .scaleEffect(ripple ? 2 : 0)
                        .opacity(ripple ? 0 : 1)
                        .animation(.easeOut(duration: 0.6), value: ripple)
                )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(listing.title)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                
                HStack {
                    Text("$\(Int(listing.price))")
                        .font(.headline)
                        .foregroundColor(Theme.Colors.primary)
                    
                    Spacer()
                    
                    HStack(spacing: 2) {
                        Image(systemName: "location")
                            .font(.caption2)
                        Text(listing.location.city)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 5)
        )
        .scaleEffect(appear ? 1 : 0.8)
        .opacity(appear ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5).delay(Double(index % 4) * 0.1)) {
                appear = true
            }
        }
        .onTapGesture {
            ripple = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                ripple = false
            }
        }
    }
}

struct ShimmerView: View {
    @State private var shimmer = false
    
    var body: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.3),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: shimmer ? 200 : -200)
                    .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: shimmer)
            )
            .onAppear {
                shimmer = true
            }
    }
}

// Preview
struct LiquidMarketplaceView_Previews: PreviewProvider {
    static var previews: some View {
        LiquidMarketplaceView()
    }
}