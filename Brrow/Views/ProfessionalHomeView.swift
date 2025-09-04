//
//  ProfessionalHomeView.swift
//  Brrow
//
//  Professional home screen with green/white theme and smooth animations
//

import SwiftUI
import MapKit

struct ProfessionalHomeView: View {
    @StateObject private var viewModel = ProfessionalHomeViewModel()
    @State private var selectedCategory: HomeCategory = .all
    @State private var animateWelcome = false
    @State private var showNotifications = false
    @State private var showAllNews = false
    @State private var pulseAnimation = false
    @State private var showFullMapView = false
    @State private var showCalculatorLauncher = false
    @State private var showAllFavorites = false
    @State private var selectedListing: Listing?
    @State private var showingListingDetail = false
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var body: some View {
        ZStack {
                // Clean white background
                Theme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Professional Header
                        professionalHeader
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.top, 10)
                        
                        // Welcome Section with subtle animation
                        welcomeSection
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.top, Theme.Spacing.lg)
                        
                        // Quick Actions Grid
                        quickActionsGrid
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.top, Theme.Spacing.xl)
                        
                        // Calculator Promotion Banner
                        calculatorPromotionBanner
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.top, Theme.Spacing.lg)
                        
                        // News & Promotions Panel
                        newsPromotionsSection
                            .padding(.top, Theme.Spacing.xl)
                        
                        // Garage Sales Map Widget
                        garageSalesSection
                            .padding(.top, Theme.Spacing.xl)
                        
                        // Featured Section
                        featuredSection
                            .padding(.top, Theme.Spacing.xl)
                        
                        // Recent Activity
                        recentActivitySection
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.top, Theme.Spacing.xl)
                        
                        // Bottom padding
                        Color.clear.frame(height: 100)
                    }
                }
                .refreshable {
                    await viewModel.refreshData()
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                startAnimations()
                viewModel.loadHomeData()
            }
            .errorAlert(error: $viewModel.errorMessage, title: "Error Loading Content")
            .toast(message: $viewModel.toastMessage, type: viewModel.toastType)
            .loadingOverlay(isLoading: $viewModel.isLoadingFeatured, message: "Loading featured items...")
            .sheet(isPresented: $showNotifications) {
                SystemNotificationsView()
            }
            .sheet(isPresented: $showAllNews) {
                NavigationView {
                    SystemNotificationsView()
                        .navigationTitle("News & Updates")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showAllNews = false
                                }
                            }
                        }
                }
            }
            .sheet(isPresented: $showAllFavorites) {
                NavigationView {
                    AllFavoritesView()
                        .navigationTitle("Your Favorites")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showAllFavorites = false
                                }
                                .foregroundColor(Theme.Colors.primary)
                            }
                        }
                }
            }
    }
    
    // MARK: - Professional Header
    private var professionalHeader: some View {
        HStack {
            // Logo with subtle animation
            HStack(spacing: 12) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(Theme.Colors.primary)
                    .rotationEffect(.degrees(pulseAnimation ? 10 : -10))
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseAnimation)
                
                Text("Brrow")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.Colors.text)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                // Search button
                Button(action: { TabSelectionManager.shared.switchToMarketplaceWithSearch() }) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Theme.Colors.text)
                        .frame(width: 44, height: 44)
                        .background(Theme.Colors.secondaryBackground)
                        .clipShape(Circle())
                }
                
                // Notifications
                Button(action: { showNotifications = true }) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Theme.Colors.text)
                            .frame(width: 44, height: 44)
                            .background(Theme.Colors.secondaryBackground)
                            .clipShape(Circle())
                        
                        if viewModel.unreadNotifications > 0 {
                            Circle()
                                .fill(Theme.Colors.accent)
                                .frame(width: 12, height: 12)
                                .overlay(
                                    Text("\(viewModel.unreadNotifications)")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.white)
                                )
                                .offset(x: -8, y: 8)
                        }
                    }
                }
            }
        }
        // Universal listing detail is now handled by withUniversalListingDetail() modifier
    }
    
    // MARK: - Welcome Section
    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.greeting)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(Theme.Colors.text)
                .opacity(animateWelcome ? 1 : 0)
                .offset(y: animateWelcome ? 0 : 20)
                .animation(.easeOut(duration: 0.6), value: animateWelcome)
            
            Text("what_would_you_like_to_share_today".localizedString)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Theme.Colors.secondaryText)
                .opacity(animateWelcome ? 1 : 0)
                .offset(y: animateWelcome ? 0 : 20)
                .animation(.easeOut(duration: 0.6).delay(0.1), value: animateWelcome)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Quick Actions Grid
    private var quickActionsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.md) {
            ForEach(QuickAction.allCases, id: \.self) { action in
                ProfessionalQuickActionCard(action: action)
                    .opacity(animateWelcome ? 1 : 0)
                    .scaleEffect(animateWelcome ? 1 : 0.8)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(action.index) * 0.1), value: animateWelcome)
            }
        }
    }
    
    // MARK: - Garage Sales Section
    private var garageSalesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Theme.Colors.primary)
                    
                    Text("garage_sales_near_you".localizedString)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Theme.Colors.text)
                }
                
                Spacer()
                
                Button(action: { showFullMapView = true }) {
                    HStack(spacing: 4) {
                        Text("view_all".localizedString)
                        Image(systemName: "arrow.up.forward")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.Colors.primary)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            
            // Map widget
            ZStack {
                // Map view
                Group {
                    if viewModel.nearbyGarageSales.isEmpty {
                        ZStack {
                            Rectangle()
                                .fill(Theme.Colors.secondaryBackground)
                            VStack(spacing: 8) {
                                Image(systemName: "map")
                                    .font(.system(size: 30))
                                    .foregroundColor(Theme.Colors.secondary)
                                Text("no_garage_sales_nearby".localizedString)
                                    .font(.system(size: 14))
                                    .foregroundColor(Theme.Colors.secondaryText)
                            }
                        }
                    } else {
                        Map(coordinateRegion: $mapRegion, annotationItems: viewModel.nearbyGarageSales) { sale in
                            MapAnnotation(coordinate: sale.coordinate) {
                                GarageSaleMapPin(sale: sale)
                            }
                        }
                    }
                }
                .frame(height: 180)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Theme.Colors.secondary.opacity(0.1), lineWidth: 1)
                )
                .disabled(true) // Disable interaction for widget
                
                // Gradient overlay for better text readability
                VStack {
                    Spacer()
                    LinearGradient(
                        colors: [Color.clear, Color.black.opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 60)
                }
                .cornerRadius(16)
                
                // Info overlay
                VStack {
                    Spacer()
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.nearbyGarageSales.isEmpty ? "no_sales_this_weekend".localizedString : String(format: "sales_this_weekend".localizedString, viewModel.nearbyGarageSales.count))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("tap_to_explore".localizedString)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.forward.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                    .padding()
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .onTapGesture {
                showFullMapView = true
            }
            
            // Quick preview cards
            if !viewModel.nearbyGarageSales.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.nearbyGarageSales.prefix(3)) { sale in
                            NavigationLink(destination: GarageSaleDetailView(sale: sale)) {
                                GarageSalePreviewCard(sale: sale)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                }
            }
        }
        .sheet(isPresented: $showFullMapView) {
            NavigationView {
                EnhancedGarageSaleMapView()
            }
        }
        .sheet(isPresented: $showCalculatorLauncher) {
            CalculatorLauncherView()
        }
    }
    
    // MARK: - Calculator Promotion Banner
    private var calculatorPromotionBanner: some View {
        Button(action: { showCalculatorLauncher = true }) {
            HStack(spacing: 16) {
                // Brrow Logo with Animation
                ZStack {
                    Circle()
                        .fill(Theme.Colors.primary)
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "cube.box.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(.white)
                        .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseAnimation)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text("Try the Borrow vs Buy Calculator")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Theme.Colors.text)
                        .lineLimit(1)
                    
                    Text("Make smart financial decisions before purchasing")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.secondaryText)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Theme.Colors.primary)
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [Theme.Colors.primary.opacity(0.3), Theme.Colors.primary.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: Theme.Colors.primary.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    
    // MARK: - Featured Section
    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Text("featured_items".localizedString)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Theme.Colors.text)
                
                Spacer()
                
                Button(action: { TabSelectionManager.shared.switchToMarketplace() }) {
                    Text("see_all".localizedString)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.Colors.primary)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            
            if viewModel.featuredItems.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "cube.box")
                            .font(.system(size: 30))
                            .foregroundColor(Theme.Colors.secondary)
                        Text("no_featured_items_available".localizedString)
                            .font(.system(size: 14))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                    .padding(.vertical, 40)
                    Spacer()
                }
                .padding(.horizontal, Theme.Spacing.md)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.md) {
                        ForEach(viewModel.featuredItems) { item in
                            FeaturedItemCard(item: item) {
                                // Use universal listing navigation
                                ListingNavigationManager.shared.showListing(item.listing)
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                }
            }
        }
    }
    
    // MARK: - Recent Activity Section
    // MARK: - News & Promotions Section
    private var newsPromotionsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "megaphone.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Theme.Colors.primary)
                    
                    Text("News & Updates")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Theme.Colors.text)
                }
                
                Spacer()
                
                Button(action: {
                    showAllNews = true
                }) {
                    Text("View All")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.Colors.primary)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.md)
            
            // News Carousel
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.md) {
                    // Welcome Promotion
                    NewsPromotionCard(
                        title: "🎉 Brrow is Just Getting Started!",
                        subtitle: "Discover amazing items from your neighbors",
                        description: "Join thousands of users already saving money and building community connections",
                        gradientColors: [Color(hex: "#2ABF5A"), Color(hex: "#1F9646")],
                        action: {
                            TabSelectionManager.shared.switchToMarketplace()
                        },
                        actionText: "View Listings"
                    )
                    
                    // Subscription Promotion
                    NewsPromotionCard(
                        title: "🌟 Upgrade to Brrow Green",
                        subtitle: "Unlock premium features",
                        description: "Get verified badge, priority support, and larger media uploads",
                        gradientColors: [Color(hex: "#FFD700"), Color(hex: "#FFA500")],
                        action: {
                            // Navigate to subscription
                        },
                        actionText: "Learn More"
                    )
                    
                    // Feature Announcement
                    NewsPromotionCard(
                        title: "📱 New: Media Messaging",
                        subtitle: "Share photos & videos in chat",
                        description: "Now you can send images and videos directly in your conversations",
                        gradientColors: [Color(hex: "#007AFF"), Color(hex: "#0051D5")],
                        action: {
                            // Navigate to messages
                        },
                        actionText: "Try Now"
                    )
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
            .frame(height: 200)
        }
        .opacity(animateWelcome ? 1 : 0)
        .offset(y: animateWelcome ? 0 : 30)
        .animation(.easeOut(duration: 0.6).delay(0.4), value: animateWelcome)
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("recent_activity".localizedString)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Theme.Colors.text)
            
            if viewModel.recentActivities.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 30))
                        .foregroundColor(Theme.Colors.secondary)
                    Text("no_recent_activity".localizedString)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.secondaryText)
                    Text("your_recent_activity_will_appear_here".localizedString)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.tertiaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Theme.Colors.secondaryBackground)
                .cornerRadius(12)
            } else {
                VStack(spacing: Theme.Spacing.sm) {
                    ForEach(viewModel.recentActivities) { activity in
                        ActivityRow(activity: activity)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func startAnimations() {
        withAnimation {
            animateWelcome = true
            pulseAnimation = true
        }
    }
}

// MARK: - Professional Quick Action Card
struct ProfessionalQuickActionCard: View {
    let action: QuickAction
    @State private var isPressed = false
    @State private var showCreateListing = false
    @State private var showSeeks = false
    @State private var showAllFavorites = false
    
    var body: some View {
        Button(action: { handleAction() }) {
            VStack(spacing: 16) {
                // Icon with green gradient background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Theme.Colors.primary.opacity(0.1), Theme.Colors.primary.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: action.icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(Theme.Colors.primary)
                }
                
                VStack(spacing: 4) {
                    Text(action.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.Colors.text)
                    
                    Text(action.subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.lg)
            .shadow(color: Theme.Shadows.card, radius: Theme.Shadows.cardRadius, x: 0, y: 2)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .sheet(isPresented: $showCreateListing) {
            ModernCreateListingView()
        }
        .sheet(isPresented: $showSeeks) {
            NavigationView {
                ProfessionalSeeksView()
                    .navigationTitle("Seeks")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showSeeks = false
                            }
                            .foregroundColor(Theme.Colors.primary)
                        }
                    }
            }
        }
        .sheet(isPresented: $showAllFavorites) {
            NavigationView {
                AllFavoritesView()
                    .navigationTitle("Your Favorites")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showAllFavorites = false
                            }
                            .foregroundColor(Theme.Colors.primary)
                        }
                    }
            }
        }
    }
    
    private func handleAction() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        switch action {
        case .list:
            showCreateListing = true
        case .search:
            TabSelectionManager.shared.switchToMarketplaceWithSearch()
        case .seeks:
            showSeeks = true
        case .favorites:
            showAllFavorites = true
        }
    }
}

