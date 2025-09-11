import SwiftUI
import Charts

struct StunningProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = ModernProfileViewModel()
    
    @State private var selectedTab = 0
    @State private var showEditProfile = false
    @State private var showSettings = false
    @State private var animateIn = false
    @State private var headerOffset: CGFloat = 0
    @State private var profileScale: CGFloat = 1
    @State private var glowAnimation = false
    
    let tabs = ["Overview", "Activity", "Analytics", "Reviews"]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Animated gradient background
                animatedBackground
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Hero header section
                        heroHeader
                            .padding(.bottom, -60)
                            .zIndex(10)
                        
                        // Main content card
                        VStack(spacing: 24) {
                            // User info card
                            userInfoCard
                            
                            // Quick stats
                            quickStatsGrid
                            
                            // Tab selector
                            customTabSelector
                            
                            // Dynamic content based on tab
                            tabContent
                                .padding(.bottom, 100)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 80)
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 20, y: -10)
                                .ignoresSafeArea(edges: .bottom)
                        )
                    }
                }
                .coordinateSpace(name: "scroll")
                
                // Floating buttons
                floatingButtons
            }
            .navigationBarHidden(true)
            .onAppear {
                startAnimations()
                viewModel.loadProfileData()
            }
            .sheet(isPresented: $showEditProfile) {
                if let user = authManager.currentUser {
                    EditProfileView(user: user)
                }
            }
            .sheet(isPresented: $showSettings) {
                NativeSettingsView()
            }
        }
    }
    
    // MARK: - Animated Background
    private var animatedBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Theme.Colors.primary,
                    Theme.Colors.primary.opacity(0.8),
                    Color(#colorLiteral(red: 0.0862745098, green: 0.6274509804, blue: 0.5215686275, alpha: 1))
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated circles
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .blur(radius: 40)
                    .offset(
                        x: animateIn ? CGFloat.random(in: -100...100) : 0,
                        y: animateIn ? CGFloat.random(in: -200...200) : 0
                    )
                    .animation(
                        .easeInOut(duration: Double.random(in: 10...15))
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 2),
                        value: animateIn
                    )
            }
        }
    }
    
    // MARK: - Hero Header
    private var heroHeader: some View {
        VStack(spacing: 20) {
            // Profile image with effects
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 100
                        )
                    )
                    .frame(width: 180, height: 180)
                    .blur(radius: 20)
                    .opacity(glowAnimation ? 0.8 : 0.4)
                    .animation(
                        .easeInOut(duration: 2)
                        .repeatForever(autoreverses: true),
                        value: glowAnimation
                    )
                
                // Profile image
                if let user = authManager.currentUser {
                    if let imageUrl = user.profilePicture, !imageUrl.isEmpty {
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "person.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .frame(width: 140, height: 140)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                        )
                        .shadow(radius: 10)
                    } else {
                        Circle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 140, height: 140)
                            .overlay(
                                Text(user.username.prefix(2).uppercased())
                                    .font(.system(size: 50, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                            )
                            .shadow(radius: 10)
                    }
                    
                    // Verified badge
                    if user.verified ?? false {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .background(
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 40, height: 40)
                            )
                            .offset(x: 50, y: 50)
                    }
                }
            }
            .scaleEffect(profileScale)
            .opacity(animateIn ? 1 : 0)
            .animation(.spring(response: 0.6), value: animateIn)
        }
        .padding(.top, 60)
        .padding(.bottom, 40)
    }
    
    // MARK: - User Info Card
    private var userInfoCard: some View {
        VStack(spacing: 12) {
            if let user = authManager.currentUser {
                Text(user.username)
                    .font(.largeTitle.bold())
                    .foregroundColor(.primary)
                
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let bio = user.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.body)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Member since
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text("Member since \(formatMemberDate(user.createdAt ?? ""))")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                
                // Action buttons
                HStack(spacing: 16) {
                    Button(action: { showEditProfile = true }) {
                        Label("Edit Profile", systemImage: "square.and.pencil")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Theme.Colors.primary)
                            .cornerRadius(25)
                    }
                    
                    Button(action: { }) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(.subheadline.bold())
                            .foregroundColor(Theme.Colors.primary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Theme.Colors.primary, lineWidth: 2)
                            )
                    }
                }
                .padding(.top, 8)
            }
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
        .animation(.spring(response: 0.6).delay(0.2), value: animateIn)
    }
    
    // MARK: - Quick Stats Grid
    private var quickStatsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ProfileQuickStat(
                title: "Listings",
                value: "\(viewModel.userListings.count)",
                icon: "cube.box.fill",
                color: .blue
            )
            
            ProfileQuickStat(
                title: "Rating",
                value: String(format: "%.1f", viewModel.rating),
                icon: "star.fill",
                color: .orange
            )
            
            ProfileQuickStat(
                title: "Earnings",
                value: "$\(viewModel.totalEarnings)",
                icon: "dollarsign.circle.fill",
                color: .green
            )
            
            ProfileQuickStat(
                title: "Reviews",
                value: "\(viewModel.reviewCount)",
                icon: "text.bubble.fill",
                color: .purple
            )
        }
        .opacity(animateIn ? 1 : 0)
        .animation(.spring(response: 0.6).delay(0.3), value: animateIn)
    }
    
    // MARK: - Custom Tab Selector
    private var customTabSelector: some View {
        HStack(spacing: 0) {
            ForEach(tabs.indices, id: \.self) { index in
                ProfileTabButton(
                    title: tabs[index],
                    isSelected: selectedTab == index,
                    action: {
                        withAnimation(.spring(response: 0.3)) {
                            selectedTab = index
                            HapticManager.impact(style: .light)
                        }
                    }
                )
            }
        }
        .padding(4)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .opacity(animateIn ? 1 : 0)
        .animation(.spring(response: 0.6).delay(0.4), value: animateIn)
    }
    
    // MARK: - Tab Content
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case 0:
            overviewContent
        case 1:
            activityContent
        case 2:
            analyticsContent
        case 3:
            reviewsContent
        default:
            EmptyView()
        }
    }
    
    // MARK: - Overview Content
    private var overviewContent: some View {
        VStack(spacing: 20) {
            // Active listings
            if !viewModel.userListings.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "cube.box.fill")
                            .foregroundColor(Theme.Colors.primary)
                        Text("Active Listings")
                            .font(.headline)
                        Spacer()
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(viewModel.userListings.prefix(5)) { listing in
                                MiniListingCard(listing: listing)
                            }
                        }
                    }
                }
            }
            
            // Recent activity summary
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(Theme.Colors.primary)
                    Text("Recent Activity")
                        .font(.headline)
                    Spacer()
                }
                
                if viewModel.recentActivity.isEmpty {
                    EmptyActivityView()
                } else {
                    ForEach(viewModel.recentActivity.prefix(3)) { activity in
                        ProfileActivityRow(activity: activity)
                    }
                }
            }
        }
        .transition(.opacity)
    }
    
    // MARK: - Activity Content
    private var activityContent: some View {
        VStack(spacing: 16) {
            if viewModel.recentActivity.isEmpty {
                EmptyActivityView()
            } else {
                ForEach(viewModel.recentActivity) { activity in
                    ProfileActivityRow(activity: activity)
                }
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }
    
    // MARK: - Analytics Content
    private var analyticsContent: some View {
        VStack(spacing: 20) {
            // Earnings chart
            if !viewModel.earningsData.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Weekly Earnings")
                        .font(.headline)
                    
                    Chart(viewModel.earningsData) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Amount", point.amount)
                        )
                        .foregroundStyle(Theme.Colors.primary)
                        .interpolationMethod(.catmullRom)
                        
                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Amount", point.amount)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Theme.Colors.primary.opacity(0.3),
                                    Theme.Colors.primary.opacity(0.05)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }
                    .frame(height: 200)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
            }
            
            // Performance metrics
            VStack(spacing: 16) {
                PerformanceRow(
                    title: "Total Views",
                    value: "1,234",
                    change: "+12%",
                    isPositive: true
                )
                
                PerformanceRow(
                    title: "Conversion Rate",
                    value: "24%",
                    change: "+3%",
                    isPositive: true
                )
                
                PerformanceRow(
                    title: "Response Time",
                    value: "2.5h",
                    change: "-15%",
                    isPositive: true
                )
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }
    
    // MARK: - Reviews Content
    private var reviewsContent: some View {
        VStack(spacing: 20) {
            // Rating summary
            HStack(spacing: 30) {
                VStack(spacing: 8) {
                    Text(String(format: "%.1f", viewModel.rating))
                        .font(.system(size: 48, weight: .bold))
                    
                    HStack(spacing: 4) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < Int(viewModel.rating.rounded()) ? "star.fill" : "star")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Text("\(viewModel.reviewCount) reviews")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach((1...5).reversed(), id: \.self) { stars in
                        HStack(spacing: 8) {
                            Text("\(stars)")
                                .font(.caption)
                                .frame(width: 20)
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color(.systemGray5))
                                        .frame(height: 8)
                                        .cornerRadius(4)
                                    
                                    Rectangle()
                                        .fill(Color.orange)
                                        .frame(
                                            width: geometry.size.width * CGFloat.random(in: 0.2...1.0),
                                            height: 8
                                        )
                                        .cornerRadius(4)
                                }
                            }
                            .frame(height: 8)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
            
            // Recent reviews
            if viewModel.userReviews.isEmpty {
                Text("No reviews yet")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                ForEach(viewModel.userReviews.prefix(5)) { profileReview in
                    SimpleReviewCard(review: Review(
                        reviewerName: profileReview.reviewerName,
                        rating: profileReview.rating,
                        comment: profileReview.comment,
                        date: profileReview.date
                    ))
                }
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }
    
    // MARK: - Floating Buttons
    private var floatingButtons: some View {
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
                                .blur(radius: 1)
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
                                .blur(radius: 1)
                        )
                }
            }
            .padding(.horizontal)
            .padding(.top, 50)
            
            Spacer()
        }
    }
    
    // MARK: - Helper Functions
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.8)) {
            animateIn = true
        }
        glowAnimation = true
    }
    
    private func formatMemberDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMMM yyyy"
            return displayFormatter.string(from: date)
        }
        return "2025"
    }
}

