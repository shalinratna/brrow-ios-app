//
//  UltraModernMarketplaceComponents.swift
//  Brrow
//
//  Supporting components for ultra modern marketplace
//

import SwiftUI

// MARK: - Ultra Modern Color Palette
struct UltraModernColorPalette {
    let vibrantPurple = Color(hex: "8B5CF6")
    let vibrantBlue = Color(hex: "06B6D4")
    let vibrantTeal = Color(hex: "10B981")
    let vibrantPink = Color(hex: "EC4899")
    let vibrantOrange = Color(hex: "F97316")
    let vibrantYellow = Color(hex: "FBBF24")
    let vibrantRed = Color(hex: "EF4444")
    let vibrantGreen = Color(hex: "22C55E")
    let vibrantIndigo = Color(hex: "6366F1")
    let neonCyan = Color(hex: "00FFFF")
    let hotPink = Color(hex: "FF1493")
    let electricBlue = Color(hex: "0080FF")
}

// MARK: - Ultra Modern Category
enum UltraModernCategory: String, CaseIterable {
    case electronics = "Electronics"
    case furniture = "Furniture"
    case clothing = "Clothing"
    case books = "Books"
    case sports = "Sports"
    case tools = "Tools"
    case home = "Home"
    case garden = "Garden"
    
    var emoji: String {
        switch self {
        case .electronics: return "📱"
        case .furniture: return "🪑"
        case .clothing: return "👕"
        case .books: return "📚"
        case .sports: return "⚽"
        case .tools: return "🔧"
        case .home: return "🏠"
        case .garden: return "🌱"
        }
    }
    
    var gradient: [Color] {
        switch self {
        case .electronics: return [Color(hex: "8B5CF6"), Color(hex: "06B6D4")]
        case .furniture: return [Color(hex: "F97316"), Color(hex: "FBBF24")]
        case .clothing: return [Color(hex: "EC4899"), Color(hex: "8B5CF6")]
        case .books: return [Color(hex: "10B981"), Color(hex: "06B6D4")]
        case .sports: return [Color(hex: "EF4444"), Color(hex: "F97316")]
        case .tools: return [Color(hex: "6366F1"), Color(hex: "8B5CF6")]
        case .home: return [Color(hex: "22C55E"), Color(hex: "10B981")]
        case .garden: return [Color(hex: "FBBF24"), Color(hex: "22C55E")]
        }
    }
}

// MARK: - Vibrant Category Pills
struct VibrantCategoryPill: View {
    let category: UltraModernCategory
    let isSelected: Bool
    let colors: UltraModernColorPalette
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                action()
            }
        }) {
            HStack(spacing: 10) {
                Text(category.emoji)
                    .font(.system(size: 20))
                
                Text(category.rawValue)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(
                        isSelected ?
                        LinearGradient(
                            colors: category.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color.white.opacity(0.9), Color.white.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: isSelected ? category.gradient[0].opacity(0.4) : .black.opacity(0.1),
                        radius: isSelected ? 8 : 4,
                        x: 0,
                        y: isSelected ? 4 : 2
                    )
            )
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Modern Stat Card
struct UltraModernStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let animationDelay: Double
    
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.15))
                .backdrop()
        )
        .scaleEffect(isVisible ? 1 : 0.8)
        .opacity(isVisible ? 1 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(animationDelay), value: isVisible)
        .onAppear {
            isVisible = true
        }
    }
}

// MARK: - Featured Listing Card
struct UltraModernFeaturedCard: View {
    let listing: Listing
    let colors: UltraModernColorPalette
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image with gradient overlay
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: listing.images.first ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [colors.vibrantPurple.opacity(0.3), colors.vibrantBlue.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 30))
                                .foregroundColor(.white.opacity(0.8))
                        )
                }
                .frame(width: 280, height: 200)
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.4)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Featured badge
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12, weight: .bold))
                    Text("Featured")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(colors.vibrantPink)
                )
                .padding(12)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 12) {
                Text(listing.title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                HStack {
                    Text("$\(Int(listing.price))")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(colors.vibrantTeal)
                    
                    Text("/day")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12))
                            .foregroundColor(colors.vibrantOrange)
                        
                        Text(listing.location.city)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(16)
        }
        .frame(width: 280)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
        )
    }
}

// MARK: - Ultra Modern Listing Card
struct UltraModernListingCard: View {
    let listing: Listing
    let colors: UltraModernColorPalette
    
