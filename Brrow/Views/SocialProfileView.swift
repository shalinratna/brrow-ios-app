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

    private let tabs = ["Activity", "Listings", "Reviews", "Stats"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Profile Header
                profileHeader
                
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
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Background gradient
            LinearGradient(
                colors: [Theme.Colors.primary, Theme.Colors.primary.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 200)
            .overlay(
                VStack {
                    HStack {
                        Spacer()
                        
                        Button(action: { showingSettings = true }) {
                            Image(systemName: "gearshape")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    
                    Spacer()
                }
            )
            .overlay(
                VStack(spacing: 12) {
                    // Profile picture
                    BrrowAsyncImage(url: user.fullProfilePictureURL ?? "") { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.white)
                            .overlay(
                                Text(String(user.username.prefix(1)).uppercased())
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(Theme.Colors.primary)
                            )
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    
                    VStack(spacing: 4) {
                        Text(user.username)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        if let bio = viewModel.userProfile?.bio {
                            Text(bio)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        
                        // Member since
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 12))
                            Text("Member since \(memberSinceText)")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.white.opacity(0.8))
                    }
                },
                alignment: .center
            )
            
            // Action buttons
            HStack(spacing: 16) {
                if user.id == AuthManager.shared.currentUser?.id {
                    Button(action: { showingEditProfile = true }) {
                        Text("Edit Profile")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Theme.Colors.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .cornerRadius(20)
                    }
                } else {
                    Button(action: { /* Message user */ }) {
                        Text("Message")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Theme.Colors.primary)
                            .cornerRadius(20)
                    }

                    Button(action: { showingWriteReview = true }) {
                        Text("Write Review")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Theme.Colors.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Theme.Colors.primary, lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .offset(y: -30)
        }
        .offset(y: -20)
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        HStack(spacing: 0) {
            ForEach(Array(viewModel.stats.enumerated()), id: \.offset) { index, stat in
                VStack(spacing: 4) {
                    Text("\(stat.value)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Theme.Colors.text)
                    
                    Text(stat.title)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                .frame(maxWidth: .infinity)
                
                if index < viewModel.stats.count - 1 {
                    Rectangle()
                        .fill(Theme.Colors.border)
                        .frame(width: 1, height: 30)
                }
            }
        }
        .padding(.vertical, Theme.Spacing.lg)
        .background(Theme.Colors.surface)
        .cornerRadius(Theme.CornerRadius.card)
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

// MARK: - Activity Card
struct ActivityCard: View {
    let activity: UserActivity
    
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Activity icon
            Circle()
                .fill(activity.type.color.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: activity.type.iconName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(activity.type.color)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.text)
                
                Text(activity.description)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.secondaryText)
                    .lineLimit(2)
                
                Text(activity.timeAgo)
                    .font(.system(size: 10))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            
            Spacer()
            
            if let amount = activity.amount {
                Text(amount)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.Colors.primary)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface)
        .cornerRadius(Theme.CornerRadius.card)
    }
}

// MARK: - Review Card
struct ReviewCard: View {
    let review: SocialUserReview
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                BrrowAsyncImage(url: review.reviewerProfilePicture) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Theme.Colors.primary.opacity(0.2))
                        .overlay(
                            Text(String(review.reviewerName.prefix(1)).uppercased())
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Theme.Colors.primary)
                        )
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(review.reviewerName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.Colors.text)
                    
                    HStack(spacing: 2) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < review.rating ? "star.fill" : "star")
                                .font(.system(size: 10))
                                .foregroundColor(index < review.rating ? .yellow : Theme.Colors.border)
                        }
                    }
                }
                
                Spacer()
                
                Text(review.timeAgo)
                    .font(.system(size: 10))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            
            Text(review.comment)
                .font(.system(size: 12))
                .foregroundColor(Theme.Colors.text)
                .lineLimit(nil)
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface)
        .cornerRadius(Theme.CornerRadius.card)
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

