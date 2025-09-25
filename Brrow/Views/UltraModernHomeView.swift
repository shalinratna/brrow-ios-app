//
//  UltraModernHomeView.swift
//  Brrow
//
//  Ultra modern home screen with amazing animations and vibrant colors
//

import SwiftUI

struct UltraModernHomeView: View {
    @StateObject private var viewModel = UltraModernHomeViewModel()
    @State private var animateGradient = false
    @State private var pulseAnimation = false
    @State private var rotationAngle: Double = 0
    @State private var cardScale: CGFloat = 1.0
    @State private var showingNotifications = false
    @State private var selectedQuickAction: QuickActionType? = nil
    
    // Vibrant colors
    private let colors = UltraModernColors()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Animated gradient background
                animatedBackground
                .onAppear {
                    print("🚀 UltraModernHomeView loaded!")
                }
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Futuristic Header
                        futuristicHeader
                            .padding(.top, 20)
                        
                        // Welcome Section with animation
                        animatedWelcomeSection
                            .padding(.horizontal, 20)
                            .padding(.top, 30)
                        
                        // Quick Actions Grid
                        quickActionsGrid
                            .padding(.horizontal, 20)
                            .padding(.top, 30)
                        
                        // Live Stats Dashboard
                        liveStatsDashboard
                            .padding(.horizontal, 20)
                            .padding(.top, 30)
                        
                        // Trending Items Carousel
                        trendingItemsSection
                            .padding(.top, 30)
                        
                        // Activity Feed
                        activityFeedSection
                            .padding(.horizontal, 20)
                            .padding(.top, 30)
                        
