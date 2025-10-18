//
//  SocialProfileView.swift
//  Brrow
//
//  Complete Social Profile with Activity Feed
//

import SwiftUI
import Charts

struct SocialProfileView: View {
    let user: User
    @StateObject private var viewModel = SocialProfileViewModel()
    @State private var selectedTab = 0
    @State private var showingSettings = false
    @State private var showingEditProfile = false
    @State private var showingWriteReview = false
    @State private var showingAllReviews = false

    // Verification banner states
    @ObservedObject private var authManager = AuthenticationManager.shared
    @State private var showEmailBanner = true
    @State private var showIDmeBanner = true
    @State private var showIDmeVerification = false

    private let tabs = ["Activity", "Listings", "Reviews", "Stats"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Profile Header
                profileHeader

                // Verification Banners - Only show on own profile
                if user.id == authManager.currentUser?.id {
                    // Priority 1: Email verification (if not email verified)
                    if authManager.isAuthenticated,
                       let currentUser = authManager.currentUser,
                       currentUser.emailVerified == false,
                       showEmailBanner {
                        EmailVerificationBanner(
                            onVerifyTapped: {
                                Task {
                                    do {
                                        try await APIClient.shared.sendEmailVerification()
                                        ToastManager.shared.showSuccess(
                                            title: "Verification Email Sent",
                                            message: "Check your inbox and verify your email"
                                        )
                                    } catch {
                                        ToastManager.shared.showError(
                                            title: "Error",
                                            message: "Failed to send verification email. Please try again."
                                        )
                                        print("❌ Email verification error: \(error)")
                                    }
                                }
                            },
                            onDismiss: {
                                showEmailBanner = false
                            }
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 8)
                    }

                    // Priority 2: ID.me verification (if email verified but not ID.me verified)
                    if authManager.isAuthenticated,
                       let currentUser = authManager.currentUser,
                       currentUser.emailVerified == true,
                       currentUser.idVerified == false,
                       showIDmeBanner {
                        IDmeVerificationBanner(
                            onVerifyTapped: {
                                showIDmeVerification = true
                            },
                            onDismiss: {
                                showIDmeBanner = false
                            }
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 8)
                    }
                }

                // Stats Section
                statsSection
                
                // Tab Navigation
                tabNavigation
                
                // Tab Content
                tabContent
            }
        }
        .background(Theme.Colors.background)
        .navigationTitle(user.username)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape.fill")
                }
            }
        }
        .onAppear {
            // Convert String id to Int for the API call
            if let userId = Int(user.id) {
                viewModel.loadUserProfile(userId: userId)
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView(user: user)
        }
        .sheet(isPresented: $showingSettings) {
            ModernSettingsView()
                .environmentObject(AuthManager.shared)
        }
        .sheet(isPresented: $showingWriteReview) {
            ReviewSubmissionView(
                reviewee: UserInfo(
                    id: user.id,
                    username: user.username,
                    profilePictureUrl: user.profilePicture,
                    averageRating: user.rating,
                    bio: viewModel.userProfile?.bio,
                    totalRatings: user.totalReviews,
                    isVerified: user.idVerified,
                    createdAt: nil
                ),
                listing: nil,
                transaction: nil,
                reviewType: .general
            )
        }
        .sheet(isPresented: $showingAllReviews) {
            NavigationView {
                ReviewsListView(revieweeId: user.id, reviewType: .user)
            }
        }
        .sheet(isPresented: $showIDmeVerification) {
            NavigationView {
                IDmeVerificationView(onVerificationComplete: {
                    showIDmeVerification = false
                    showIDmeBanner = false
                    // Refresh user data to get updated verification status
                    Task {
                        await authManager.refreshUserData()
                    }
                })
            }
        }
    }
    
    // MARK: - Profile Header (Enhanced with Glassmorphism)
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // ✨ Modern animated gradient background
            ZStack {
                // Animated gradient mesh
                LinearGradient(
                    colors: [
                        Theme.Colors.primary,
                        Theme.Colors.primary.opacity(0.8),
                        Theme.Colors.secondary.opacity(0.6)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 240)

                // ✨ Glassmorphism overlay
                Rectangle()
                    .fill(.white.opacity(0.08))
                    .frame(height: 240)
                    .background(.ultraThinMaterial)

                // Animated circles for depth
                Circle()
                    .fill(.white.opacity(0.1))
                    .frame(width: 150, height: 150)
                    .offset(x: -80, y: -40)
                    .blur(radius: 30)

                Circle()
                    .fill(.white.opacity(0.08))
                    .frame(width: 180, height: 180)
                    .offset(x: 100, y: 30)
                    .blur(radius: 40)
            }
            .overlay(
                VStack {
                    HStack {
                        Spacer()

                        // ✨ Glassmorphic settings button
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showingSettings = true
                            }
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(.white.opacity(0.2))
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                        }
                    }
                    .padding()

                    Spacer()
                }
            )
            .overlay(
                VStack(spacing: 16) {
                    // ✨ Enhanced profile picture with glow
                    ZStack {
                        // Glow effect
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [.white.opacity(0.3), .clear],
                                    center: .center,
                                    startRadius: 50,
                                    endRadius: 70
                                )
                            )
                            .frame(width: 140, height: 140)
                            .blur(radius: 10)

                        BrrowAsyncImage(url: user.fullProfilePictureURL ?? "") { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.white, .white.opacity(0.9)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    Text(String(user.username.prefix(1)).uppercased())
                                        .font(.system(size: 38, weight: .bold))
                                        .foregroundColor(Theme.Colors.primary)
                                )
                        }
                        .frame(width: 110, height: 110)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [.white, .white.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 5
                                )
                        )
                        .shadow(color: .black.opacity(0.25), radius: 15, x: 0, y: 8)

                        // ✨ Verified badge
                        if user.idVerified == true {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 28))
                                .foregroundColor(Theme.Colors.primary)
                                .background(Circle().fill(.white))
                                .offset(x: 40, y: 40)
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                    }

                    VStack(spacing: 8) {
                        // Username with enhanced typography
                        Text(user.username)
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .white.opacity(0.95)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)

                        if let bio = viewModel.userProfile?.bio {
                            Text(bio)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.95))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .padding(.horizontal, 32)
                        }

                        // ✨ Enhanced member badge
                        HStack(spacing: 6) {
                            Image(systemName: "calendar.badge.checkmark")
                                .font(.system(size: 11, weight: .semibold))
                            Text("Member since \(memberSinceText)")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.15))
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                    }
                },
                alignment: .center
            )

            // ✨ Enhanced action buttons with glassmorphism
            HStack(spacing: 14) {
                if user.id == AuthManager.shared.currentUser?.id {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showingEditProfile = true
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "pencil")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Edit Profile")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundColor(Theme.Colors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.white)
                        .cornerRadius(16)
                        .shadow(color: Theme.Colors.primary.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                } else {
                    Button(action: { /* Message user */ }) {
                        HStack(spacing: 6) {
                            Image(systemName: "bubble.right.fill")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Message")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Theme.Colors.primary, Theme.Colors.primary.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: Theme.Colors.primary.opacity(0.4), radius: 12, x: 0, y: 6)
                    }

                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showingWriteReview = true
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Review")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundColor(Theme.Colors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.white)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: [Theme.Colors.primary, Theme.Colors.primary.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: Theme.Colors.primary.opacity(0.15), radius: 8, x: 0, y: 4)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .offset(y: -35)
        }
        .offset(y: -20)
    }
    
    // MARK: - Stats Section (Enhanced with Glassmorphism)
    private var statsSection: some View {
        HStack(spacing: 0) {
            ForEach(Array(viewModel.stats.enumerated()), id: \.offset) { index, stat in
                VStack(spacing: 6) {
                    Text("\(stat.value)")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Theme.Colors.primary, Theme.Colors.primary.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text(stat.title)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.Colors.secondaryText)
                        .textCase(.uppercase)
                        .tracking(0.5)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)

                if index < viewModel.stats.count - 1 {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Theme.Colors.border.opacity(0.3), Theme.Colors.border.opacity(0.6), Theme.Colors.border.opacity(0.3)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 1, height: 40)
                }
            }
        }
        .padding(.vertical, 20)
        .background(.white.opacity(0.05))
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.08), radius: 15, x: 0, y: 8)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.3), .white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .padding(.horizontal, Theme.Spacing.lg)
        .offset(y: -40)
    }
    
    // MARK: - Tab Navigation
    private var tabNavigation: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedTab = index
                        }
                    }) {
                        VStack(spacing: 8) {
                            Text(tab)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(selectedTab == index ? Theme.Colors.primary : Theme.Colors.secondaryText)
                            
                            Rectangle()
                                .fill(selectedTab == index ? Theme.Colors.primary : Color.clear)
                                .frame(height: 2)
                        }
                    }
                    .frame(minWidth: 80)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
        }
        .offset(y: -20)
    }
    
    // MARK: - Tab Content
    private var tabContent: some View {
        Group {
            switch selectedTab {
            case 0:
                activityFeed
            case 1:
                userListings
            case 2:
                userReviews
            case 3:
                userStats
            default:
                activityFeed
            }
        }
        .padding(.top, Theme.Spacing.md)
    }
    
    // MARK: - Activity Feed
    private var activityFeed: some View {
        LazyVStack(spacing: Theme.Spacing.md) {
            ForEach(viewModel.activities, id: \.id) { activity in
                ActivityCard(activity: activity)
            }
            
            if viewModel.activities.isEmpty {
                EmptyStateView(
                    title: "No Activity Yet",
                    message: "Activity will appear here when you start borrowing and lending.",
                    systemImage: "clock"
                )
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }
    
    // MARK: - User Listings
    private var userListings: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: Theme.Spacing.md) {
            ForEach(viewModel.userListings, id: \.id) { listing in
                ListingGridCard(listing: listing)
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }
    
    // MARK: - User Reviews
    private var userReviews: some View {
        LazyVStack(spacing: Theme.Spacing.md) {
            ForEach(viewModel.reviews, id: \.id) { review in
                ReviewCard(review: review)
            }

            if viewModel.reviews.isEmpty {
                EmptyStateView(
                    title: "No Reviews Yet",
                    message: "Reviews from other users will appear here.",
                    systemImage: "star"
                )
            } else if viewModel.reviews.count > 3 {
                // Show "View All Reviews" button if more than 3 reviews
                Button(action: { showingAllReviews = true }) {
                    Text("View All Reviews")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Theme.Colors.primary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.Colors.primary.opacity(0.1))
                        .cornerRadius(12)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }
    
    // MARK: - User Stats
    private var userStats: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Earnings Chart
            if #available(iOS 16.0, *) {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    Text("Monthly Earnings")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Theme.Colors.text)
                    
                    Chart(viewModel.monthlyEarnings, id: \.month) { data in
                        LineMark(
                            x: .value("Month", data.month),
                            y: .value("Earnings", data.amount)
                        )
                        .foregroundStyle(Theme.Colors.primary)
                        .symbol(Circle().strokeBorder(lineWidth: 2))
                        
                        AreaMark(
                            x: .value("Month", data.month),
                            y: .value("Earnings", data.amount)
                        )
                        .foregroundStyle(Theme.Colors.primary.opacity(0.1))
                    }
                    .frame(height: 200)
                }
                .padding(Theme.Spacing.lg)
                .background(Theme.Colors.surface)
                .cornerRadius(Theme.CornerRadius.card)
            }
            
            // Activity Stats
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text("Activity Breakdown")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
                
                VStack(spacing: Theme.Spacing.sm) {
                    ForEach(viewModel.activityStats, id: \.type) { stat in
                        HStack {
                            Circle()
                                .fill(stat.color)
                                .frame(width: 12, height: 12)
                            
                            Text(stat.type)
                                .font(.system(size: 14))
                                .foregroundColor(Theme.Colors.text)
                            
                            Spacer()
                            
                            Text("\(stat.count)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Theme.Colors.text)
                        }
                    }
                }
            }
            .padding(Theme.Spacing.lg)
            .background(Theme.Colors.surface)
            .cornerRadius(Theme.CornerRadius.card)
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }
    
    private var memberSinceText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: Date())
    }
}

