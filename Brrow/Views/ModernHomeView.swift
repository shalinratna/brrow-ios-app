import SwiftUI
import CoreLocation

// MARK: - Models

struct QuickStat: Identifiable {
    let id: String
    let icon: String
    let label: String
    let value: String
    let color: Color
    let order: Int
}

struct HomeUserNotification: Identifiable {
    let id: String
    let icon: String
    let title: String
    let time: String
    let color: Color
}

struct HomeNearbyItem: Identifiable {
    let id: String
    let title: String
    let price: String
    let distance: String
    let imageName: String?
}

struct Category: Identifiable {
    let id: String
    let name: String
    let icon: String
    let color: Color
}

struct NewsItem: Identifiable {
    let id: String
    let icon: String
    let title: String
    let summary: String
    let date: String
}

struct HomeRecentActivity: Identifiable {
    let id: String
    let icon: String
    let description: String
    let time: String
    let color: Color
}

struct ModernHomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = ModernHomeViewModel()
    @State private var animateWelcome = false
    @State private var animateCards = false
    @State private var pulseAnimation = false
    @State private var liquidAnimation = false
    @State private var selectedCategory: String? = nil
    @State private var showNotificationDetail = false
    @State private var refreshing = false
    @State private var showCreateMenu = false
    @State private var navigateToCreateListing = false
    @State private var navigateToCreateSeek = false
    @State private var navigateToCreateGarageSale = false
    
    // Grid layout for dynamic content
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        ZStack {
                // Animated gradient background
                AnimatedHomeBackground()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Personalized header
                        personalizedHeader
                            .padding(.top, 20)
                        
                        // Quick stats bar
                        quickStatsBar
                            .padding(.vertical, 20)
                        
                        // Main content
                        VStack(spacing: 24) {
                            // What's new section
                            if !viewModel.notifications.isEmpty {
                                whatsNewSection
                            }
                            
                            // Nearby items
                            nearbyItemsSection
                            
                            // Categories grid
                            categoriesSection
                            
                            // Latest news
                            latestNewsSection
                            
                            // Recent activity
                            recentActivitySection
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 100)
                    }
                }
                .refreshable {
                    await refreshContent()
                }
                
                // Floating action button
                floatingActionButton
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showNotificationDetail) {
                NavigationView {
                    SystemNotificationsView()
                        .navigationTitle("Notifications")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showNotificationDetail = false
                                }
                            }
                        }
                }
            }
            .onAppear {
                startAnimations()
                viewModel.loadUserData()
                viewModel.trackUserActivity(event: "home_view_opened")
            }
            .confirmationDialog("What would you like to create?", isPresented: $showCreateMenu) {
                Button("New Listing") {
                    navigateToCreateListing = true
                }
                Button("New Seek Request") {
                    navigateToCreateSeek = true
                }
                Button("New Garage Sale") {
                    navigateToCreateGarageSale = true
                }
                Button("Cancel", role: .cancel) {}
            }
            .navigationDestination(isPresented: $navigateToCreateListing) {
                ModernCreateListingView()
            }
            .navigationDestination(isPresented: $navigateToCreateSeek) {
                ModernCreateSeekView()
            }
            .navigationDestination(isPresented: $navigateToCreateGarageSale) {
                ModernCreateGarageSaleView()
            }
    }
    
    // MARK: - Header Section
    
    private var personalizedHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(getGreeting())
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .opacity(animateWelcome ? 1 : 0)
                        .offset(y: animateWelcome ? 0 : 20)
                    
                    Text("\(viewModel.userName) 👋")
                        .font(.largeTitle.bold())
                        .foregroundColor(.primary)
                        .opacity(animateWelcome ? 1 : 0)
                        .offset(y: animateWelcome ? 0 : 20)
                        .animation(.spring().delay(0.1), value: animateWelcome)
                }
                
                Spacer()
                
                // Notification bell with badge
                ZStack(alignment: .topTrailing) {
                    Button(action: { showNotificationDetail = true }) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 48, height: 48)
                            
                            Image(systemName: "bell.fill")
                                .font(.title3)
                                .foregroundColor(Theme.Colors.primary)
                        }
                    }
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    
                    if viewModel.unreadNotifications > 0 {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Text("\(viewModel.unreadNotifications)")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            )
                            .offset(x: -8, y: 8)
                    }
                }
            }
            .padding(.horizontal)
            
            // Motivational message based on activity
            if let message = viewModel.motivationalMessage {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(Theme.Colors.primary)
                        .rotationEffect(.degrees(animateWelcome ? 0 : -180))
                    
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Theme.Colors.primary.opacity(0.1))
                )
                .padding(.horizontal)
                .opacity(animateWelcome ? 1 : 0)
                .offset(y: animateWelcome ? 0 : 20)
                .animation(.spring().delay(0.2), value: animateWelcome)
            }
        }
    }
    
    // MARK: - Quick Stats Bar
    
    private var quickStatsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(viewModel.quickStats) { stat in
                    QuickStatCard(stat: stat)
                        .scaleEffect(animateCards ? 1 : 0.8)
                        .opacity(animateCards ? 1 : 0)
                        .animation(.spring().delay(Double(stat.order) * 0.1), value: animateCards)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - What's New Section
    
    private var whatsNewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("What's New", systemImage: "sparkle")
                    .font(.headline)
                    .foregroundColor(Theme.Colors.primary)
                
                Spacer()
                
                Button("View All") {
                    showNotificationDetail = true
                }
                .font(.subheadline)
                .foregroundColor(Theme.Colors.primary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.notifications.prefix(3)) { notification in
                        NotificationCard(notification: notification)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Nearby Items Section
    
    private var nearbyItemsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Nearby Items", systemImage: "location.fill")
                    .font(.headline)
                
                Spacer()
                
                Text("\(viewModel.nearbyDistance) mi")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color(.systemGray5)))
            }
            
            if viewModel.nearbyItems.isEmpty {
                EmptyNearbyView()
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.nearbyItems.prefix(4)) { item in
                        HomeNearbyItemCard(item: item)
                            .scaleEffect(animateCards ? 1 : 0.9)
                            .opacity(animateCards ? 1 : 0)
                            .animation(
                                .spring()
                                .delay(Double(viewModel.nearbyItems.firstIndex(where: { $0.id == item.id }) ?? 0) * 0.1),
                                value: animateCards
                            )
                    }
                }
            }
        }
    }
    
    // MARK: - Categories Section
    
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Browse Categories")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.categories) { category in
                        HomeCategoryCard(
                            category: category,
                            isSelected: selectedCategory == category.id
                        ) {
                            withAnimation(.spring()) {
                                selectedCategory = category.id
                                HapticManager.impact(style: .light)
                                viewModel.trackUserActivity(event: "category_selected", properties: ["category": category.name])
                            }
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
            }
        }
    }
    
    // MARK: - Latest News Section
    
    private var latestNewsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Latest Updates", systemImage: "newspaper.fill")
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 12) {
                ForEach(viewModel.newsItems) { news in
                    NewsCard(news: news)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
        }
    }
    
    // MARK: - Recent Activity Section
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Your Recent Activity", systemImage: "clock.arrow.circlepath")
                    .font(.headline)
                
                Spacer()
                
                Button("Clear") {
                    viewModel.clearHomeRecentActivity()
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            if viewModel.recentActivities.isEmpty {
                Text("No recent activity")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else {
                ForEach(viewModel.recentActivities.prefix(5)) { activity in
                    HomeRecentActivityRow(activity: activity)
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
                    HapticManager.impact(style: .medium)
                    showCreateMenu = true
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Theme.Colors.primary, Theme.Colors.primary.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                            .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 10, y: 5)
                        
                        Image(systemName: "plus")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(liquidAnimation ? 90 : 0))
                    }
                }
                .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true),
                    value: pulseAnimation
                )
            }
            .padding()
        }
    }
    
    // MARK: - Helper Functions
    
    private func getGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        default:
            return "Good evening"
        }
    }
    
    private func startAnimations() {
        withAnimation(.spring().delay(0.1)) {
            animateWelcome = true
        }
        withAnimation(.spring().delay(0.3)) {
            animateCards = true
        }
        pulseAnimation = true
        
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            liquidAnimation = true
        }
    }
    
    private func refreshContent() async {
        refreshing = true
        await viewModel.refreshData()
        refreshing = false
        HapticManager.impact(style: .light)
    }
}