// MARK: - Favorite Item Card
struct FavoriteItemCard: View {
    let item: Listing
    
    var body: some View {
        NavigationLink(destination: ListingDetailView(listing: item)) {
            VStack(alignment: .leading, spacing: 0) {
                // Image
                AsyncImage(url: URL(string: item.images.first ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Theme.Colors.secondary.opacity(0.2))
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 20))
                                .foregroundColor(Theme.Colors.secondary)
                        )
                }
                .frame(width: 140, height: 100)
                .clipped()
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.Colors.text)
                        .lineLimit(2)
                    
                    Text("$\(String(format: "%.2f", item.price))/day")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.Colors.primary)
                }
                .padding(8)
            }
            .frame(width: 140)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(12)
            .shadow(color: Theme.Shadows.card, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Featured Item Card
struct FeaturedItemCard: View {
    let item: FeaturedItem
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            AsyncImage(url: URL(string: item.imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Theme.Colors.secondary.opacity(0.2))
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 24))
                            .foregroundColor(Theme.Colors.secondary)
                    )
            }
            .frame(width: 240, height: 160)
            .clipped()
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(item.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
                    .lineLimit(2)
                
                HStack {
                    Text("$\(item.price)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Theme.Colors.primary)
                    
                    Text("/" + "day".localizedString)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.secondaryText)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.accentOrange)
                        
                        Text(String(format: "%.1f", item.rating))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.Colors.text)
                    }
                }
            }
            .padding(Theme.Spacing.md)
        }
        .frame(width: 240)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.lg)
        .shadow(color: Theme.Shadows.card, radius: Theme.Shadows.cardRadius, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Activity Row
struct ActivityRow: View {
    let activity: ProfessionalRecentActivity
    
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Icon
            Circle()
                .fill(Theme.Colors.primary.opacity(0.1))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: activity.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Theme.Colors.primary)
                )
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.Colors.text)
                
                Text(activity.time)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            
            Spacer()
            
            // Arrow
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.Colors.tertiaryText)
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(Theme.CornerRadius.md)
    }
}