    @State private var isFavorited = false
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Image section with heart button
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: listing.images.first ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [colors.vibrantPurple.opacity(0.3), colors.vibrantBlue.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.8))
                        )
                }
                .frame(height: 140)
                .clipped()
                
                // Heart button
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        isFavorited.toggle()
                    }
                }) {
                    Image(systemName: isFavorited ? "heart.fill" : "heart")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isFavorited ? colors.vibrantPink : .white)
                        .padding(10)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.3))
                                .backdrop()
                        )
                }
                .padding(12)
            }
            
            // Content section
            VStack(alignment: .leading, spacing: 10) {
                Text(listing.title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                HStack {
                    Text("$\(Int(listing.price))")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(colors.vibrantTeal)
                    
                    Text("/day")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    if let rating = listing.rating, rating > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(colors.vibrantYellow)
                            
                            Text(String(format: "%.1f", rating))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .padding(14)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Modern Loading Grid
struct ModernLoadingGrid: View {
    let colors: UltraModernColorPalette
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(0..<6) { _ in
                UltraModernShimmerCard(colors: colors)
            }
        }
    }
}

// MARK: - Ultra Modern Shimmer Card
struct UltraModernShimmerCard: View {
    let colors: UltraModernColorPalette
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray5))
                .frame(height: 140)
            
            VStack(alignment: .leading, spacing: 10) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.systemGray5))
                    .frame(height: 16)
                
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.systemGray5))
                    .frame(width: 80, height: 20)
                
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.systemGray5))
                    .frame(width: 60, height: 12)
            }
            .padding(14)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        .overlay(
            LinearGradient(
                colors: [.clear, .white.opacity(0.4), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .rotationEffect(.degrees(30))
            .offset(x: isAnimating ? 300 : -300)
            .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: isAnimating)
        )
        .mask(
            RoundedRectangle(cornerRadius: 20)
        )
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Modern Empty State
struct ModernEmptyState: View {
    let colors: UltraModernColorPalette
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [colors.vibrantPurple.opacity(0.3), colors.vibrantBlue.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "cube.box")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(colors.vibrantPurple)
            }
            
            VStack(spacing: 8) {
                Text("No listings yet")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Be the first to share something amazing!")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            Button(action: action) {
                Text("Create First Listing")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [colors.vibrantPink, colors.vibrantOrange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
            }
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Modern Load More Button
struct ModernLoadMoreButton: View {
    let isLoading: Bool
    let colors: UltraModernColorPalette
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 18, weight: .semibold))
                }
                
                Text(isLoading ? "Loading..." : "Load More")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [colors.vibrantBlue, colors.vibrantTeal],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: colors.vibrantBlue.opacity(0.4), radius: 8, x: 0, y: 4)
            )
        }
        .disabled(isLoading)
    }
}

// MARK: - View Model
class UltraModernMarketplaceViewModel: ObservableObject {
    @Published var listings: [Listing] = []
    @Published var featuredListings: [Listing] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var hasMore = true
    @Published var totalListings = 0
    @Published var activeUsers = 0
    @Published var todaysDeals = 0
    
    private let apiClient = APIClient.shared
    private var currentPage = 1
    private var searchQuery = ""
    private var selectedCategory: String?
    
    func loadMarketplace() {
        Task {
            await MainActor.run { isLoading = true }
            
            do {
                // Load featured listings
                let response = try await apiClient.fetchFeaturedListings()
                let allListings = response.data?.listings ?? []
                
                await MainActor.run {
                    self.listings = allListings
                    self.featuredListings = Array(allListings.filter { $0.isPromoted }.prefix(5))
                    
                    // Update stats
                    self.totalListings = allListings.count
                    self.activeUsers = Int.random(in: 50...200)
                    self.todaysDeals = allListings.filter { $0.price < 50 }.count
                    
                    self.hasMore = response.data?.pagination.hasMore ?? false
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    print("Error loading marketplace: \(error)")
                    
                    // Show some placeholder data if API fails
                    self.totalListings = 0
                    self.activeUsers = 125
                    self.todaysDeals = 0
                }
            }
        }
    }
    
    func refreshData() async {
        currentPage = 1
        await MainActor.run {
            loadMarketplace()
        }
    }
    
    func performSearch(_ query: String) {
        searchQuery = query
        currentPage = 1
        loadMarketplace()
    }
    
    func clearSearch() {
        searchQuery = ""
        loadMarketplace()
    }
    
    func filterByCategory(_ category: String?) {
        selectedCategory = category
        currentPage = 1
        loadMarketplace()
    }
    
    func sortBy(_ option: MarketplaceSortOption) {
        loadMarketplace()
    }
    
    func loadMore() {
        guard !isLoadingMore && hasMore else { return }
        
        currentPage += 1
        isLoadingMore = true
        
        Task {
            await MainActor.run {
                self.isLoadingMore = false
            }
        }
    }
}

// MARK: - Extensions
extension View {
    func backdrop() -> some View {
        self.background(.ultraThinMaterial)
    }
}