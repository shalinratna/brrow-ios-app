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
    @State private var showBecomeCreator = false
    @State private var showCreatorDashboard = false
    @State private var showEnterCreatorCode = false
    @State private var showingMyPosts = false
    @State private var showingOffers = false
    @State private var showingSavedItems = false
    @StateObject private var creatorViewModel = CreatorStatusViewModel()
    
    // Show email verification banner if user is not verified and banner hasn't been dismissed
    private var shouldShowEmailBanner: Bool {
        showEmailVerificationBanner && 
        !(viewModel.user?.emailVerified ?? false) && 
        !idmeService.isVerified &&
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
                        // Email Verification Banner
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
            .sheet(isPresented: $showBecomeCreator) {
                BecomeCreatorView()
            }
            .sheet(isPresented: $showCreatorDashboard) {
                CreatorDashboardView()
            }
            .sheet(isPresented: $showEnterCreatorCode) {
                EnterCreatorCodeView()
            }
            .sheet(isPresented: $showingMyPosts) {
                EnhancedMyPostsView()
            }
            .sheet(isPresented: $showingOffers) {
                EnhancedOffersView()
            }
            .sheet(isPresented: $showingSavedItems) {
                EnhancedSavedItemsView()
            }
            .onAppear {
                withAnimation {
                    animateContent = true
                }
                
                // Track achievement for profile completion check
                if let user = viewModel.user, !(user.bio?.isEmpty ?? true) && user.profilePicture != nil {
                    AchievementManager.shared.trackProfileCompleted()
                }
                
                // Load creator status
                Task {
                    await creatorViewModel.loadCreatorStatus()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .navigateToMyPosts)) { _ in
                showingMyPosts = true
            }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Text("profile".localizedString)
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
                
                if let user = viewModel.user, let profilePicture = user.profilePicture, !profilePicture.isEmpty {
                    AsyncImage(url: URL(string: profilePicture)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ProgressView()
                            .scaleEffect(0.5)
                    }
                    .frame(width: 90, height: 90)
                    .clipShape(Circle())
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
                UsernameWithBadge(
                    username: viewModel.user?.username ?? "Loading...",
                    badgeType: viewModel.user?.badgeType,
                    fontSize: 24,
                    badgeSize: .large
                )
                .foregroundColor(Theme.Colors.text)
                
                Text("@\(viewModel.user?.username ?? "")")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.Colors.secondaryText)
                
                // Rating
                if let user = viewModel.user {
                    let averageRating = Double(((user.listerRating ?? 0) + (user.renteeRating ?? 0)) / 2.0)
                    let fullStars = Int(averageRating)
                    let hasHalfStar = averageRating - Double(fullStars) >= 0.5
                    
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
            
            // Edit Profile Button
            Group {
                if let user = viewModel.user {
                    NavigationLink(destination: EditProfileView(user: user)) {
                        Text("edit_profile".localizedString)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Theme.Colors.primary)
                            .cornerRadius(12)
                    }
                } else {
                    Button(action: {}) {
                        Text("edit_profile".localizedString)
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
                    title: "active_listings".localizedString,
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
                title: "total_reviews".localizedString,
                value: "\(viewModel.reviewCount)",
                icon: "star.fill",
                color: Theme.Colors.accentOrange
            )
            .opacity(animateContent ? 1 : 0)
            .scaleEffect(animateContent ? 1 : 0.9)
            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.35), value: animateContent)
            
            ProfileStatBox(
                title: "lister_rating".localizedString,
                value: String(format: "%.1f", viewModel.user?.listerRating ?? 0.0),
                icon: "star.fill",
                color: Theme.Colors.accentBlue
            )
            .opacity(animateContent ? 1 : 0)
            .scaleEffect(animateContent ? 1 : 0.9)
            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4), value: animateContent)
            
            ProfileStatBox(
                title: "rentee_rating".localizedString,
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
        do {
            let response = try await APIClient.shared.sendEmailVerification()
            await MainActor.run {
                if response.alreadyVerified == true {
                    showEmailVerificationBanner = false
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
            
            Button(action: { showingOffers = true }) {
                ProfileMenuRow(
                    icon: "clock.fill",
                    title: "rental_history".localizedString
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            NavigationLink(destination: UltraModernProfileView2()) {
                ProfileMenuRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "analytics".localizedString
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: { showingSavedItems = true }) {
                ProfileMenuRow(
                    icon: "heart.fill",
                    title: "saved_items".localizedString
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            NavigationLink(destination: PushNotificationSettingsView()) {
                ProfileMenuRow(
                    icon: "bell.fill",
                    title: "notifications".localizedString
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
            
            // Subscription Management
            NavigationLink(destination: StripeSubscriptionView()) {
                ProfileMenuRow(
                    icon: "crown.fill",
                    title: "subscription".localizedString
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Creator Options
            if creatorViewModel.isCreator {
                // Creator Dashboard
                Button(action: { showCreatorDashboard = true }) {
                    ProfileMenuRow(
                        icon: "star.circle.fill",
                        title: "Creator Dashboard",
                        badge: creatorViewModel.creatorCode
                    )
                }
                .buttonStyle(PlainButtonStyle())
            } else if creatorViewModel.applicationPending {
                // Application Pending
                ProfileMenuRow(
                    icon: "hourglass",
                    title: "Creator Application",
                    badge: "Pending"
                )
                .opacity(0.7)
            } else {
                // Become a Creator
                Button(action: { showBecomeCreator = true }) {
                    ProfileMenuRow(
                        icon: "star.circle",
                        title: "Become a Creator",
                        badge: "Earn 1%"
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Enter Creator Code (if user hasn't been referred)
            if authManager.currentUser?.referredByCreatorCode == nil {
                Button(action: { showEnterCreatorCode = true }) {
                    ProfileMenuRow(
                        icon: "gift.fill",
                        title: "Have a Creator Code?",
                        badge: "Support"
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Business Account (if business user)
            if authManager.currentUser?.accountType == "business" {
                NavigationLink(destination: BusinessAccountView()) {
                    ProfileMenuRow(
                        icon: "building.2.fill",
                        title: "business_account".localizedString
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
            
            // Achievements
            NavigationLink(destination: AchievementsView()) {
                ProfileMenuRow(
                    icon: "trophy.fill",
                    title: "achievements".localizedString
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Borrow vs Buy Calculator - Removed (requires listing context)
            
            NavigationLink(destination: LanguageSettingsView()) {
                ProfileMenuRow(
                    icon: "globe",
                    title: "language".localizedString
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            NavigationLink(destination: AboutView()) {
                ProfileMenuRow(
                    icon: "questionmark.circle.fill",
                    title: "help_support".localizedString
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