                        // Promotional Banner
                        promotionalBanner
                            .padding(.horizontal, 20)
                            .padding(.top, 30)
                            .padding(.bottom, 100)
                    }
                }
                .refreshable {
                    await viewModel.refreshData()
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                startAllAnimations()
                viewModel.loadHomeData()
            }
            .sheet(isPresented: $showingNotifications) {
                NotificationsView()
            }
            .sheet(item: $selectedQuickAction) { action in
                getViewForAction(action)
            }
        }
    }
    
    // MARK: - Animated Background
    private var animatedBackground: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: animateGradient ? 
                    [colors.neonPurple, colors.electricBlue, colors.hotPink] :
                    [colors.electricBlue, colors.neonGreen, colors.neonPurple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: animateGradient)
            
            // Animated circles
            GeometryReader { geometry in
                ForEach(0..<5) { index in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    colors.randomColor().opacity(0.3),
                                    colors.randomColor().opacity(0.1)
                                ],
                                center: .center,
                                startRadius: 50,
                                endRadius: 150
                            )
                        )
                        .frame(width: 200, height: 200)
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .animation(
                            .easeInOut(duration: Double.random(in: 10...20))
                                .repeatForever(autoreverses: true),
                            value: animateGradient
                        )
                        .opacity(animateGradient ? 0.8 : 0.3)
                }
            }
        }
    }
    
    // MARK: - Futuristic Header
    private var futuristicHeader: some View {
        HStack {
            // Logo with rotation
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [colors.neonCyan, colors.hotPink, colors.electricBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(rotationAngle))
                    .animation(.linear(duration: 10).repeatForever(autoreverses: false), value: rotationAngle)
                
                Image(systemName: "cube.transparent.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [colors.neonPurple, colors.electricBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            Spacer()
            
            // Notification button with badge
            Button(action: { showingNotifications = true }) {
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "bell.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                        )
                    
                    if viewModel.unreadNotifications > 0 {
                        Circle()
                            .fill(colors.hotPink)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Text("\(viewModel.unreadNotifications)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .offset(x: -5, y: 5)
                            .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulseAnimation)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Animated Welcome Section
    private var animatedWelcomeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.greeting)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.9)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
            
            Text("Ready to discover amazing deals?")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(animateGradient ? 1 : 0.8)
        .animation(.easeInOut(duration: 2), value: animateGradient)
    }
    
    // MARK: - Quick Actions Grid
    private var quickActionsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(QuickActionType.allCases, id: \.self) { action in
                UltraQuickActionCard(
                    action: action,
                    colors: colors,
                    scale: cardScale
                ) {
                    selectedQuickAction = action
                }
                .scaleEffect(cardScale)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: cardScale)
            }
        }
    }
    
    // MARK: - Live Stats Dashboard
    private var liveStatsDashboard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("📊 Live Stats")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
            
            HStack(spacing: 12) {
                LiveStatCard(
                    title: "Active Now",
                    value: "\(viewModel.activeUsers)",
                    icon: "person.2.fill",
                    color: colors.neonGreen,
                    isAnimating: pulseAnimation
                )
                
                LiveStatCard(
                    title: "New Today",
                    value: "\(viewModel.newListingsToday)",
                    icon: "sparkles",
                    color: colors.hotPink,
                    isAnimating: pulseAnimation
                )
                
                LiveStatCard(
                    title: "Saved",
                    value: "$\(viewModel.totalSaved)",
                    icon: "dollarsign.circle.fill",
                    color: colors.electricBlue,
                    isAnimating: pulseAnimation
                )
            }
        }
    }
    
    // MARK: - Trending Items Section
    private var trendingItemsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("🔥 Trending Now")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                
                Spacer()
                
                NavigationLink(destination: UltraModernMarketplaceView3()) {
                    Text("See all")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(colors.neonCyan)
                }
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.trendingItems) { item in
                        HomeTrendingCard(item: item, colors: colors)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Activity Feed Section
    private var activityFeedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("⚡ Recent Activity")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
            
            VStack(spacing: 12) {
                ForEach(viewModel.recentActivities) { activity in
                    HomeActivityCard(activity: activity, colors: colors)
                }
            }
        }
    }
    
    // MARK: - Promotional Banner
    private var promotionalBanner: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [colors.neonPurple, colors.hotPink, colors.electricBlue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 180)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
            
            HStack {
                VStack(alignment: .leading, spacing: 12) {
                    Text("🎉 Special Offer")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text("List 3 items, get 1 free!")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Button(action: {}) {
                        Text("Learn More")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(colors.neonPurple)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(Color.white)
                            )
                    }
                }
                
                Spacer()
                
                Image(systemName: "gift.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white.opacity(0.3))
                    .rotationEffect(.degrees(15))
            }
            .padding(24)
        }
        .shadow(color: colors.neonPurple.opacity(0.5), radius: 20, x: 0, y: 10)
    }
    
    // MARK: - Helper Functions
    private func startAllAnimations() {
        animateGradient = true
        pulseAnimation = true
        rotationAngle = 360
        
        // Card entrance animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            cardScale = 1.05
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                cardScale = 1.0
            }
        }
    }
    
    private func getViewForAction(_ action: QuickActionType) -> some View {
        Group {
            switch action {
            case .browse:
                UltraModernMarketplaceView3()
            case .list:
                ModernCreateListingView()
            case .search:
                SearchView()
            case .deals:
                Text("Deals View") // Placeholder
            }
        }
    }
}

// MARK: - Supporting Types

enum QuickActionType: String, CaseIterable, Identifiable {
    case browse, list, search, deals
    
    var id: String { self.rawValue }
    
    var title: String {
        switch self {
        case .browse: return "Browse"
        case .list: return "List Item"
        case .search: return "Search"
        case .deals: return "Hot Deals"
        }
    }
    
    var icon: String {
        switch self {
        case .browse: return "square.grid.2x2.fill"
        case .list: return "plus.circle.fill"
        case .search: return "magnifyingglass"
        case .deals: return "flame.fill"
        }
    }
    
