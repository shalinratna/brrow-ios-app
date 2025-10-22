//
//  UniversalProfileView.swift
//  Brrow
//
//  Universal profile view that works for both own profile and other users
//  Replaces: SocialProfileView, SimpleProfessionalProfileView, FullSellerProfileView
//

import SwiftUI
import Charts

struct UniversalProfileView: View {
    let user: User
    @StateObject private var viewModel: UniversalProfileViewModel
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedTab = 0
    @State private var showSettings = false
    @State private var showEditProfile = false
    @State private var showMessageComposer = false
    @State private var showWriteReview = false
    @State private var showAllReviews = false
    @State private var showIdentityVerification = false
    @State private var showReportUser = false
    @State private var animateContent = false
    @State private var showEmailBanner = true
    @State private var showIdentityBanner = true
    @State private var showChatDetail = false
    @State private var selectedConversation: Conversation?
    @State private var isCreatingChat = false
    @State private var canReview = false
    @State private var isCheckingReviewEligibility = false

    private let tabs = ["Listings", "Reviews", "Activity", "Stats"]

    /// Determine if this is the current user's own profile
    private var isOwnProfile: Bool {
        guard let currentUser = authManager.currentUser else { return false }
        return user.id == currentUser.id || user.apiId == currentUser.apiId
    }

