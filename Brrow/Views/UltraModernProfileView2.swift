import SwiftUI
import Charts

struct UltraModernProfileView2: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = ProfileViewModel()
    @State private var selectedTab = 0
    @State private var showEditProfile = false
    @State private var showSettings = false
    @State private var scrollOffset: CGFloat = 0
    @State private var headerScale: CGFloat = 1.0
    @State private var profileImageScale: CGFloat = 1.0
    @State private var animateIn = false
    
    let tabs = ["Activity", "Listings", "Analytics", "Reviews"]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Clean background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                // Main content
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            // Parallax header
                            parallaxHeader
                                .id("header")
                            
                            // Profile content card
                            VStack(spacing: 0) {
                                // User info section
                                userInfoSection
                                    .padding(.top, -50)
                                
                                // Quick stats
                                quickStatsBar
                                    .padding(.top, 20)
                                
                                // Modern tab selector
                                modernTabSelector
                                    .padding(.top, 24)
                                
                                // Tab content
                                tabContent
                                    .padding(.top, 20)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.05), radius: 20, x: 0, y: -10)
                                    .ignoresSafeArea(edges: .bottom)
                            )
                            .offset(y: -20)
                        }
                    }
                    .coordinateSpace(name: "scroll")
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        scrollOffset = value
                        updateHeaderScale()
                    }
                }
                
                // Floating header buttons
                floatingHeaderButtons
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showEditProfile) {
                if let user = authManager.currentUser {
                    EditProfileView(user: user)
                }
            }
            .sheet(isPresented: $showSettings) {
                EnhancedSettingsView()
                    .environmentObject(authManager)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    animateIn = true
                }
            }
        }
    }
    
    // MARK: - Parallax Header
    private var parallaxHeader: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient with parallax
                LinearGradient(
                    colors: [
                        Theme.Colors.primary.opacity(0.8),
                        Theme.Colors.primary.opacity(0.4)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    // Mesh pattern overlay
                    Image(systemName: "hexagon.fill")
                        .font(.system(size: 200))
                        .foregroundColor(.white.opacity(0.03))
                        .rotationEffect(.degrees(15))
                        .offset(x: 100, y: -50)
                )
                .scaleEffect(headerScale)
                .offset(y: scrollOffset > 0 ? -scrollOffset * 0.8 : 0)
                
                // User avatar with dynamic scaling
                VStack {
                    Spacer()
                    
                    ZStack {
                        // Animated ring
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.8), .white.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 130, height: 130)
                            .scaleEffect(profileImageScale)
                            .rotationEffect(.degrees(animateIn ? 360 : 0))
                            .animation(.linear(duration: 20).repeatForever(autoreverses: false), value: animateIn)
                        
                        // Profile image
                        if let user = authManager.currentUser, let imageUrl = user.profilePicture {
                            AsyncImage(url: URL(string: imageUrl)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                            )
                            .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 5)
                        } else {
                            Circle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.white)
                                )
                        }
                        
                        // Verified badge
                        if authManager.currentUser?.verified ?? false {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .background(
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 35, height: 35)
                                )
                                .offset(x: 45, y: 45)
                        }
                    }
                    .scaleEffect(profileImageScale)
                    .offset(y: scrollOffset > 0 ? scrollOffset * 0.3 : 0)
                    
                    Spacer().frame(height: 60)
                }
            }
            .frame(height: 280)
            .background(GeometryReader { geometry in
                Color.clear.preference(
                    key: ScrollOffsetPreferenceKey.self,
                    value: geometry.frame(in: .named("scroll")).minY
                )
            })
        }
        .frame(height: 280)
    }
    
    // MARK: - User Info Section
    private var userInfoSection: some View {
        VStack(spacing: 16) {
            // Name and username
            VStack(spacing: 4) {
                Text(authManager.currentUser?.username ?? "Guest User")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("@\(authManager.currentUser?.username.lowercased() ?? "guest")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .opacity(animateIn ? 1 : 0)
            .offset(y: animateIn ? 0 : 20)
            .animation(.spring(response: 0.6).delay(0.2), value: animateIn)
            
            // Bio or status
            Text("Sharing is caring 🌟 Active in San Francisco Bay Area")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .opacity(animateIn ? 1 : 0)
                .animation(.spring(response: 0.6).delay(0.3), value: animateIn)
            
            // Action buttons
            HStack(spacing: 12) {
                ModernButton(
                    title: "Edit Profile",
                    icon: "square.and.pencil",
                    style: .primary,
                    action: { showEditProfile = true }
                )
                
                ModernButton(
                    title: "Share",
                    icon: "square.and.arrow.up",
                    style: .secondary,
                    action: { }
                )
            }
            .padding(.horizontal, 20)
            .opacity(animateIn ? 1 : 0)
            .animation(.spring(response: 0.6).delay(0.4), value: animateIn)
        }
    }
    
    // MARK: - Quick Stats Bar
    private var quickStatsBar: some View {
        HStack(spacing: 0) {
            QuickStatItem(
                value: "\(viewModel.userListings.count)",
                label: "Listings",
                icon: "cube.box.fill",
                color: .blue
            )
            
            Divider()
                .frame(height: 40)
                .background(Color(.systemGray4))
            
            QuickStatItem(
                value: String(format: "%.1f", viewModel.userRating),
                label: "Rating",
                icon: "star.fill",
                color: .orange
            )
            
            Divider()
                .frame(height: 40)
                .background(Color(.systemGray4))
            
            QuickStatItem(
                value: viewModel.totalEarned > 0 ? "$\(String(format: "%.0f", viewModel.totalEarned))" : "$0",
                label: "Earned",
                icon: "dollarsign.circle.fill",
                color: .green
            )
            
            Divider()
                .frame(height: 40)
                .background(Color(.systemGray4))
            
            QuickStatItem(
                value: "\(viewModel.reviewCount)",
                label: "Reviews",
                icon: "text.bubble.fill",
                color: .purple
            )
        }
        .padding(.vertical, 20)
        .padding(.horizontal)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal, 20)
        .opacity(animateIn ? 1 : 0)
        .scaleEffect(animateIn ? 1 : 0.9)
        .animation(.spring(response: 0.6).delay(0.5), value: animateIn)
    }
    
    // MARK: - Modern Tab Selector
    private var modernTabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tabs.indices, id: \.self) { index in
                    TabPill(
                        title: tabs[index],
                        isSelected: selectedTab == index,
                        action: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedTab = index
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Tab Content
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case 0:
            activityContent
        case 1:
            listingsContent
        case 2:
            analyticsContent
        case 3:
            reviewsContent
        default:
            EmptyView()
        }
    }
    
    private var activityContent: some View {
        VStack(spacing: 16) {
            if viewModel.activities.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text("No Recent Activity")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Your recent activities will appear here")
                        .font(.subheadline)
                        .foregroundColor(.secondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else {
                ForEach(viewModel.activities) { activity in
                    ProfileActivityCard(
                        icon: activity.icon,
                        title: activity.title,
                        subtitle: activity.subtitle,
                        time: activity.timeAgo,
                        color: activity.color
                    )
                    .opacity(animateIn ? 1 : 0)
                    .offset(x: animateIn ? 0 : -50)
                    .animation(.spring(response: 0.5).delay(Double(viewModel.activities.firstIndex(where: { $0.id == activity.id }) ?? 0) * 0.1), value: animateIn)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 100)
    }
    
    private var listingsContent: some View {
        VStack {
            if viewModel.userListings.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "cube.box")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text("No Listings Yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Start listing items to share with your community")
                        .font(.subheadline)
                        .foregroundColor(.secondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    NavigationLink(destination: ModernCreateListingView()) {
                        Label("Create Your First Listing", systemImage: "plus.circle.fill")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Theme.Colors.primary)
                            )
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(viewModel.userListings) { listing in
                        ModernListingGridCard(listing: listing)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 100)
    }
    
    private var analyticsContent: some View {
        VStack(spacing: 20) {
            if viewModel.monthlyEarnings == 0 && viewModel.totalViews == 0 {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text("No Analytics Data")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Analytics will appear once you start listing and renting items")
                        .font(.subheadline)
                        .foregroundColor(.secondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else {
                // Performance card
                ModernAnalyticsCard(
                    title: "This Month",
                    value: "$\(String(format: "%.0f", viewModel.monthlyEarnings))",
                    change: viewModel.monthlyChange,
                    chartData: generateMockChartData()
                )
                
                // Insights grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ProfileInsightCard(
                        title: "Views",
                        value: viewModel.totalViews > 999 ? "\(String(format: "%.1fK", Double(viewModel.totalViews) / 1000))" : "\(viewModel.totalViews)",
                        icon: "eye.fill",
                        trend: viewModel.viewsTrend
                    )
                    ProfileInsightCard(
                        title: "Saves",
                        value: "\(viewModel.totalSaves)",
                        icon: "bookmark.fill",
                        trend: viewModel.savesTrend
                    )
                    ProfileInsightCard(
                        title: "Messages",
                        value: "\(viewModel.totalMessages)",
                        icon: "message.fill",
                        trend: viewModel.messagesTrend
                    )
                    ProfileInsightCard(
                        title: "Rentals",
                        value: "\(viewModel.totalRentals)",
                        icon: "arrow.triangle.2.circlepath",
                        trend: viewModel.rentalsTrend
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 100)
    }
    
    private var reviewsContent: some View {
        VStack(spacing: 16) {
            if viewModel.reviews.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "star")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text("No Reviews Yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Reviews from renters will appear here")
                        .font(.subheadline)
                        .foregroundColor(.secondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else {
                // Rating summary
                RatingSummaryCard(
                    rating: viewModel.userRating,
                    totalReviews: viewModel.reviewCount,
                    ratingDistribution: viewModel.ratingDistribution
                )
                
                // Individual reviews
                ForEach(viewModel.reviews) { review in
                    UltraModernReviewCard(
                        reviewerName: review.reviewerName,
                        rating: review.rating,
                        comment: review.comment,
                        date: review.date
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 100)
    }
    
    // MARK: - Floating Header Buttons
    private var floatingHeaderButtons: some View {
        VStack {
            HStack {
                Button(action: { showSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.3))
                                .blur(radius: 0.5)
                        )
                }
                
                Spacer()
                
                Button(action: { }) {
                    Image(systemName: "bell.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.3))
                                .blur(radius: 0.5)
                        )
                        .overlay(
                            Circle()
                                .fill(Color.red)
                                .frame(width: 10, height: 10)
                                .offset(x: 12, y: -12)
                        )
                }
            }
            .padding(.horizontal)
            .padding(.top, 50)
            
            Spacer()
        }
        .opacity(scrollOffset < -100 ? 0 : 1)
        .animation(.easeInOut, value: scrollOffset)
    }
    
    private func updateHeaderScale() {
        let offset = scrollOffset
        if offset > 0 {
            headerScale = 1 + (offset / 500)
            profileImageScale = 1 + (offset / 800)
        } else {
            headerScale = 1
            profileImageScale = 1 + (offset / 1000)
        }
    }
    
    private func generateMockChartData() -> [ChartDataPoint] {
        // Return actual analytics data from viewModel if available
        if !viewModel.analyticsData.isEmpty {
            return viewModel.analyticsData
        }
        
        // Return empty data for clean state
        return (0..<7).map { day in
            ChartDataPoint(
                day: day,
                value: 0
            )
        }
    }
}

// MARK: - Supporting Views

struct ModernButton: View {
    let title: String
    let icon: String
    let style: ButtonStyle
    let action: () -> Void
    
    enum ButtonStyle {
        case primary, secondary
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline.bold())
                Text(title)
                    .font(.subheadline.bold())
            }
            .foregroundColor(style == .primary ? .white : .primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(style == .primary ? Theme.Colors.primary : Color(.systemGray6))
            )
        }
    }
}

struct QuickStatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Text(value)
                    .font(.headline.bold())
                    .foregroundColor(.primary)
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct TabPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? Theme.Colors.primary : Color(.systemGray6))
                )
        }
    }
}