    var gradient: [Color] {
        let colors = UltraModernColors()
        switch self {
        case .browse: return [colors.electricBlue, colors.neonCyan]
        case .list: return [colors.hotPink, colors.neonPurple]
        case .search: return [colors.neonGreen, colors.electricBlue]
        case .deals: return [colors.neonOrange, colors.hotPink]
        }
    }
}

// MARK: - Quick Action Card
struct UltraQuickActionCard: View {
    let action: QuickActionType
    let colors: UltraModernColors
    let scale: CGFloat
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: action.gradient.map { $0.opacity(0.3) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: action.icon)
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: action.gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                Text(action.title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.1))
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: action.gradient.map { $0.opacity(0.5) },
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Live Stat Card
struct LiveStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let isAnimating: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(color)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isAnimating)
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(color.opacity(0.5), lineWidth: 1)
                )
        )
    }
}

// MARK: - Trending Item Card
struct HomeTrendingCard: View {
    let item: HomeTrendingItem
    let colors: UltraModernColors
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            AsyncImage(url: URL(string: item.imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [colors.electricBlue.opacity(0.3), colors.neonPurple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.5))
                    )
            }
            .frame(width: 200, height: 150)
            .clipped()
            
            VStack(alignment: .leading, spacing: 8) {
                Text(item.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                HStack {
                    Text("$\(item.price)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(colors.neonGreen)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "eye.fill")
                            .font(.system(size: 12))
                        Text("\(item.views)")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(12)
        }
        .frame(width: 200)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Activity Card
struct HomeActivityCard: View {
    let activity: Activity
    let colors: UltraModernColors
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [colors.randomColor().opacity(0.6), colors.randomColor().opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: activity.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(activity.subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Text(activity.time)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
        )
    }
}

// MARK: - Ultra Modern Colors
struct UltraModernColors {
    let neonPurple = Color(hex: "9D4EDD")
    let electricBlue = Color(hex: "0080FF")
    let hotPink = Color(hex: "FF1493")
    let neonGreen = Color(hex: "39FF14")
    let neonCyan = Color(hex: "00FFFF")
    let neonOrange = Color(hex: "FF6700")
    let neonYellow = Color(hex: "FFFF00")
    
    func randomColor() -> Color {
        [neonPurple, electricBlue, hotPink, neonGreen, neonCyan, neonOrange, neonYellow].randomElement()!
    }
}

// MARK: - View Models and Data Types
struct HomeTrendingItem: Identifiable {
    let id = UUID()
    let title: String
    let price: Int
    let imageURL: String
    let views: Int
}

struct Activity: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let time: String
}

class UltraModernHomeViewModel: ObservableObject {
    @Published var greeting = "Welcome back!"
    @Published var unreadNotifications = 3
    @Published var activeUsers = 127
    @Published var newListingsToday = 42
    @Published var totalSaved = 1250
    @Published var trendingItems: [HomeTrendingItem] = []
    @Published var recentActivities: [Activity] = []
    
    init() {
        updateGreeting()
        loadMockData()
    }
    
    func loadHomeData() {
        // Load real data from API
        Task {
            await loadTrendingItems()
            await loadRecentActivities()
            await updateStats()
        }
    }
    
    func refreshData() async {
        loadHomeData()
    }
    
    private func updateGreeting() {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            greeting = "Good morning, Shalin! ☀️"
        } else if hour < 17 {
            greeting = "Good afternoon! 🌤"
        } else {
            greeting = "Good evening! 🌙"
        }
    }
    
    private func loadMockData() {
        // Mock trending items
        trendingItems = [
            HomeTrendingItem(title: "MacBook Pro 16\"", price: 75, imageURL: "", views: 234),
            HomeTrendingItem(title: "Electric Scooter", price: 25, imageURL: "", views: 189),
            HomeTrendingItem(title: "Canon DSLR Camera", price: 45, imageURL: "", views: 156)
        ]
        
        // Mock activities
        recentActivities = [
            Activity(title: "New listing nearby", subtitle: "PlayStation 5 available", icon: "location.fill", time: "2m ago"),
            Activity(title: "Price drop alert", subtitle: "Drone rental now $30/day", icon: "tag.fill", time: "15m ago"),
            Activity(title: "Popular in your area", subtitle: "Power tools category trending", icon: "flame.fill", time: "1h ago")
        ]
    }
    
    private func loadTrendingItems() async {
        // API call to load trending items
    }
    
    private func loadRecentActivities() async {
        // API call to load activities
    }
    
    private func updateStats() async {
        // API call to update stats
    }
}

// MARK: - Notifications View
struct HomeNotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var notifications: [NotificationItem] = []

    var body: some View {
        NavigationView {
            List {
                ForEach(notifications) { notification in
                    NotificationRowView(notification: notification)
                }
                .onDelete(perform: deleteNotifications)
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Mark All Read") {
                        markAllAsRead()
                    }
                    .disabled(notifications.allSatisfy { $0.isRead })
                }
            }
            .onAppear {
                loadNotifications()
            }
        }
    }

    private func loadNotifications() {
        // Mock notifications
        notifications = [
            NotificationItem(
                id: UUID().uuidString,
                title: "New message from John",
                body: "Hey, is the bicycle still available?",
                type: .message,
                timestamp: Date().addingTimeInterval(-300),
                isRead: false
            ),
            NotificationItem(
                id: UUID().uuidString,
                title: "Rental request approved",
                body: "Your Camera rental request has been approved",
                type: .booking,
                timestamp: Date().addingTimeInterval(-3600),
                isRead: false
            ),
            NotificationItem(
                id: UUID().uuidString,
                title: "Payment received",
                body: "You've received $45 for your Power Drill rental",
                type: .payment,
                timestamp: Date().addingTimeInterval(-7200),
                isRead: true
            ),
            NotificationItem(
                id: UUID().uuidString,
                title: "New listing nearby",
                body: "Someone listed a MacBook Pro near you",
                type: .newListing,
                timestamp: Date().addingTimeInterval(-86400),
                isRead: true
            )
        ]
    }

    private func markAllAsRead() {
        notifications = notifications.map { notification in
            var updated = notification
            updated.isRead = true
            return updated
        }
    }

    private func deleteNotifications(at offsets: IndexSet) {
        notifications.remove(atOffsets: offsets)
    }
}