// MARK: - Supporting Views

struct AnimatedHomeBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Theme.Colors.primary.opacity(0.05),
                    Color(.systemBackground)
                ],
                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                endPoint: animateGradient ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 10).repeatForever(autoreverses: true), value: animateGradient)
            
            // Floating orbs
            GeometryReader { geometry in
                ForEach(0..<3) { i in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Theme.Colors.primary.opacity(0.1),
                                    Theme.Colors.primary.opacity(0.05),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .blur(radius: 40)
                        .offset(
                            x: animateGradient ? CGFloat.random(in: -50...geometry.size.width) : CGFloat.random(in: -50...geometry.size.width),
                            y: animateGradient ? CGFloat.random(in: -50...geometry.size.height) : CGFloat.random(in: -50...geometry.size.height)
                        )
                        .animation(
                            .easeInOut(duration: Double.random(in: 15...25))
                                .repeatForever(autoreverses: true),
                            value: animateGradient
                        )
                }
            }
        }
        .onAppear {
            animateGradient = true
        }
    }
}

struct QuickStatCard: View {
    let stat: QuickStat
    @State private var animateValue = false
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(stat.color.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: stat.icon)
                    .font(.title2)
                    .foregroundColor(stat.color)
                    .scaleEffect(animateValue ? 1.0 : 0.5)
            }
            
            Text(animateValue ? stat.value : "0")
                .font(.headline)
                .contentTransition(.numericText())
            
            Text(stat.label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 100)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10)
        )
        .onAppear {
            withAnimation(.spring().delay(0.5)) {
                animateValue = true
            }
        }
    }
}

