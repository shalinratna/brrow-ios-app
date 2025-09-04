import SwiftUI
import Charts

struct ModernProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var profileData = ModernProfileViewModel2()
    @State private var selectedSegment = 0
    @State private var showEditProfile = false
    @State private var showSettings = false
    @State private var animateStats = false
    @State private var selectedStat: String? = nil
    @State private var pulseAnimation = false
    
    let segments = ["Overview", "Activity", "Stats", "Reviews"]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Subtle background
                Theme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Profile Header Section with proper padding
                        profileHeaderSection
                            .padding(.horizontal)
                            .padding(.top, 16)
                            .padding(.bottom, 24)
                        
                        // Quick Stats with better spacing
                        quickStatsSection
                            .padding(.horizontal)
                            .padding(.bottom, 24)
                        
                        // Segmented Control
                        customSegmentedControl
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        
                        // Dynamic Content
                        Group {
                            switch selectedSegment {
                            case 0:
                                overviewContent
                            case 1:
                                activityContent
                            case 2:
                                statsContent
                            case 3:
                                reviewsContent
                            default:
                                overviewContent
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                        .animation(.spring(response: 0.4), value: selectedSegment)
                    }
                    .padding(.bottom, 100) // Bottom padding for tab bar
                }
            }
            .navigationBarTitleDisplayMode(.large)
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button(action: { showEditProfile = true }) {
                            Image(systemName: "square.and.pencil")
                                .font(.body)
                                .foregroundColor(Theme.Colors.primary)
                        }
                        
                        Button(action: { showSettings = true }) {
                            Image(systemName: "gearshape")
                                .font(.body)
                                .foregroundColor(Theme.Colors.primary)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showEditProfile) {
            if let currentUser = authManager.currentUser {
                EditProfileView(user: currentUser)
            } else {
                EditProfileView(user: User(
                    id: 0,
                    username: "guest",
                    email: "guest@example.com"
                ))
            }
        }
        .sheet(isPresented: $showSettings) {
            NativeSettingsView()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateStats = true
            }
            startPulseAnimation()
        }
    }
    
    private var profileHeaderSection: some View {
        VStack(spacing: 20) {
            HStack(alignment: .center, spacing: 24) {
                // Profile Picture
                ZStack {
                    Circle()
                        .fill(Theme.Colors.primary.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    if let avatarUrl = profileData.avatarUrl {
                        AsyncImage(url: URL(string: avatarUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "person.fill")
                                .font(.system(size: 44))
                                .foregroundColor(Theme.Colors.primary.opacity(0.5))
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 44))
                            .foregroundColor(Theme.Colors.primary.opacity(0.5))
                    }
                    
                    // Status indicator
                    Circle()
                        .fill(Color.green)
                        .frame(width: 20, height: 20)
                        .overlay(Circle().stroke(Theme.Colors.cardBackground, lineWidth: 3))
                        .offset(x: 35, y: 35)
                }
                
                // User Info
                VStack(alignment: .leading, spacing: 10) {
                    Text(profileData.displayName)
                        .font(.title2.bold())
                        .foregroundColor(Theme.Colors.text)
                    
                    Text("@\(profileData.username)")
                        .font(.subheadline)
                        .foregroundColor(Theme.Colors.secondaryText)
                    
                    // Member since
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text("Member since \(profileData.memberSince)")
                            .font(.caption)
                    }
                    .foregroundColor(Theme.Colors.secondaryText)
                }
                
                Spacer()
            }
            
            // Bio or description (if available)
            if !profileData.bio.isEmpty {
                Text(profileData.bio)
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.text)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
    
    private var quickStatsSection: some View {
        HStack(spacing: 12) {
            // Total Listings
            quickStatCard(
                icon: "cube.box",
                value: "\(profileData.totalListings)",
                label: "Listings",
                color: Theme.Colors.primary
            )
            
            // Total Earnings
            quickStatCard(
                icon: "dollarsign.circle",
                value: "$\(Int(profileData.totalEarnings))",
                label: "Earned",
                color: .green
            )
            
            // Rating
            quickStatCard(
                icon: "star.fill",
                value: String(format: "%.1f", profileData.rating),
                label: "Rating",
                color: .orange
            )
            
            // Days Active
            quickStatCard(
                icon: "calendar",
                value: "\(profileData.userStats?.daysActive ?? 0)",
                label: "Days",
                color: .blue
            )
        }
    }
    
    private func quickStatCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.text)
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var customSegmentedControl: some View {
        HStack(spacing: 0) {
            ForEach(segments.indices, id: \.self) { index in
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        selectedSegment = index
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(segments[index])
                            .font(.subheadline.weight(selectedSegment == index ? .semibold : .regular))
                            .foregroundColor(selectedSegment == index ? Theme.Colors.primary : .secondary)
                        
                        // Animated underline
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Theme.Colors.primary)
                            .frame(height: 3)
                            .opacity(selectedSegment == index ? 1 : 0)
                            .scaleEffect(x: selectedSegment == index ? 1 : 0.5, anchor: .center)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
    
    private var overviewContent: some View {
        VStack(spacing: 32) {
            // Animated Stats Grid
            VStack(alignment: .leading, spacing: 16) {
                Text("Overview")
                    .font(.headline)
                    .padding(.horizontal)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(statsData, id: \.title) { stat in
                        ModernStatCard(
                            stat: stat,
                            isSelected: selectedStat == stat.title,
                            animateStats: animateStats
                        )
                        .onTapGesture {
                            withAnimation(.spring()) {
                                selectedStat = selectedStat == stat.title ? nil : stat.title
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Recent Activity with animations
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Recent Activity")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button("View All") {
                        withAnimation {
                            selectedSegment = 1
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.primary)
                }
                .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        if profileData.recentActivities.isEmpty {
                            // Placeholder when no activities
                            VStack(spacing: 12) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                                
                                Text("No recent activity")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 250, height: 100)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.Colors.cardBackground)
                            .cornerRadius(16)
                        } else {
                            ForEach(Array(profileData.recentActivities.prefix(5).enumerated()), id: \.element.id) { index, activity in
                                ModernActivityCard(activity: activity)
                                    .transition(.scale.combined(with: .opacity))
                                    .animation(.spring().delay(Double(index) * 0.1), value: animateStats)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // Quick Actions with hover effects
            VStack(alignment: .leading, spacing: 16) {
                Text("Quick Actions")
                    .font(.headline)
                    .padding(.horizontal)
                
                VStack(spacing: 12) {
                    QuickActionRow(icon: "plus.circle.fill", title: "Create Listing", color: Theme.Colors.primary)
                    QuickActionRow(icon: "magnifyingglass.circle.fill", title: "Browse Seeks", color: .blue)
                    QuickActionRow(icon: "bell.circle.fill", title: "Notifications", color: .orange)
                    QuickActionRow(icon: "creditcard.circle.fill", title: "Payment Methods", color: .purple)
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var activityContent: some View {
        VStack(spacing: 20) {
            if profileData.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding(.vertical, 50)
            } else if profileData.recentActivities.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text("No recent activity")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Your recent actions will appear here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 80)
            } else {
                // Activity timeline
                VStack(spacing: 0) {
                    ForEach(Array(profileData.recentActivities.enumerated()), id: \.element.id) { index, activity in
                        ModernTimelineCard(activity: activity)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                            .animation(.spring().delay(Double(index) * 0.05), value: selectedSegment)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var statsContent: some View {
        VStack(spacing: 28) {
            // Interactive charts
            if #available(iOS 16.0, *) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Earnings Overview")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Chart {
                        ForEach(mockChartData) { data in
                            LineMark(
                                x: .value("Month", data.month),
                                y: .value("Earnings", data.earnings)
                            )
                            .foregroundStyle(Theme.Colors.primary)
                            .interpolationMethod(.catmullRom)
                            
                            AreaMark(
                                x: .value("Month", data.month),
                                y: .value("Earnings", data.earnings)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Theme.Colors.primary.opacity(0.3), Color.clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                        }
                    }
                    .frame(height: 220)
                    .padding()
                    .background(Theme.Colors.cardBackground)
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.05), radius: 10)
                    .padding(.horizontal)
                }
            }
            
            // Detailed stats grid
            VStack(alignment: .leading, spacing: 16) {
                Text("Detailed Statistics")
                    .font(.headline)
                    .padding(.horizontal)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    DetailedStatCard(title: "Total Earnings", value: "$\(String(format: "%.0f", profileData.totalEarnings))", trend: .up, percentage: "+12.5%")
                    DetailedStatCard(title: "Active Listings", value: "\(profileData.totalListings)", trend: .up, percentage: "+2")
                    DetailedStatCard(title: "Completed", value: "\(profileData.userStats?.savedItems ?? 0)", trend: .up, percentage: "+5")
                    DetailedStatCard(title: "Rating", value: String(format: "%.1f", profileData.rating), trend: .neutral, percentage: "★★★★★")
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var reviewsContent: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Reviews & Ratings")
                    .font(.headline)
                    .padding(.horizontal)
                
                if profileData.userReviews.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "star.bubble")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No reviews yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Reviews from your transactions will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 80)
                } else {
                    // Reviews with animations
                    VStack(spacing: 16) {
                        ForEach(0..<min(profileData.userReviews.count, 5)) { index in
                            ModernReviewCard(index: index)
                                .transition(.scale.combined(with: .opacity))
                                .animation(.spring().delay(Double(index) * 0.1), value: selectedSegment)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private var statsData: [StatData] {
        [
            StatData(title: "Listings", value: "\(profileData.totalListings)", icon: "bag.fill", color: Theme.Colors.primary),
            StatData(title: "Earnings", value: "$\(Int(profileData.totalEarnings))", icon: "dollarsign.circle.fill", color: .green),
            StatData(title: "Rating", value: String(format: "%.1f", profileData.rating), icon: "star.fill", color: .orange),
            StatData(title: "Reviews", value: "\(profileData.reviewCount)", icon: "text.bubble.fill", color: .blue)
        ]
    }
    
    private var mockChartData: [ChartData] {
        [
            ChartData(month: "Jan", earnings: 1200),
            ChartData(month: "Feb", earnings: 1450),
            ChartData(month: "Mar", earnings: 1100),
            ChartData(month: "Apr", earnings: 1800),
            ChartData(month: "May", earnings: 2100),
            ChartData(month: "Jun", earnings: 2459)
        ]
    }
    
    private func startPulseAnimation() {
        pulseAnimation = true
    }
    
    private func formatTimeAgo(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: dateString) else {
            // Try without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            guard let date = formatter.date(from: dateString) else {
                return "Recently"
            }
            return formatRelativeTime(from: date)
        }
        
        return formatRelativeTime(from: date)
    }
    
    private func formatRelativeTime(from date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else if interval < 604800 {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }
    
    private func getActivityDetail(from metadata: [String: Any]) -> String {
        if let listingTitle = metadata["listing_title"] as? String {
            return "Item: \(listingTitle)"
        } else if let amount = metadata["amount"] as? Double {
            return String(format: "Amount: $%.2f", amount)
        } else if let message = metadata["message"] as? String {
            return message
        } else {
            return "View details"
        }
    }
    
    private func getActivityIcon(for activityType: String) -> String {
        switch activityType {
        case "listing_created":
            return "plus.circle.fill"
        case "listing_viewed":
            return "eye.fill"
        case "listing_updated":
            return "pencil.circle.fill"
        case "listing_favorited":
            return "heart.fill"
        case "message_sent":
            return "message.fill"
        case "message_received":
            return "envelope.fill"
        case "review_posted":
            return "star.fill"
        case "review_received":
            return "star.circle.fill"
        case "payment_sent":
            return "creditcard.fill"
        case "payment_received":
            return "dollarsign.circle.fill"
        case "profile_viewed":
            return "person.crop.circle.fill"
        default:
            return "circle.fill"
        }
    }
    
    private func getActivityTitle(for activityType: String) -> String {
        switch activityType {
        case "listing_created":
            return "Listed Item"
        case "listing_viewed":
            return "Viewed Listing"
        case "listing_updated":
            return "Updated Listing"
        case "listing_favorited":
            return "Favorited"
        case "message_sent":
            return "Sent Message"
        case "message_received":
            return "New Message"
        case "review_posted":
            return "Posted Review"
        case "review_received":
            return "Received Review"
        case "payment_sent":
            return "Payment Sent"
        case "payment_received":
            return "Payment Received"
        case "profile_viewed":
            return "Profile View"
        default:
            return "Activity"
        }
    }
}

// MARK: - Supporting Views

struct ModernStatCard: View {
    let stat: StatData
    let isSelected: Bool
    let animateStats: Bool
    @State private var showValue = false
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(stat.color.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: stat.icon)
                    .font(.title2)
                    .foregroundColor(stat.color)
                    .scaleEffect(showValue ? 1.0 : 0.5)
                    .rotationEffect(.degrees(showValue ? 0 : -180))
            }
            
            Text(stat.title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(showValue ? stat.value : "0")
                .font(.title2.bold())
                .foregroundColor(.primary)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .onAppear {
            if animateStats {
                withAnimation(.spring().delay(0.3)) {
                    showValue = true
                }
            }
        }
    }
}

struct ModernActivityCard: View {
    let activity: APIUserActivity
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(Theme.Colors.primary.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: getActivityIcon(for: activity.type))
                            .foregroundColor(Theme.Colors.primary)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(getActivityTitle(for: activity.type))
                        .font(.subheadline.weight(.medium))
                    
                    Text(formatRelativeTime(from: activity.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Text(activity.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding()
        .frame(width: 250)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3)) {
                isHovered = hovering
            }
        }
    }
    
    private func getActivityIcon(for activityType: String) -> String {
        switch activityType {
        case "listing_created":
            return "plus.circle.fill"
        case "listing_viewed":
            return "eye.fill"
        case "listing_updated":
            return "pencil.circle.fill"
        case "listing_favorited":
            return "heart.fill"
        case "message_sent":
            return "message.fill"
        case "message_received":
            return "envelope.fill"
        case "review_posted":
            return "star.fill"
        case "review_received":
            return "star.circle.fill"
        case "payment_sent":
            return "creditcard.fill"
        case "payment_received":
            return "dollarsign.circle.fill"
        case "profile_viewed":
            return "person.crop.circle.fill"
        default:
            return "circle.fill"
        }
    }
    
    private func getActivityTitle(for activityType: String) -> String {
        switch activityType {
        case "listing_created":
            return "Listed Item"
        case "listing_viewed":
            return "Viewed Listing"
        case "listing_updated":
            return "Updated Listing"
        case "listing_favorited":
            return "Favorited"
        case "message_sent":
            return "Sent Message"
        case "message_received":
            return "New Message"
        case "review_posted":
            return "Posted Review"
        case "review_received":
            return "Received Review"
        case "payment_sent":
            return "Payment Sent"
        case "payment_received":
            return "Payment Received"
        case "profile_viewed":
            return "Profile View"
        default:
            return "Activity"
        }
    }
    
    private func formatTimeAgo(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: dateString) else {
            // Try without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            guard let date = formatter.date(from: dateString) else {
                return "Recently"
            }
            return formatRelativeTime(from: date)
        }
        
        return formatRelativeTime(from: date)
    }
    
    private func formatRelativeTime(from date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else if interval < 604800 {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }
}

struct QuickActionRow: View {
    let icon: String
    let title: String
    let color: Color
    @State private var isPressed = false
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(title)
                .font(.subheadline.weight(.medium))
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
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

struct ModernTimelineCard: View {
    let activity: APIUserActivity
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline indicator
            VStack(spacing: 0) {
                Circle()
                    .fill(Theme.Colors.primary)
                    .frame(width: 12, height: 12)
                
                Rectangle()
                    .fill(Theme.Colors.primary.opacity(0.3))
                    .frame(width: 2)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(activity.description)
                        .font(.subheadline.weight(.semibold))
                    
                    Spacer()
                    
                    Text(formatRelativeTime(from: activity.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let metadata = activity.metadata {
                    Text(getActivityDetail(from: metadata))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private func formatTimeAgo(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: dateString) else {
            formatter.formatOptions = [.withInternetDateTime]
            guard let date = formatter.date(from: dateString) else {
                return "Recently"
            }
            return formatRelativeTime(from: date)
        }
        
        return formatRelativeTime(from: date)
    }
    
    private func formatRelativeTime(from date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else if interval < 604800 {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }
    
    private func getActivityDetail(from metadata: [String: Any]) -> String {
        if let listingTitle = metadata["listing_title"] as? String {
            return "Item: \(listingTitle)"
        } else if let amount = metadata["amount"] as? Double {
            return String(format: "Amount: $%.2f", amount)
        } else if let message = metadata["message"] as? String {
            return message
        } else {
            return "View details"
        }
    }
}

struct DetailedStatCard: View {
    let title: String
    let value: String
    let trend: Trend
    let percentage: String
    
    enum Trend {
        case up, down, neutral
        
        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .neutral: return .blue
            }
        }
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "minus"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title.bold())
            
            HStack(spacing: 4) {
                Image(systemName: trend.icon)
                    .font(.caption.bold())
                
                Text(percentage)
                    .font(.caption.bold())
            }
            .foregroundColor(trend.color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }
}

struct ModernReviewCard: View {
    let index: Int
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("User \(index + 1)")
                        .font(.subheadline.weight(.semibold))
                    
                    HStack(spacing: 2) {
                        ForEach(0..<5) { star in
                            Image(systemName: star < 4 ? "star.fill" : "star")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        
                        Text("• 2 days ago")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text("Great experience! Would definitely recommend.")
                .font(.subheadline)
                .lineLimit(isExpanded ? nil : 2)
            
            if isExpanded {
                Text("The entire process was smooth and professional. Communication was excellent throughout.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Supporting Models

struct StatData {
    let title: String
    let value: String
    let icon: String
    let color: Color
}

struct ChartData: Identifiable {
    let id = UUID()
    let month: String
    let earnings: Double
}

// MARK: - View Model

class ModernProfileViewModel2: ObservableObject {
    @Published var displayName: String = "Loading..."
    @Published var username: String = ""
    @Published var avatarUrl: String?
    @Published var totalListings: Int = 0
    @Published var totalEarnings: Double = 0
    @Published var rating: Double = 0.0
    @Published var reviewCount: Int = 0
    @Published var isLoading = true
    @Published var userStats: APIUserStats?
    @Published var recentActivities: [APIUserActivity] = []
    @Published var userListings: [Listing] = []
    @Published var userReviews: [SocialUserReview] = []
    @Published var bio: String = ""
    
    private let apiClient = APIClient.shared
    
    var memberSince: String {
        guard let currentUser = AuthManager.shared.currentUser else {
            return "Unknown"
        }
        
        // Parse the ISO date string
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let createdAt = currentUser.createdAt, let date = isoFormatter.date(from: createdAt) {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM yyyy"
            return formatter.string(from: date)
        } else {
            // Try without fractional seconds
            isoFormatter.formatOptions = [.withInternetDateTime]
            if let createdAt = currentUser.createdAt, let date = isoFormatter.date(from: createdAt) {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM yyyy"
                return formatter.string(from: date)
            }
        }
        
        return "Unknown"
    }
    
    init() {
        loadUserData()
    }
    
    func loadUserData() {
        Task {
            await fetchUserProfile()
            await fetchUserStats()
            await fetchUserActivities()
            await fetchUserListings()
            await fetchUserReviews()
        }
    }
    
    @MainActor
    private func fetchUserProfile() async {
        guard let currentUser = AuthManager.shared.currentUser else {
            self.isLoading = false
            return
        }
        
        self.displayName = currentUser.username
        if self.displayName.isEmpty {
            self.displayName = currentUser.username
        }
        self.username = currentUser.username
        self.avatarUrl = currentUser.profilePicture
        self.bio = currentUser.bio ?? ""
    }
    
    @MainActor
    private func fetchUserStats() async {
        do {
            let stats = try await apiClient.getUserStats()
            self.userStats = stats
            self.totalListings = stats.activeListings ?? 0
            self.totalEarnings = Double(stats.totalEarnings)
            self.rating = stats.rating ?? 0
            self.reviewCount = Int(stats.rating ?? 0) // This should be review count from API
        } catch {
            print("Error fetching user stats: \(error)")
        }
    }
    
    @MainActor
    private func fetchUserActivities() async {
        guard let userId = AuthManager.shared.currentUser?.id else { return }
        
        do {
            let activities = try await apiClient.fetchUserActivities(userId: userId, limit: 10)
            self.recentActivities = activities
        } catch {
            print("Error fetching activities: \(error)")
        }
    }
    
    @MainActor
    private func fetchUserListings() async {
        guard let userApiId = AuthManager.shared.currentUser?.apiId else { 
            print("No user API ID available")
            return 
        }
        
        do {
            let response = try await apiClient.fetchUserListings(userId: userApiId)
            if response.success, let data = response.data {
                self.userListings = data.listings
                self.totalListings = data.listings.count
                print("✅ Fetched \(data.listings.count) user listings")
            } else {
                print("❌ Failed to fetch listings: \(response.message ?? "Unknown error")")
            }
        } catch {
            print("❌ Error fetching listings: \(error)")
        }
        
        self.isLoading = false
    }
    
    @MainActor
    private func fetchUserReviews() async {
        guard AuthManager.shared.currentUser?.id != nil else { return }
        
        // Fetch reviews when API endpoint is available
        // For now, we'll leave it empty
        self.userReviews = []
    }
}

// MARK: - Preview

struct ModernProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ModernProfileView()
            .environmentObject(AuthManager.shared)
    }
}