struct NotificationRowView: View {
    let notification: NotificationItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: notification.type.icon)
                .font(.title2)
                .foregroundColor(notification.type.color)
                .frame(width: 40, height: 40)
                .background(notification.type.color.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.title)
                        .font(.system(size: 16, weight: notification.isRead ? .medium : .semibold))
                        .foregroundColor(Theme.Colors.text)
                        .lineLimit(1)

                    Spacer()

                    Text(timeAgo(from: notification.timestamp))
                        .font(.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }

                Text(notification.body)
                    .font(.system(size: 14))
                    .foregroundColor(notification.isRead ? Theme.Colors.secondaryText : Theme.Colors.text)
                    .lineLimit(2)
            }

            if !notification.isRead {
                Circle()
                    .fill(Theme.Colors.primary)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
        .background(notification.isRead ? Color.clear : Theme.Colors.primary.opacity(0.05))
    }

    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct NotificationItem: Identifiable {
    let id: String
    let title: String
    let body: String
    let type: HomeNotificationType
    let timestamp: Date
    var isRead: Bool
}

enum HomeNotificationType: String, CaseIterable {
    case message, booking, payment, newListing

    var icon: String {
        switch self {
        case .message: return "message.fill"
        case .booking: return "calendar"
        case .payment: return "dollarsign.circle.fill"
        case .newListing: return "plus.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .message: return .blue
        case .booking: return .green
        case .payment: return .orange
        case .newListing: return .purple
        }
    }
}

// MARK: - Preview
struct UltraModernHomeView_Previews: PreviewProvider {
    static var previews: some View {
        UltraModernHomeView()
    }
}