    init(user: User) {
        self.user = user
        self._viewModel = StateObject(wrappedValue: UniversalProfileViewModel(user: user))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Verification Banners (own profile only)
                if isOwnProfile {
                    verificationBanners
                }

                // Profile Header
                profileHeader

                // Stats Section
                statsSection
                    .padding(.top, 20)

                // Tab Navigation
                tabNavigation
                    .padding(.top, 24)

                // Tab Content
                tabContent
                    .padding(.top, 20)

                // Bottom spacing
                Color.clear.frame(height: 100)
            }
        }
        .background(Theme.Colors.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isOwnProfile {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(Theme.Colors.text)
                    }
                } else {
                    Menu {
                        Button(action: { showMessageComposer = true }) {
                            Label("Send Message", systemImage: "message")
                        }
                        Button(action: { shareProfile() }) {
                            Label("Share Profile", systemImage: "square.and.arrow.up")
                        }
                        Button(action: { showReportUser = true }) {
                            Label("Report User", systemImage: "exclamationmark.triangle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(Theme.Colors.text)
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            ModernSettingsView()
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView(user: user)
        }
        .sheet(isPresented: $showMessageComposer) {
            DirectMessageComposerView(recipient: user)
        }
        .sheet(isPresented: $showWriteReview) {
            ReviewSubmissionView(
                reviewee: UserInfo(
                    id: user.id,
                    username: user.username,
                    profilePictureUrl: user.profilePicture,
                    averageRating: user.rating,
                    bio: user.bio,
                    totalRatings: user.totalReviews,
                    isVerified: user.idVerified,
                    createdAt: nil
                ),
                listing: nil,
                transaction: nil,
                reviewType: .general
            )
        }
        .sheet(isPresented: $showAllReviews) {
            NavigationView {
                ReviewsListView(revieweeId: user.id, reviewType: .user)
            }
        }
        .sheet(isPresented: $showIdentityVerification) {
            IdentityVerificationIntroView()
        }
        .sheet(isPresented: $showReportUser) {
            ReportUserView(user: user)
        }
        .sheet(isPresented: $showChatDetail) {
            if let conversation = selectedConversation {
                ChatDetailView(conversation: conversation)
            }
        }
        .onAppear {
            withAnimation {
                animateContent = true
            }
            viewModel.loadProfile()

            // Refresh own profile data
            if isOwnProfile {
                Task {
                    await authManager.refreshUserProfile()
                }
            } else {
                // Check if current user can review this profile
                Task {
                    await checkReviewEligibility()
                }
            }
        }
    }

    // MARK: - Verification Banners (Own Profile Only)
    private var verificationBanners: some View {
        VStack(spacing: 8) {
            // Email verification banner
            if authManager.currentUser?.emailVerified == false && showEmailBanner {
                EmailVerificationBanner(
                    onVerifyTapped: {
                        Task {
                            await sendEmailVerification()
                        }
                    },
                    onDismiss: {
                        showEmailBanner = false
                    }
                )
            }

            // Identity verification banner
            if authManager.currentUser?.emailVerified == true &&
               authManager.currentUser?.idVerified == false &&
               showIdentityBanner {
                IdentityVerificationBanner(
                    onDismiss: {
                        showIdentityBanner = false
                    }
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 20) {
            // Gradient background
            ZStack {
                LinearGradient(
                    colors: [
                        Theme.Colors.primary,
                        Theme.Colors.primary.opacity(0.8),
                        Theme.Colors.secondary.opacity(0.6)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 200)

                // Glassmorphism overlay
                Rectangle()
                    .fill(.white.opacity(0.08))
                    .frame(height: 200)
                    .background(.ultraThinMaterial)

                // Animated circles
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
                VStack(spacing: 16) {
                    // Profile Picture with glow
                    ZStack {
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

                        // Verified badge
                        if user.hasBlueCheckmark == true {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 28))
                                .foregroundColor(Theme.Colors.primary)
                                .background(Circle().fill(.white))
                                .offset(x: 40, y: 40)
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                    }

                    // Username and bio
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Text(user.displayName ?? user.username)
                                .font(.system(size: 28, weight: .heavy, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, .white.opacity(0.95)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)

                            if let badgeType = user.badgeType {
                                UserBadgeView(badgeType: badgeType, size: .large)
                            }
                        }

                        Text("@\(user.username)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))

                        if let bio = user.bio, !bio.isEmpty {
                            Text(bio)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.95))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .padding(.horizontal, 32)
                        }

                        // Member since badge
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

            // Action Buttons
            HStack(spacing: 14) {
                if isOwnProfile {
                    Button(action: { showEditProfile = true }) {
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
                    // Message button
                    Button(action: { openDirectChat() }) {
                        HStack(spacing: 6) {
                            if isCreatingChat {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "bubble.right.fill")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            Text(isCreatingChat ? "Opening Chat..." : "Message")
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
                        .opacity(isCreatingChat ? 0.7 : 1.0)
                    }
                    .disabled(isCreatingChat)

                    // Review button (only show if user is eligible to review)
                    if canReview {
                        Button(action: { showWriteReview = true }) {
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
            }
            .padding(.horizontal, 16)
            .offset(y: -35)
        }
        .offset(y: -20)
    }

    // MARK: - Stats Section
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
                                colors: [
                                    Theme.Colors.border.opacity(0.3),
                                    Theme.Colors.border.opacity(0.6),
                                    Theme.Colors.border.opacity(0.3)
                                ],
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
        .padding(.horizontal, 16)
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
                                .foregroundColor(
                                    selectedTab == index ? Theme.Colors.primary : Theme.Colors.secondaryText
                                )

                            Rectangle()
                                .fill(selectedTab == index ? Theme.Colors.primary : Color.clear)
                                .frame(height: 2)
                        }
                    }
                    .frame(minWidth: 80)
                }
            }
            .padding(.horizontal, 16)
        }
        .offset(y: -20)
    }

    // MARK: - Tab Content
    private var tabContent: some View {
        Group {
            switch selectedTab {
            case 0:
                userListings
            case 1:
                userReviews
            case 2:
                activityFeed
            case 3:
                userStats
            default:
                userListings
            }
        }
    }

    // MARK: - Listings Tab
    private var userListings: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 12
        ) {
            ForEach(viewModel.listings, id: \.listingId) { listing in
                NavigationLink(destination: ProfessionalListingDetailView(listing: listing)) {
                    ListingGridCard(listing: listing)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Reviews Tab
    private var userReviews: some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.reviews.prefix(5), id: \.id) { review in
                UniversalReviewCard(review: review)  // FIXED: Renamed to avoid conflict with SocialProfileView.ReviewCard
            }

            if viewModel.reviews.isEmpty {
                EmptyStateView(
                    title: "No Reviews Yet",
                    message: "Reviews from other users will appear here.",
                    systemImage: "star"
                )
            } else if viewModel.reviews.count > 5 {
                Button(action: { showAllReviews = true }) {
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
        .padding(.horizontal, 16)
    }

    // MARK: - Activity Feed Tab
    private var activityFeed: some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.activities, id: \.id) { activity in
                UniversalActivityCard(activity: activity)  // FIXED: Renamed to avoid conflict with SocialProfileView.ActivityCard
            }

            if viewModel.activities.isEmpty {
                EmptyStateView(
                    title: "No Activity Yet",
                    message: "Activity will appear here when you start borrowing and lending.",
                    systemImage: "clock"
                )
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Stats Tab
    private var userStats: some View {
        VStack(spacing: 16) {
            // Earnings/Activity Chart
            if #available(iOS 16.0, *) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(isOwnProfile ? "Monthly Earnings" : "Monthly Activity")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Theme.Colors.text)

                    Chart(viewModel.monthlyData, id: \.month) { data in
                        LineMark(
                            x: .value("Month", data.month),
                            y: .value("Amount", data.earnings)  // FIXED: MonthlyData has 'earnings' not 'amount'
                        )
                        .foregroundStyle(Theme.Colors.primary)
                        .symbol(Circle().strokeBorder(lineWidth: 2))

                        AreaMark(
                            x: .value("Month", data.month),
                            y: .value("Amount", data.earnings)  // FIXED: MonthlyData has 'earnings' not 'amount'
                        )
                        .foregroundStyle(Theme.Colors.primary.opacity(0.1))
                    }
                    .frame(height: 200)
                }
                .padding(16)
                .background(Theme.Colors.surface)
                .cornerRadius(12)
            }

            // Activity Breakdown
            VStack(alignment: .leading, spacing: 12) {
                Text("Activity Breakdown")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)

                VStack(spacing: 8) {
                    ForEach(viewModel.activityStats) { stat in  // FIXED: Use id from Identifiable
                        HStack {
                            Circle()
                                .fill(colorForActivityLabel(stat.label))  // FIXED: Use helper function for color
                                .frame(width: 12, height: 12)

                            Text(stat.label)  // FIXED: Use 'label' instead of 'type'
                                .font(.system(size: 14))
                                .foregroundColor(Theme.Colors.text)

                            Spacer()

                            Text("\(stat.value)")  // FIXED: Use 'value' instead of 'count'
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Theme.Colors.text)

                            // FIXED: Show trend indicator if available
                            if let trend = stat.trend {
                                Image(systemName: trendIcon(for: trend))
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(trendColor(for: trend))
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(Theme.Colors.surface)
            .cornerRadius(12)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Helper Functions
    private var memberSinceText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: Date())
    }

    private func sendEmailVerification() async {
        do {
            let response = try await APIClient.shared.sendEmailVerification()

            await MainActor.run {
                if response.alreadyVerified == true {
                    showEmailBanner = false
                    ToastManager.shared.showSuccess(
                        title: "Already Verified",
                        message: "Your email is already verified!"
                    )
                } else {
                    ToastManager.shared.showSuccess(
                        title: "Verification Email Sent",
                        message: "Check your inbox and click the verification link"
                    )
                }
            }
        } catch {
            await MainActor.run {
                ToastManager.shared.showError(
                    title: "Verification Failed",
                    message: "Failed to send verification email. Please try again."
                )
            }
        }
    }

    private func shareProfile() {
        // Share profile implementation
    }

    // MARK: - Helper Functions for ActivityStat Display

    /// Map activity label to color for visual consistency
    private func colorForActivityLabel(_ label: String) -> Color {
        switch label.lowercased() {
        case "views":
            return Color.blue
        case "saves", "favorites":
            return Color.orange
        case "messages":
            return Color.green
        case "rentals", "transactions":
            return Theme.Colors.primary
        case "reviews":
            return Color.purple
        default:
            return Theme.Colors.secondary
        }
    }

    /// Get SF Symbol icon name for trend direction
    private func trendIcon(for trend: String) -> String {
        switch trend.lowercased() {
        case "up":
            return "arrow.up.right"
        case "down":
            return "arrow.down.right"
        default:
            return "minus"
        }
    }

    /// Get color for trend indicator
    private func trendColor(for trend: String) -> Color {
        switch trend.lowercased() {
        case "up":
            return Color.green
        case "down":
            return Color.red
        default:
            return Color.gray
        }
    }

    // MARK: - Review Eligibility

    /// Check if the current user can review this profile user
    private func checkReviewEligibility() async {
        guard !isOwnProfile else {
            // Cannot review own profile
            await MainActor.run {
                canReview = false
            }
            return
        }

        let targetUserId = user.apiId ?? user.id

        await MainActor.run {
            isCheckingReviewEligibility = true
        }

        do {
            let response = try await ReviewService.shared.canReview(targetId: targetUserId, listingId: nil)

            await MainActor.run {
                canReview = response.canReview
                isCheckingReviewEligibility = false
                print("✅ [UniversalProfile] Review eligibility check: \(canReview ? "Can review" : "Cannot review")")
                if let reason = response.reason, !canReview {
                    print("ℹ️ [UniversalProfile] Reason: \(reason)")
                }
            }
        } catch {
            await MainActor.run {
                canReview = false
                isCheckingReviewEligibility = false
                print("❌ [UniversalProfile] Failed to check review eligibility: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Chat Navigation

    /// Create or get direct chat and navigate to it
    private func openDirectChat() {
        // Use apiId if available, otherwise use id
        let userId = user.apiId ?? user.id

        print("🔄 [UniversalProfile] Opening direct chat with user: \(user.username) (ID: \(userId))")

        isCreatingChat = true

        Task {
            do {
                // Use ChatService to create or get direct chat
                let chat = try await ChatService.shared.createOrGetDirectChat(with: userId, listingId: nil)

                await MainActor.run {
                    // Construct a simple Conversation from the User we already have
                    let conversationUser = ConversationUser(
                        id: user.apiId ?? user.id,
                        username: user.username,
                        displayName: user.displayName,
                        profilePicture: user.profilePicture,
                        hasBlueCheckmark: user.hasBlueCheckmark ?? false
                    )

                    let conversation = Conversation(
                        id: chat.id,
                        type: .direct,
                        otherUser: conversationUser,
                        lastMessage: nil,
                        unreadCount: 0,
                        updatedAt: ISO8601DateFormatter().string(from: Date()),
                        listing: nil,
                        listingId: nil,
                        isActive: true
                    )

                    self.selectedConversation = conversation
                    self.showChatDetail = true
                    self.isCreatingChat = false
                    print("✅ [UniversalProfile] Chat created/retrieved: \(chat.id)")
                }
            } catch {
                await MainActor.run {
                    self.isCreatingChat = false
                    print("❌ [UniversalProfile] Failed to create chat: \(error.localizedDescription)")
                    // Fallback to composer sheet if chat creation fails
                    self.showMessageComposer = true
                }
            }
        }
    }
}

// MARK: - Review Card Component
struct UniversalReviewCard: View {  // FIXED: Renamed to avoid conflict with SocialProfileView.ReviewCard
    let review: SocialUserReview

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Theme.Colors.primary.opacity(0.15),
                                    Theme.Colors.primary.opacity(0.05)
                                ],
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
                                    colors: [
                                        Theme.Colors.primary.opacity(0.3),
                                        Theme.Colors.primary.opacity(0.2)
                                    ],
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

// MARK: - Activity Card Component
struct UniversalActivityCard: View {  // FIXED: Renamed to avoid conflict with SocialProfileView.ActivityCard
    let activity: UserActivity

    // FIXED: Computed properties to handle both API activities (with type) and local activities (with icon/color)
    private var activityColor: Color {
        activity.color ?? activity.type?.color ?? Theme.Colors.primary
    }

    private var activityIcon: String {
        activity.icon ?? activity.type?.iconName ?? "circle.fill"
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                activityColor.opacity(0.15),
                                activityColor.opacity(0.25)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)

                Circle()
                    .strokeBorder(activityColor.opacity(0.3), lineWidth: 1)
                    .frame(width: 48, height: 48)

                Image(systemName: activityIcon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [activityColor, activityColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(activity.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)

                Text(activity.displaySubtitle)  // FIXED: Use displaySubtitle instead of description
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

// MARK: - Extensions
// NOTE: ActivityType extensions (iconName, color) are defined in SocialProfileView.swift
// They are shared globally and don't need to be redeclared here