struct ProfileActivityCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let time: String
    let color: Color
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 48, height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.1))
                )
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Time
            Text(time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onTapGesture {
            withAnimation(.spring(response: 0.3)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3)) {
                    isPressed = false
                }
            }
        }
    }
}

struct ModernListingGridCard: View {
    let listing: Listing
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Image
            if let imageUrl = listing.imageUrls.first {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay(
                            ProgressView()
                                .tint(Theme.Colors.primary)
                        )
                }
                .frame(height: 140)
                .clipped()
                .overlay(
                    // Status badge
                    VStack {
                        HStack {
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
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(8)
                )
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(listing.title)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
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
                        Image(systemName: "eye")
                            .font(.caption2)
                        Text("\(listing.views)")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding(12)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(
                    color: isHovered ? Theme.Colors.primary.opacity(0.2) : .black.opacity(0.05),
                    radius: isHovered ? 15 : 8,
                    x: 0,
                    y: isHovered ? 8 : 4
                )
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onTapGesture {
            withAnimation(.spring(response: 0.3)) {
                isHovered = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3)) {
                    isHovered = false
                }
            }
        }
    }
}

struct ModernAnalyticsCard: View {
    let title: String
    let value: String
    let change: String
    let chartData: [ChartDataPoint]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(alignment: .lastTextBaseline, spacing: 8) {
                        Text(value)
                            .font(.largeTitle.bold())
                            .foregroundColor(.primary)
                        
                        Label(change, systemImage: change.contains("+") ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption.bold())
                            .foregroundColor(change.contains("+") ? .green : .red)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundColor(Theme.Colors.primary)
            }
            
