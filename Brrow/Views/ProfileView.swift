//
//  ProfileView.swift
//  Brrow
//
//  Created by Shalin Ratna on 7/16/25.
//

import SwiftUI
import Combine

struct ProfileView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var showingSettings = false
    @State private var showingEditProfile = false
    @State private var showingMyListings = false
    @State private var showingFavorites = false
    @State private var showingTransactions = false
    @State private var showingHelpSupport = false
    @State private var showingPaymentMethods = false
    @State private var showingNotifications = false
    @State private var showingPrivacySecurity = false
    @State private var showingAboutBrrow = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Header
                    headerSection
                    
                    // Profile Info
                    profileInfoSection
                    
                    // Stats Section
                    statsSection
                    
                    // Quick Actions
                    quickActionsSection
                    
                    // Menu Items
                    menuSection
                    
                    Spacer()
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
            .background(Theme.Colors.background)
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingEditProfile) {
                EnhancedEditProfileView()
                    .environmentObject(authManager)
            }
            .sheet(isPresented: $showingMyListings) {
                EnhancedMyPostsView()
                    .environmentObject(authManager)
            }
            .sheet(isPresented: $showingFavorites) {
                AllFavoritesView()
                    .environmentObject(authManager)
            }
            .sheet(isPresented: $showingTransactions) {
                TransactionsView()
                    .environmentObject(authManager)
            }
            .sheet(isPresented: $showingHelpSupport) {
                StandaloneHelpSupportView()
            }
            .sheet(isPresented: $showingPaymentMethods) {
                PaymentMethodsView()
                    .environmentObject(authManager)
            }
            .sheet(isPresented: $showingNotifications) {
                SettingsView()
            }
            .sheet(isPresented: $showingPrivacySecurity) {
                PrivacySecurityView()
                    .environmentObject(authManager)
            }
            .sheet(isPresented: $showingAboutBrrow) {
                AboutBrrowView()
            }
            .onAppear {
                trackScreenView("profile")
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Text("Profile")
                .font(Theme.Typography.title)
                .fontWeight(.bold)
                .foregroundColor(Theme.Colors.text)
            
            Spacer()
            
            Button(action: {
                showingSettings = true
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.headline)
                    .foregroundColor(Theme.Colors.primary)
            }
        }
        .padding(.top, Theme.Spacing.md)
    }
    
    // MARK: - Profile Info Section
    private var profileInfoSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Profile Picture
            BrrowAsyncImage(url: authManager.currentUser?.fullProfilePictureURL ?? "") { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .foregroundColor(Theme.Colors.divider)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(Theme.Colors.secondaryText)
                    )
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Theme.Colors.primary, lineWidth: 3)
            )
            
            // User Info
            VStack(spacing: Theme.Spacing.sm) {
                Text(authManager.currentUser?.username ?? "Unknown")
                    .font(Theme.Typography.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.Colors.text)
                
                Text(authManager.currentUser?.email ?? "")
                    .font(Theme.Typography.callout)
                    .foregroundColor(Theme.Colors.secondaryText)
                
                // Verification Status
                HStack {
                    if authManager.currentUser?.emailVerified == true {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Theme.Colors.success)
                        Text("Email Verified")
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.success)
                    }
                    
                    if authManager.currentUser?.idVerified == true {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(Theme.Colors.success)
                        Text("ID Verified")
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.success)
                    }
                }
            }
            
            // Edit Profile Button
            Button(action: {
                showingEditProfile = true
            }) {
                Text("Edit Profile")
                    .font(Theme.Typography.callout)
                    .fontWeight(.medium)
                    .foregroundColor(Theme.Colors.primary)
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(Theme.Colors.primary.opacity(0.1))
                    .cornerRadius(Theme.CornerRadius.md)
            }
        }
        .cardStyle()
        .padding(.top, Theme.Spacing.md)
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: Theme.Spacing.sm) {
            ProfileStatCard(
                title: "Active Listings",
                value: "\(authManager.currentUser?.activeListings ?? 0)",
                icon: "list.bullet",
                color: Theme.Colors.primary
            )

            ProfileStatCard(
                title: "Total Reviews",
                value: "\(authManager.currentUser?.totalReviews ?? 0)",
                icon: "star.fill",
                color: Theme.Colors.warning
            )

            ProfileStatCard(
                title: "Active Rentals",
                value: "\(authManager.currentUser?.activeRentals ?? 0)",
                icon: "clock.fill",
                color: Theme.Colors.info
            )

            ProfileStatCard(
                title: "Offers Made",
                value: "\(authManager.currentUser?.offersMade ?? 0)",
                icon: "hand.raised.fill",
                color: Theme.Colors.success
            )
        }
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            Text("Quick Actions")
                .font(Theme.Typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.text)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Theme.Spacing.md) {
                QuickActionCard(
                    title: "My Listings",
                    icon: "list.bullet",
                    color: Theme.Colors.primary
                ) {
                    showingMyListings = true
                }
                
                QuickActionCard(
                    title: "Favorites",
                    icon: "heart.fill",
                    color: Theme.Colors.error
                ) {
                    showingFavorites = true
                }
                
                QuickActionCard(
                    title: "Transactions",
                    icon: "creditcard",
                    color: Theme.Colors.success
                ) {
                    showingTransactions = true
                }
                
                QuickActionCard(
                    title: "Help & Support",
                    icon: "questionmark.circle",
                    color: Theme.Colors.info
                ) {
                    showingHelpSupport = true
                }
            }
        }
    }
    
    // MARK: - Menu Section
    private var menuSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            MenuRow(
                title: "Payment Methods",
                icon: "creditcard",
                showChevron: true
            ) {
                showingPaymentMethods = true
            }
            
            MenuRow(
                title: "Notifications",
                icon: "bell",
                showChevron: true
            ) {
                showingNotifications = true
            }
            
            MenuRow(
                title: "Privacy & Security",
                icon: "lock.shield",
                showChevron: true
            ) {
                showingPrivacySecurity = true
            }
            
            MenuRow(
                title: "About Brrow",
                icon: "info.circle",
                showChevron: true
            ) {
                showingAboutBrrow = true
            }
            
            MenuRow(
                title: "Sign Out",
                icon: "arrow.right.square",
                showChevron: false,
                isDestructive: true
            ) {
                authManager.logout()
            }
        }
        .cardStyle()
    }
    
    private func trackScreenView(_ screenName: String) {
        let event = AnalyticsEvent(
            eventName: "screen_view",
            eventType: "navigation",
            userId: authManager.currentUser?.apiId,
            sessionId: authManager.sessionId,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            metadata: [
                "screen_name": screenName,
                "platform": "ios"
            ]
        )
        
        Task {
            try? await APIClient.shared.trackAnalytics(event: event)
        }
    }
}

// MARK: - Profile Stat Card
struct ProfileStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(color)
            
            Text(value)
                .font(Theme.Typography.subheadline)
                .fontWeight(.bold)
                .foregroundColor(Theme.Colors.text)
            
            Text(title)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.md)
        .cardStyle()
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundColor(color)
                
                Text(title)
                    .font(Theme.Typography.callout)
                    .fontWeight(.medium)
                    .foregroundColor(Theme.Colors.text)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .cardStyle()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Menu Row
struct MenuRow: View {
    let title: String
    let icon: String
    let showChevron: Bool
    let isDestructive: Bool
    let action: () -> Void
    
    init(title: String, icon: String, showChevron: Bool, isDestructive: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.showChevron = showChevron
        self.isDestructive = isDestructive
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(isDestructive ? Theme.Colors.error : Theme.Colors.primary)
                    .frame(width: 24)
                
                Text(title)
                    .font(Theme.Typography.callout)
                    .foregroundColor(isDestructive ? Theme.Colors.error : Theme.Colors.text)
                
                Spacer()
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
            }
            .padding(.vertical, Theme.Spacing.md)
            .padding(.horizontal, Theme.Spacing.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Placeholder Views (SettingsView moved to separate file)

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}