struct NotificationCard: View {
    let notification: HomeUserNotification
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(notification.color.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: notification.icon)
                    .foregroundColor(notification.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                
                Text(notification.time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 200)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5)
        )
    }
}

struct HomeNearbyItemCard: View {
    let item: HomeNearbyItem
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color(.systemGray5), Color(.systemGray6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 120)
                
                if let imageName = item.imageName {
                    Image(systemName: imageName)
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                }
                
                // Distance badge
                VStack {
                    HStack {
                        Spacer()
                        Text(item.distance)
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.black.opacity(0.7)))
                            .padding(8)
                    }
                    Spacer()
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                
                Text(item.price)
                    .font(.caption)
                    .foregroundColor(Theme.Colors.primary)
                    .fontWeight(.semibold)
            }
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onTapGesture {
            withAnimation(.spring(response: 0.3)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
        }
    }
}

struct HomeCategoryCard: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            isSelected
                                ? LinearGradient(
                                    colors: [category.color, category.color.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                  )
                                : LinearGradient(
                                    colors: [category.color.opacity(0.1), category.color.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                  )
                        )
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: category.icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? .white : category.color)
                }
                
                Text(category.name)
                    .font(.caption.weight(.medium))
                    .foregroundColor(isSelected ? category.color : .secondary)
            }
            .frame(width: 90)
        }
    }
}