// MARK: - Activity Card (Enhanced with Glassmorphism)
struct ActivityCard: View {
    let activity: UserActivity

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // ✨ Enhanced activity icon with gradient
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [activity.type.color.opacity(0.15), activity.type.color.opacity(0.25)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)

                Circle()
                    .strokeBorder(activity.type.color.opacity(0.3), lineWidth: 1)
                    .frame(width: 48, height: 48)

                Image(systemName: activity.type.iconName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [activity.type.color, activity.type.color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(activity.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)

                Text(activity.description)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Theme.Colors.secondaryText)
                    .lineLimit(2)

                Text(activity.timeAgo)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.Colors.tertiaryText)
            }

            Spacer()

            if let amount = activity.amount {
                Text(amount)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.Colors.primary, Theme.Colors.primary.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.05))
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
            }
        }
        .padding(16)
        .background(.white.opacity(0.03))
        .background(.ultraThinMaterial)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.2), .white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Review Card (Enhanced with Glassmorphism)
struct ReviewCard: View {
    let review: SocialUserReview

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                // ✨ Enhanced profile picture
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Theme.Colors.primary.opacity(0.15), Theme.Colors.primary.opacity(0.05)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 20
                            )
                        )
                        .frame(width: 42, height: 42)

                    BrrowAsyncImage(url: review.reviewerProfilePicture) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Theme.Colors.primary.opacity(0.3), Theme.Colors.primary.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Text(String(review.reviewerName.prefix(1)).uppercased())
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Theme.Colors.primary)
                            )
                    }
                    .frame(width: 38, height: 38)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.white.opacity(0.4), .white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(review.reviewerName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.Colors.text)

                    // ✨ Enhanced star rating
                    HStack(spacing: 3) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < review.rating ? "star.fill" : "star")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(
                                    index < review.rating ?
                                        LinearGradient(
                                            colors: [.yellow, .orange],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ) :
                                        LinearGradient(
                                            colors: [Theme.Colors.border, Theme.Colors.border],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                )
                        }
                    }
                }

                Spacer()

                // ✨ Time badge
                Text(review.timeAgo)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.Colors.tertiaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.05))
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
            }

            Text(review.comment)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Theme.Colors.text)
                .lineLimit(nil)
                .lineSpacing(2)
        }
        .padding(16)
        .background(.white.opacity(0.03))
        .background(.ultraThinMaterial)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.2), .white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Supporting Models

// MARK: - Extensions for ProfileModels types

extension UserActivity.ActivityType {
    var iconName: String {
        switch self {
        case .borrowed: return "arrow.down.circle"
        case .lent: return "arrow.up.circle"
        case .earned: return "dollarsign.circle"
        case .reviewed: return "star.circle"
        case .listed: return "tag.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .borrowed: return .blue
        case .lent: return .green
        case .earned: return Theme.Colors.primary
        case .reviewed: return .orange
        case .listed: return Theme.Colors.secondary
        }
    }
}