// MARK: - Supporting Types
enum QuickAction: CaseIterable {
    case list, search, seeks, favorites
    
    var title: String {
        switch self {
        case .list: return "list_item".localizedString
        case .search: return "search".localizedString
        case .seeks: return "seeks".localizedString
        case .favorites: return "Favorites"
        }
    }
    
    var subtitle: String {
        switch self {
        case .list: return "share_something".localizedString
        case .search: return "find_items".localizedString
        case .seeks: return "view_requests".localizedString
        case .favorites: return "Your saved items"
        }
    }
    
    var icon: String {
        switch self {
        case .list: return "plus.circle.fill"
        case .search: return "magnifyingglass"
        case .seeks: return "bubble.left.and.bubble.right.fill"
        case .favorites: return "heart.fill"
        }
    }
    
    var index: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }
}

enum HomeCategory: String, CaseIterable {
    case all = "All"
    case trending = "Trending"
    case nearby = "Nearby"
    case deals = "Deals"
}

struct FeaturedItem: Identifiable {
    let id = UUID()
    let title: String
    let price: Int
    let imageURL: String
    let rating: Double
    let listing: Listing
}

struct ProfessionalRecentActivity: Identifiable {
    let id = UUID()
    let title: String
    let time: String
    let icon: String
}

// MARK: - View Model
class ProfessionalHomeViewModel: ObservableObject {
    @Published var greeting = "Welcome back!"
    @Published var unreadNotifications = 0
    @Published var featuredItems: [FeaturedItem] = []
    @Published var recentActivities: [ProfessionalRecentActivity] = []
    @Published var nearbyGarageSales: [GarageSaleItem] = []
    @Published var errorMessage: String?
    @Published var toastMessage: String?
    @Published var toastType: ToastModifier.ToastType = .error
    @Published var isLoadingFeatured = false
    