            // Mini chart
            Chart(chartData) { point in
                LineMark(
                    x: .value("Day", point.day),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(Theme.Colors.primary)
                .interpolationMethod(.catmullRom)
                
                AreaMark(
                    x: .value("Day", point.day),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.Colors.primary.opacity(0.3), Theme.Colors.primary.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
            .frame(height: 100)
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray6))
        )
    }
}

struct ProfileInsightCard: View {
    let title: String
    let value: String
    let icon: String
    let trend: Trend
    
    enum Trend {
        case up, down, neutral
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(Theme.Colors.primary)
                
                Spacer()
                
                Image(systemName: trend == .up ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption.bold())
                    .foregroundColor(trend == .up ? .green : .red)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

struct RatingSummaryCard: View {
    let rating: Double
    let totalReviews: Int
    let ratingDistribution: [Double]
    
    var body: some View {
        HStack(spacing: 20) {
            // Overall rating
            VStack(spacing: 8) {
                Text(String(format: "%.1f", rating))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                HStack(spacing: 2) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < Int(rating.rounded()) ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Text("\(totalReviews) reviews")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .frame(height: 80)
            
            // Rating bars
            VStack(alignment: .leading, spacing: 8) {
                ForEach((1...5).reversed(), id: \.self) { rating in
                    HStack(spacing: 8) {
                        Text("\(rating)")
                            .font(.caption.monospaced())
                            .foregroundColor(.secondary)
                            .frame(width: 15)
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color(.systemGray5))
                                    .frame(height: 6)
                                
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.orange)
                                    .frame(
                                        width: geometry.size.width * (rating - 1 < ratingDistribution.count ? ratingDistribution[rating - 1] : 0),
                                        height: 6
                                    )
                            }
                        }
                        .frame(height: 6)
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray6))
        )
    }
}

struct UltraModernReviewCard: View {
    let reviewerName: String
    let rating: Int
    let comment: String
    let date: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Reviewer avatar
                Circle()
                    .fill(Theme.Colors.primary.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(reviewerName.prefix(1))
                            .font(.headline)
                            .foregroundColor(Theme.Colors.primary)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(reviewerName)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 2) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < rating ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                Spacer()
                
                Text(date, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(comment)
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let day: Int
    let value: Double
}

// Scroll offset preference key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// Preview
struct UltraModernProfileView2_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Empty state preview
            UltraModernProfileView2()
                .environmentObject(AuthManager.shared)
                .previewDisplayName("Empty State")
            
            // With data preview (if needed for testing)
        }
    }
}