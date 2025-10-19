//
//  SimpleProfessionalProfileView.swift
//  Brrow
//
//  Clean professional profile with green/white theme
//

import SwiftUI

struct SimpleProfessionalProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = ProfileViewModel()
    @StateObject private var idmeService = IDmeService.shared
    @State private var showSettings = false
    @State private var animateContent = false
    @State private var showProfilePictureEdit = false
    @State private var showIDmeVerification = false
    @State private var showEmailVerificationBanner = true
    @State private var showIDmeTest = false
    @State private var showingMyPosts = false
    @State private var showingOffers = false
    @State private var showingSavedItems = false
    @State private var showingTransactions = false
    @State private var selectedPurchaseId: String? = nil

    // Show email verification banner if user is not verified and banner hasn't been dismissed
    private var shouldShowEmailBanner: Bool {
        showEmailVerificationBanner &&
        !(viewModel.user?.isVerified ?? false) &&  // FIXED: Check isVerified field from API
        !idmeService.isVerified &&
        !authManager.isGuestUser
    }

    // Show ID.me banner if email is verified but ID.me is not
    private var shouldShowIDmeBanner: Bool {
        (viewModel.user?.isVerified ?? false) &&  // Email is verified
        !idmeService.isVerified &&  // But ID.me is not
        !authManager.isGuestUser
    }
    
    var body: some View {
        ZStack {
                // Clean background
                Theme.Colors.background
                    .ignoresSafeArea()
                
                if authManager.isGuestUser {
                    // Guest user view
                    guestUserView
                } else {
                    // Regular user view
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                        // Email Verification Banner (show if email NOT verified)
                        if shouldShowEmailBanner {
                            EmailVerificationBanner(
                                onVerifyTapped: {
                                    Task {
                                        await sendEmailVerification()
                                    }
                                },
                                onDismiss: {
                                    showEmailVerificationBanner = false
                                }
                            )
                            .padding(.top, 8)
                        }

                        // ID.me Verification Banner (show if email IS verified but ID.me is NOT)
                        if shouldShowIDmeBanner {
                            IDmeVerificationBanner(
                                onVerifyTapped: {
                                    showIDmeVerification = true
                                },
                                onDismiss: {
                                    // User dismissed ID.me banner
                                }
                            )
                            .padding(.top, 8)
                        }

                        // Header
                        headerSection
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.top, 10)
                            .onLongPressGesture {
                                // Debug: Long press to show ID.me test view
                                #if DEBUG
                                showIDmeTest = true
                                #endif
                            }
                        
                        // Profile Info
                        profileSection
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.top, Theme.Spacing.lg)
                        
                        // Stats Grid
                        statsGrid
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.top, Theme.Spacing.xl)
                        
                        // Menu Options
                        menuOptions
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.top, Theme.Spacing.xl)
                        
                        // Bottom padding
                        Color.clear.frame(height: 100)
                    }
                }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showSettings) {
                ModernSettingsView()
                    .environmentObject(authManager)
            }
            .sheet(isPresented: $showProfilePictureEdit) {
                ProfilePictureEditView()
            }
            .sheet(isPresented: $showIDmeVerification) {
                IDmeVerificationView()
            }
            // .sheet(isPresented: $showIDmeTest) {
            //     IDmeTestView()
            // }
            .sheet(isPresented: $showingMyPosts) {
                EnhancedMyPostsView()
            }
            .sheet(isPresented: $showingOffers) {
                EnhancedOffersView()
            }
            .sheet(isPresented: $showingSavedItems) {
                EnhancedSavedItemsView()
            }
            .sheet(isPresented: $showingTransactions) {
                NavigationView {
                    if let purchaseId = selectedPurchaseId {
                        // Direct navigation to specific transaction
                        TransactionDetailView(purchaseId: purchaseId)
                            .onDisappear {
                                selectedPurchaseId = nil
                            }
                    } else {
                        // Show transactions list
                        TransactionsListView()
                    }
                }
            }
            .onAppear {
                withAnimation {
                    animateContent = true
                }

                // Refresh user profile every time view appears to get latest data
                print("🔄 SimpleProfessionalProfileView: View appeared, refreshing profile")
                viewModel.loadUserProfile()

                // Track achievement for profile completion check
                if let user = viewModel.user, !(user.bio?.isEmpty ?? true) && user.profilePicture != nil {
                    AchievementManager.shared.trackProfileCompleted()
                }

            }
            .onReceive(NotificationCenter.default.publisher(for: .navigateToMyPosts)) { _ in
                showingMyPosts = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .openTransactions)) { notification in
                print("🔔 [Profile] Received openTransactions notification")

                // Extract purchaseId if provided
                if let userInfo = notification.userInfo,
                   let purchaseId = userInfo["purchaseId"] as? String {
                    print("💰 [Profile] Opening transaction detail for: \(purchaseId)")
                    selectedPurchaseId = purchaseId
                } else {
                    print("📋 [Profile] Opening transactions list")
                    selectedPurchaseId = nil
                }

                showingTransactions = true
            }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Text(LocalizationHelper.localizedString("profile"))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Theme.Colors.text)
            
            Spacer()
            
            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Theme.Colors.text)
                    .frame(width: 44, height: 44)
                    .background(Theme.Colors.secondaryBackground)
                    .clipShape(Circle())
            }
        }
    }
    
    // MARK: - Profile Section
    private var profileSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Profile Image
            ZStack {
                Circle()
                    .fill(Theme.Colors.primary.opacity(0.1))
                    .frame(width: 100, height: 100)

                if let user = viewModel.user, let profilePictureURL = user.fullProfilePictureURL, !profilePictureURL.isEmpty {
                    BrrowAsyncImage(url: profilePictureURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ProgressView()
                            .scaleEffect(0.5)
                    }
                    .frame(width: 90, height: 90)
                    .clipShape(Circle())
                    .id(profilePictureURL) // Force re-render when URL changes
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Theme.Colors.primary)
                }

                // Camera Edit Button
                Button(action: { showProfilePictureEdit = true }) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Theme.Colors.primary)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                }
                .offset(x: 35, y: 35)
            }
            .opacity(animateContent ? 1 : 0)
            .scaleEffect(animateContent ? 1 : 0.8)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: animateContent)
            
            // User Info
            VStack(spacing: 8) {
                // Display name (or username as fallback) with badge
                HStack(spacing: 8) {
                    Text(viewModel.user?.displayName ?? viewModel.user?.username ?? "Loading...")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(Theme.Colors.text)

                    // Badge
                    if let badgeType = viewModel.user?.badgeType {
                        UserBadgeView(badgeType: badgeType, size: .large)
                    }
                }

                Text("@\(viewModel.user?.username ?? "")")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.Colors.secondaryText)
                
                // Rating
                if let user = viewModel.user {
                    let listerRating = user.listerRating ?? 0
                    let renteeRating = user.renteeRating ?? 0
                    let averageRating = listerRating == 0 && renteeRating == 0 ? 0 : Double((listerRating + renteeRating) / 2.0)
                    let validRating = averageRating.isNaN || averageRating.isInfinite ? 0 : averageRating
                    let fullStars = Int(validRating)
                    let hasHalfStar = validRating - Double(fullStars) >= 0.5
                    
                    HStack(spacing: 6) {
                        ForEach(0..<5) { index in
                            if index < fullStars {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(Theme.Colors.accentOrange)
                            } else if index == fullStars && hasHalfStar {
                                Image(systemName: "star.lefthalf.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(Theme.Colors.accentOrange)
                            } else {
                                Image(systemName: "star")
                                    .font(.system(size: 14))
                                    .foregroundColor(Theme.Colors.accentOrange)
                            }
                        }
                        
                        Text(String(format: "%.1f", averageRating))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.Colors.text)
                        
                        if viewModel.reviewCount > 0 {
                            Text("(\(viewModel.reviewCount))")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                    }
                }
            }
            .opacity(animateContent ? 1 : 0)
            .offset(y: animateContent ? 0 : 20)
            .animation(.easeOut(duration: 0.6).delay(0.1), value: animateContent)

            // Bio Section (Instagram-style)
            if let bio = viewModel.user?.bio, !bio.isEmpty {
                Text(bio)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#8E8E8E") ?? Theme.Colors.secondaryText)
                    .lineLimit(3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.15), value: animateContent)
            }

            // Edit Profile Button
            Group {
                if let user = viewModel.user {
                    NavigationLink(destination: EditProfileView(user: user)) {
                        Text(LocalizationHelper.localizedString("edit_profile"))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Theme.Colors.primary)
                            .cornerRadius(12)
                    }
                } else {
                    Button(action: {}) {
                        Text(LocalizationHelper.localizedString("edit_profile"))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Theme.Colors.primary)
                            .cornerRadius(12)
                    }
                }
            }
            .opacity(animateContent ? 1 : 0)
            .offset(y: animateContent ? 0 : 20)
            .animation(.easeOut(duration: 0.6).delay(0.2), value: animateContent)
        }
    }
    
    // MARK: - Stats Grid
    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            Button(action: { showingMyPosts = true }) {
                ProfileStatBox(
                    title: LocalizationHelper.localizedString("active_listings"),
                    value: "\(viewModel.userListings.filter { $0.status == "active" }.count)",
                    icon: "tag.fill",
                    color: Theme.Colors.primary
                )
            }
            .buttonStyle(PlainButtonStyle())
            .opacity(animateContent ? 1 : 0)
            .scaleEffect(animateContent ? 1 : 0.9)
            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3), value: animateContent)
            
            ProfileStatBox(
                title: LocalizationHelper.localizedString("total_reviews"),
                value: "\(viewModel.reviewCount)",
                icon: "star.fill",
                color: Theme.Colors.accentOrange
            )
            .opacity(animateContent ? 1 : 0)
            .scaleEffect(animateContent ? 1 : 0.9)
            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.35), value: animateContent)
            
            ProfileStatBox(
                title: LocalizationHelper.localizedString("lister_rating"),
                value: String(format: "%.1f", viewModel.user?.listerRating ?? 0.0),
                icon: "star.fill",
                color: Theme.Colors.accentBlue
            )
            .opacity(animateContent ? 1 : 0)
            .scaleEffect(animateContent ? 1 : 0.9)
            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4), value: animateContent)
            
            ProfileStatBox(
                title: LocalizationHelper.localizedString("rentee_rating"),
                value: String(format: "%.1f", viewModel.user?.renteeRating ?? 0.0),
                icon: "person.fill",
                color: Theme.Colors.success
            )
            .opacity(animateContent ? 1 : 0)
            .scaleEffect(animateContent ? 1 : 0.9)
            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.45), value: animateContent)
        }
    }
    
    // MARK: - Email Verification
    private func sendEmailVerification() async {
        print("📧 [PROFILE] sendEmailVerification() called")
        print("📧 [PROFILE] Current auth token exists: \(AuthManager.shared.authToken != nil)")

        do {
            print("📧 [PROFILE] Calling APIClient.sendEmailVerification()...")
            let response = try await APIClient.shared.sendEmailVerification()
            print("📧 [PROFILE] API call succeeded, response: \(response)")

            await MainActor.run {
                if response.alreadyVerified == true {
                    print("📧 [PROFILE] Email already verified")
                    showEmailVerificationBanner = false
                    ToastManager.shared.showSuccess(
                        title: "Already Verified",
                        message: "Your email is already verified!"
                    )
                } else {
                    print("📧 [PROFILE] Verification email sent")
                    ToastManager.shared.showSuccess(
                        title: "Verification Email Sent",
                        message: "Check your inbox and click the verification link"
                    )
                }
            }
        } catch {
            print("❌ [PROFILE] Email verification failed with error: \(error)")
            print("❌ [PROFILE] Error type: \(type(of: error))")
            print("❌ [PROFILE] Error description: \(error.localizedDescription)")

            await MainActor.run {
                ToastManager.shared.showError(
                    title: "Verification Failed",
                    message: "Failed to send verification email. Please try again."
                )
            }
        }
    }
    
    // MARK: - Menu Options
    private var menuOptions: some View {
        VStack(spacing: 12) {
            #if DEBUG
            // Debug button for testing
            if !authManager.isAuthenticated {
                Button(action: {
                    AuthManager.shared.simulateLoginForTesting()
                }) {
                    HStack {
                        Image(systemName: "ladybug.fill")
                            .foregroundColor(.orange)
                        Text("DEBUG: Login as Test User")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding(8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            #endif
            
            Button(action: { showingMyPosts = true }) {
                ProfileMenuRow(
                    icon: "folder.fill",
                    title: "My Posts"
                )
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: { showingTransactions = true }) {
                ProfileMenuRow(
                    icon: "cart.fill",
                    title: "Transactions"
                )
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: { showingOffers = true }) {
                ProfileMenuRow(
                    icon: "clock.fill",
                    title: LocalizationHelper.localizedString("rental_history")
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            NavigationLink(destination: PostsAnalyticsView(posts: viewModel.userPosts)) {
                ProfileMenuRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: LocalizationHelper.localizedString("analytics")
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: { showingSavedItems = true }) {
                ProfileMenuRow(
                    icon: "heart.fill",
                    title: LocalizationHelper.localizedString("saved_items")
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            NavigationLink(destination: PushNotificationSettingsView()) {
                ProfileMenuRow(
                    icon: "bell.fill",
                    title: LocalizationHelper.localizedString("notifications")
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // ID.me Identity Verification
            Button(action: { showIDmeVerification = true }) {
                ProfileMenuRow(
                    icon: "checkmark.shield.fill",
                    title: "Identity Verification",
                    badge: authManager.currentUser?.idVerified == true ? "Verified" : "Verify Now"
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            
            // Business Account (if business user) - TEMPORARILY HIDDEN
            /*
            if authManager.currentUser?.accountType == "business" {
                NavigationLink(destination: BusinessAccountView()) {
                    ProfileMenuRow(
                        icon: "building.2.fill",
                        title: LocalizationHelper.localizedString("business_account")
                    )
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                // Create Business Account (for personal users)
                NavigationLink(destination: BusinessAccountCreationView(showingAccountTypeSelection: .constant(false))) {
                    ProfileMenuRow(
                        icon: "building.2.fill",
                        title: "Create Business Account",
                        badge: "New"
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            */

            // Achievements - TEMPORARILY HIDDEN
            /*
            NavigationLink(destination: AchievementsView()) {
                ProfileMenuRow(
                    icon: "trophy.fill",
                    title: LocalizationHelper.localizedString("achievements")
                )
            }
            .buttonStyle(PlainButtonStyle())
            */
            
            // Borrow vs Buy Calculator - Removed (requires listing context)
            
            NavigationLink(destination: LanguageSettingsView()) {
                ProfileMenuRow(
                    icon: "globe",
                    title: LocalizationHelper.localizedString("language")
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            NavigationLink(destination: AboutBrrowView()) {
                ProfileMenuRow(
                    icon: "questionmark.circle.fill",
                    title: LocalizationHelper.localizedString("help_support")
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Version and Build Number
            Text("Brrow \(getAppVersion()) (\(getBuildNumber()))")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.Colors.secondaryText)
                .padding(.top, 20)
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(.easeOut(duration: 0.6).delay(0.5), value: animateContent)
    }
    
    // MARK: - Guest User View
    private var guestUserView: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()
            
            // Icon
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 80))
                .foregroundColor(Theme.Colors.primary)
                .padding(.bottom, Theme.Spacing.md)
            
            // Title
            Text("Sign In to Access Your Profile")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(Theme.Colors.text)
                .multilineTextAlignment(.center)
            
            // Description
            Text("Create an account to save favorites, post items, send messages, and track your activity.")
                .font(.system(size: 16))
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xl)
            
            // Sign In Button
            Button(action: {
                AuthManager.shared.logout()
            }) {
                Text("Sign In")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Theme.Colors.primary)
                    .cornerRadius(Theme.CornerRadius.md)
            }
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.top, Theme.Spacing.lg)
            
            Spacer()
        }
        .onReceive(NotificationCenter.default.publisher(for: .profilePictureUpdated)) { notification in
            // Force refresh the view when profile picture is updated
            if let newURL = notification.object as? String {
                print("🔄 SimpleProfessionalProfileView: Profile picture updated, refreshing view with: \(newURL)")
                // Clear any local cache and refresh the viewModel
                ImageCacheManager.shared.clearCache()
                viewModel.loadUserProfile()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .userDidUpdate)) { _ in
            print("🔄 SimpleProfessionalProfileView: User profile updated (from EditProfile)")
            // Clear image cache to force fresh load of profile picture
            ImageCacheManager.shared.clearCache()
            // Refresh user data from AuthManager
            viewModel.loadUserProfile()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshUserProfile"))) { _ in
            print("🔄 SimpleProfessionalProfileView: General profile refresh requested")
            ImageCacheManager.shared.clearCache()
            viewModel.loadUserProfile()
        }
        .navigationBarTitle("Profile", displayMode: .large)
    }
}

// MARK: - Profile Menu Row
struct ProfileMenuRow: View {
    let icon: String
    let title: String
    let badge: String?
    
    init(icon: String, title: String, badge: String? = nil) {
        self.icon = icon
        self.title = title
        self.badge = badge
    }
    
    var body: some View {
        HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Theme.Colors.primary)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.Colors.text)
                
                Spacer()
                
                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(badge.contains("Verified") ? Color.green.opacity(0.2) : Theme.Colors.primary.opacity(0.2))
                        )
                        .foregroundColor(badge.contains("Verified") ? .green : Theme.Colors.primary)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.tertiaryText)
            }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(Theme.CornerRadius.md)
    }
}

// MARK: - Profile Stat Box
struct ProfileStatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Theme.Colors.text)
                
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(Theme.CornerRadius.md)
    }
}

// MARK: - Helper Functions
extension SimpleProfessionalProfileView {
    private func getAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    private func getBuildNumber() -> String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
}

// MARK: - Preview
struct SimpleProfessionalProfileView_Previews: PreviewProvider {
    static var previews: some View {
        SimpleProfessionalProfileView()
            .environmentObject(AuthManager.shared)
    }
}