    init() {
        updateGreeting()
        // Data will be loaded from API
    }
    
    func loadHomeData() {
        Task {
            await loadFeaturedItems()
            await loadRecentActivities()
            await loadGarageSales()
        }
    }
    
    func refreshData() async {
        loadHomeData()
    }
    
    private func updateGreeting() {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            greeting = "good_morning".localizedString
        } else if hour < 17 {
            greeting = "good_afternoon".localizedString
        } else {
            greeting = "good_evening".localizedString
        }
    }
    
    private func loadMockData() {
        // No mock data - all data comes from API
        featuredItems = []
        recentActivities = []
        nearbyGarageSales = []
    }
    
    private func loadFeaturedItems() async {
        do {
            // Simple API call with proper error handling
            let response = try await APIClient.shared.fetchFeaturedListings()
            
            await MainActor.run {
                self.featuredItems = response.data?.listings.compactMap { listing in
                    FeaturedItem(
                        title: listing.title,
                        price: Int(listing.price),
                        imageURL: listing.images.first ?? "",
                        rating: listing.rating ?? 0.0,
                        listing: listing
                    )
                } ?? []
            }
        } catch {
            print("Failed to load featured items: \(error)")
            await MainActor.run {
                self.featuredItems = []
            }
        }
    }
    
    private func loadGarageSales() async {
        do {
            let sales = try await APIClient.shared.fetchGarageSales()
            await MainActor.run {
                self.nearbyGarageSales = sales
                print("🏠 DEBUG: Loaded \(sales.count) garage sales for home view")
            }
        } catch {
            print("❌ Failed to load garage sales for home: \(error)")
            await MainActor.run {
                self.nearbyGarageSales = []
            }
        }
    }
    
    private func loadRecentActivities() async {
        // TODO: Implement recent activities API endpoint
        // For now, show empty state
        await MainActor.run {
            self.recentActivities = []
        }
    }
    
}