struct NewsCard: View {
    let news: NewsItem
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Theme.Colors.primary.opacity(0.1), Theme.Colors.primary.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: news.icon)
                    .font(.title2)
                    .foregroundColor(Theme.Colors.primary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(news.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                
                Text(news.summary)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text(news.date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct HomeRecentActivityRow: View {
    let activity: HomeRecentActivity
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activity.icon)
                .font(.caption)
                .foregroundColor(activity.color)
                .frame(width: 24, height: 24)
                .background(Circle().fill(activity.color.opacity(0.1)))
            
            Text(activity.description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(activity.time)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct EmptyNearbyView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "location.slash")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text("No items nearby")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Be the first to list something in your area!")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - View Model

class ModernHomeViewModel: ObservableObject {
    @Published var userName = "User"
    @Published var unreadNotifications = 0
    @Published var motivationalMessage: String?
    @Published var quickStats: [QuickStat] = []
    @Published var notifications: [HomeUserNotification] = []
    @Published var nearbyItems: [HomeNearbyItem] = []
    @Published var categories: [Category] = []
    @Published var newsItems: [NewsItem] = []
    @Published var recentActivities: [HomeRecentActivity] = []
    @Published var nearbyDistance = 5
    
    init() {
        // Initialize with empty data - will be loaded from API
        categories = [
            Category(id: "1", name: "Tools", icon: "wrench.fill", color: .orange),
            Category(id: "2", name: "Electronics", icon: "tv.fill", color: .blue),
            Category(id: "3", name: "Sports", icon: "sportscourt.fill", color: .green),
            Category(id: "4", name: "Home", icon: "house.fill", color: .purple),
            Category(id: "5", name: "Events", icon: "calendar", color: .red),
            Category(id: "6", name: "More", icon: "ellipsis", color: .gray)
        ]
    }
    
    func loadUserData() {
        // Get real user data from AuthManager
        if let currentUser = AuthManager.shared.currentUser {
            userName = currentUser.username
            
            Task {
                await fetchUserStats()
                await fetchNearbyItems()
                await fetchUserNotifications()
                await fetchRecentActivity()
            }
        }
        
        trackUserActivity(event: "home_view_loaded")
    }
    
    func fetchUserStats() async {
        do {
            let stats = try await APIClient.shared.fetchUserStats()
            await MainActor.run {
                quickStats = [
                    QuickStat(id: "1", icon: "bag.fill", label: "Active", value: "\(stats.activeListings)", color: .blue, order: 0),
                    QuickStat(id: "2", icon: "star.fill", label: "Rating", value: String(format: "%.1f", stats.rating), color: .orange, order: 1),
                    QuickStat(id: "3", icon: "dollarsign.circle", label: "Earned", value: "$\(stats.totalEarnings)", color: .green, order: 2),
                    QuickStat(id: "4", icon: "heart.fill", label: "Saved", value: "\(stats.savedItems)", color: .red, order: 3)
                ]
                
                // Set motivational message based on actual activity
                if stats.daysActive >= 3 {
                    motivationalMessage = "You've been active for \(stats.daysActive) days in a row! 🔥"
                } else if stats.newMessages > 0 {
                    motivationalMessage = "You have \(stats.newMessages) new messages waiting! 💬"
                } else if stats.activeListings == 0 {
                    motivationalMessage = "Ready to list your first item? Let's get started! 🚀"
                }
            }
        } catch {
            print("Error fetching user stats: \(error)")
        }
    }
    
    func fetchNearbyItems() async {
        do {
            let items = try await APIClient.shared.fetchNearbyListings(radius: nearbyDistance)
            await MainActor.run {
                nearbyItems = items.map { listing in
                    HomeNearbyItem(
                        id: "\(listing.id)",
                        title: listing.title,
                        price: listing.isFree ? "Free" : "$\(listing.price)/day",
                        distance: "\(0.0) mi",
                        imageName: nil
                    )
                }
            }
        } catch {
            print("Error fetching nearby items: \(error)")
        }
    }
    
    func fetchUserNotifications() async {
        do {
            let notifs = try await APIClient.shared.fetchNotifications()
            await MainActor.run {
                unreadNotifications = notifs.filter { !$0.isRead }.count
                notifications = notifs.prefix(5).map { notif in
                    HomeUserNotification(
                        id: notif.id,
                        icon: notificationIcon(for: notif.type),
                        title: notif.title,
                        time: formatTime(notif.createdAt),
                        color: notificationColor(for: notif.type)
                    )
                }
            }
        } catch {
            print("Error fetching notifications: \(error)")
        }
    }
    
    func fetchRecentActivity() async {
        do {
            guard let userId = AuthManager.shared.currentUser?.id, let userIdInt = Int(userId) else { return }
            let activities = try await APIClient.shared.fetchUserActivities(userId: userIdInt)
            await MainActor.run {
                recentActivities = activities.map { activity in
                    HomeRecentActivity(
                        id: activity.id,
                        icon: activityIcon(for: activity.type),
                        description: activity.description,
                        time: formatTime(activity.timestamp),
                        color: activityColor(for: activity.type)
                    )
                }
            }
        } catch {
            print("Error fetching recent activity: \(error)")
        }
    }
    
    func trackUserActivity(event: String, properties: [String: Any] = [:]) {
        // Log user activity
        let activity = HomeRecentActivity(
            id: UUID().uuidString,
            icon: "circle.fill",
            description: event.replacingOccurrences(of: "_", with: " ").capitalized,
            time: "now",
            color: .blue
        )
        recentActivities.insert(activity, at: 0)
        
        // In a real app, send to analytics service
        print("📊 Tracked: \(event) with properties: \(properties)")
    }
    
    func refreshData() async {
        await fetchUserStats()
        await fetchNearbyItems()
        await fetchUserNotifications()
        await fetchRecentActivity()
    }
    
    // Helper functions
    private func notificationIcon(for type: String) -> String {
        switch type {
        case "message": return "message.fill"
        case "review": return "star.fill"
        case "offer": return "tag.fill"
        case "listing_view": return "eye.fill"
        default: return "bell.fill"
        }
    }
    
    private func notificationColor(for type: String) -> Color {
        switch type {
        case "message": return .blue
        case "review": return .orange
        case "offer": return .green
        case "listing_view": return .purple
        default: return .gray
        }
    }
    
    private func activityIcon(for type: String) -> String {
        switch type {
        case "listing_created": return "plus.circle.fill"
        case "listing_viewed": return "eye.fill"
        case "search": return "magnifyingglass"
        case "favorite": return "heart.fill"
        case "message_sent": return "message.fill"
        default: return "circle.fill"
        }
    }
    
    private func activityColor(for type: String) -> Color {
        switch type {
        case "listing_created": return .green
        case "listing_viewed": return .blue
        case "search": return .purple
        case "favorite": return .red
        case "message_sent": return .blue
        default: return .gray
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    func clearHomeRecentActivity() {
        recentActivities.removeAll()
    }
    
}

// MARK: - Preview

struct ModernHomeView_Previews: PreviewProvider {
    static var previews: some View {
        ModernHomeView()
            .environmentObject(AuthManager.shared)
    }
}