//
//  NativeMainTabView.swift
//  Brrow
//
//  Production-Ready Native iOS Tab Bar
//

import SwiftUI
import Combine

struct NativeMainTabView: View {
    @StateObject private var discoverViewModel = DiscoverViewModel()
    @StateObject private var chatViewModel = ChatListViewModel()
    @StateObject private var profileViewModel = ProfileViewModel()
    @StateObject private var earningsViewModel = EarningsViewModel()
    @StateObject private var tabSelectionManager = TabSelectionManager.shared
    @StateObject private var achievementNotificationManager = AchievementNotificationManager.shared
    @StateObject private var listingNavManager = ListingNavigationManager.shared
    // IMPORTANT: HomeViewModel for background marketplace preloading
    @StateObject private var homeViewModel = HomeViewModel()
    @EnvironmentObject var authManager: AuthManager
    
    @State private var showingPostSheet = false
    @State private var showingGuestAlert = false
    
    init() {
        // Configure native tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.shadowColor = UIColor.separator.withAlphaComponent(0.3)
        appearance.shadowImage = UIImage()
        
        // Configure item appearance
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.secondaryLabel
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel
        ]
        
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Theme.Colors.primary)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor(Theme.Colors.primary)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        ZStack {
            TabView(selection: $tabSelectionManager.selectedTab) {
            // Home Tab - Professional Design (Hidden for guests)
            if !authManager.isGuestUser {
                NavigationView {
                    ProfessionalHomeView()
                        .environmentObject(discoverViewModel)
                }
                .tabItem {
                    Label("home".localizedString, systemImage: "house.fill")
                }
                .tag(0)
            }
            
            // Marketplace Tab - Professional Design
            NavigationView {
                ProfessionalMarketplaceView()
            }
            .tabItem {
                Label("marketplace".localizedString, systemImage: "bag.fill")
            }
            .tag(1)
            
            // Post Tab - Opens sheet instead of navigating (Plus icon in middle)
            Color.clear
                .tabItem {
                    Label("post".localizedString, systemImage: "plus.app.fill")
                }
                .tag(2)
            
            // Messages Tab with badge
            NavigationView {
                SocialChatView()
                    .environmentObject(chatViewModel)
            }
            .tabItem {
                Label("messages".localizedString, systemImage: "message.fill")
            }
            .badge(chatViewModel.unreadCount > 0 ? "\(chatViewModel.unreadCount)" : nil)
            .tag(3)
            
            // Profile Tab - Professional Design
            NavigationView {
                SimpleProfessionalProfileView()
                    .environmentObject(profileViewModel)
                    .environmentObject(authManager)
            }
            .tabItem {
                Label("profile".localizedString, systemImage: "person.fill")
            }
            .tag(4)
            }
            .onChange(of: tabSelectionManager.selectedTab) { newValue in
            // Check guest restrictions - guests can only use marketplace
            if authManager.isGuestUser {
                // For guests, any tab other than marketplace (1) shows alert
                if newValue != 1 {
                    showGuestAlert()
                    // Always reset to marketplace for guests
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        tabSelectionManager.selectedTab = 1
                    }
                }
            } else {
                // Regular user - only handle post tab
                if newValue == 2 {
                    showingPostSheet = true
                    // Reset to previous tab
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        tabSelectionManager.selectedTab = 0
                    }
                }
            }
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
            .sheet(isPresented: $showingPostSheet) {
                ModernPostCreationView(onListingCreated: { listingId in
                    // Navigate to the marketplace tab
                    tabSelectionManager.selectedTab = 1 // Marketplace tab
                    
                    // Trigger marketplace refresh
                    NotificationCenter.default.post(name: Notification.Name("RefreshMarketplace"), object: nil)
                    
                    // Show the listing detail using the navigation manager
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        listingNavManager.showListingById(listingId)
                    }
                })
            }
            // .quickActionsOverlay() // Temporarily disabled - will be restored after fixing build issues
            
            // Achievement Notifications Overlay
            if achievementNotificationManager.showNotification,
               let achievement = achievementNotificationManager.currentNotification {
                AchievementNotificationView(
                    achievement: achievement,
                    isPresented: $achievementNotificationManager.showNotification
                )
                .onDisappear {
                    achievementNotificationManager.dismissCurrentNotification()
                }
            }
        }
        .sheet(isPresented: $listingNavManager.showingListingDetail, onDismiss: {
            print("🔴 Sheet dismissed")
            listingNavManager.clearListing()
        }) {
            if let listing = listingNavManager.selectedListing {
                NavigationView {
                    ProfessionalListingDetailView(listing: listing)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button(action: {
                                    listingNavManager.clearListing()
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                }
            }
        }
        .alert("Sign In Required", isPresented: $showingGuestAlert) {
            Button("Sign In") {
                // Log out guest and return to login
                authManager.logout()
            }
            Button("Continue Browsing", role: .cancel) {}
        } message: {
            Text("Guest users can only browse the marketplace. Sign in to access all features including posting items, messaging, and your profile.")
        }
        .toastOverlay()
        // CRITICAL: Preload marketplace content when app launches
        // This ensures marketplace is populated BEFORE user taps on it
        .task {
            // Fetch listings in background so they're ready instantly when user opens marketplace
            await homeViewModel.preloadContent()
            print("✅ Marketplace content preloaded in background")
        }
    }
    
    private func showGuestAlert() {
        showingGuestAlert = true
    }
}

#Preview {
    NativeMainTabView()
        .environmentObject(AuthManager.shared)
}