// MARK: - Calculator Launcher View
struct CalculatorLauncherView: View {
    @StateObject private var viewModel = CalculatorLauncherViewModel()
    @State private var selectedListing: Listing?
    @State private var showingListingDetail = false
    @State private var showCalculator = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "calculator.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Theme.Colors.primary)
                    
                    Text("Borrow vs Buy Calculator")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Theme.Colors.text)
                    
                    Text("Make smart financial decisions when renting or buying items")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                .padding(.bottom, 32)
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                    Spacer()
                } else if viewModel.listings.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(Theme.Colors.secondary)
                        
                        Text("No items available")
                            .font(.headline)
                            .foregroundColor(Theme.Colors.text)
                        
                        Text("Browse the marketplace first to use the calculator")
                            .font(.subheadline)
                            .foregroundColor(Theme.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                        
                        Button("Go to Marketplace") {
                            dismiss()
                            TabSelectionManager.shared.switchToMarketplace()
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Theme.Colors.primary)
                        .cornerRadius(12)
                    }
                    Spacer()
                } else {
                    // Listings List
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.listings) { listing in
                                CalculatorListingCard(listing: listing) {
                                    selectedListing = listing
                                    showCalculator = true
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Theme.Colors.primary)
                }
            }
        }
        .onAppear {
            viewModel.loadListings()
        }
        .sheet(isPresented: $showCalculator) {
            if let listing = selectedListing {
                BorrowVsBuyCalculatorView(listing: listing)
            }
        }
    }
}

// MARK: - Calculator Listing Card
struct CalculatorListingCard: View {
    let listing: Listing
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Image
                ListingImageView(
                    imageURLs: listing.images,
                    aspectRatio: .fill,
                    cornerRadius: 12
                )
                .frame(width: 80, height: 80)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(listing.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.Colors.text)
                        .lineLimit(2)
                    
                    Text(listing.category)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.secondaryText)
                    
                    HStack {
                        Text("$\(String(format: "%.2f", listing.price))/day")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Theme.Colors.primary)
                        
                        if let buyoutValue = listing.buyoutValue {
                            Text("• $\(String(format: "%.0f", buyoutValue)) to buy")
                                .font(.system(size: 14))
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "calculator")
                    .font(.system(size: 20))
                    .foregroundColor(Theme.Colors.primary)
            }
            .padding()
            .background(Theme.Colors.cardBackground)
            .cornerRadius(16)
            .shadow(color: Theme.Shadows.card, radius: Theme.Shadows.cardRadius, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Calculator Launcher ViewModel
class CalculatorLauncherViewModel: ObservableObject {
    @Published var listings: [Listing] = []
    @Published var isLoading = false
    
    func loadListings() {
        isLoading = true
        
        Task {
            do {
                let response = try await APIClient.shared.fetchFeaturedListings()
                await MainActor.run {
                    self.listings = response.data?.listings ?? []
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.listings = []
                    self.isLoading = false
                }
                print("Failed to load listings for calculator: \(error)")
            }
        }
    }
}

// MARK: - News Promotion Card
struct NewsPromotionCard: View {
    let title: String
    let subtitle: String
    let description: String
    let gradientColors: [Color]
    let action: () -> Void
    let actionText: String
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Text(subtitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(1)
                    
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    // Action Button
                    HStack {
                        Text(actionText)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(gradientColors.first ?? Theme.Colors.primary)
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(gradientColors.first ?? Theme.Colors.primary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(20)
                }
                .padding(20)
            }
            .frame(width: 280, height: 180)
            .background(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .shadow(color: gradientColors.first?.opacity(0.3) ?? Color.black.opacity(0.1), 
                   radius: 8, x: 0, y: 4)
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


// MARK: - Preview
struct ProfessionalHomeView_Previews: PreviewProvider {
    static var previews: some View {
        ProfessionalHomeView()
    }
}