// MARK: - Supporting Views

struct ProfileQuickStat: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct ProfileTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    isSelected ? Theme.Colors.primary : Color.clear
                )
                .cornerRadius(8)
        }
    }
}

struct MiniListingCard: View {
    let listing: Listing
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let imageUrl = listing.imageUrls.first {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                }
                .frame(width: 120, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(listing.title)
                    .font(.caption.bold())
                    .lineLimit(1)
                
                Text("$\(Int(listing.price))")
                    .font(.subheadline.bold())
                    .foregroundColor(Theme.Colors.primary)
            }
        }
        .frame(width: 120)
    }
}

struct ProfileActivityRow: View {
    let activity: UserActivity
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: activity.icon)
                .font(.title3)
                .foregroundColor(activity.color)
                .frame(width: 40, height: 40)
                .background(activity.color.opacity(0.1))
                .cornerRadius(20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.subheadline.bold())
                
                Text(activity.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(activity.timeAgo)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct EmptyActivityView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("No recent activity")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Your rental activity will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct PerformanceRow: View {
    let title: String
    let value: String
    let change: String
    let isPositive: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.title3.bold())
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption)
                Text(change)
                    .font(.caption.bold())
            }
            .foregroundColor(isPositive ? .green : .red)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SimpleReviewCard: View {
    let review: Review
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(Theme.Colors.primary.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(review.reviewerName.prefix(1))
                            .font(.headline)
                            .foregroundColor(Theme.Colors.primary)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(review.reviewerName)
                        .font(.subheadline.bold())
                    
                    HStack(spacing: 2) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < review.rating ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                Spacer()
                
                Text(review.date, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(review.comment)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}


// Preview
struct StunningProfileView_Previews: PreviewProvider {
    static var previews: some View {
        StunningProfileView()
            .environmentObject(AuthManager.shared)
    }
}