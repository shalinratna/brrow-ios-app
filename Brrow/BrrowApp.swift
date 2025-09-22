//
//  BrrowApp.swift
//  Brrow
//
//  Created by Shalin Ratna on 7/16/25.
//

import SwiftUI
import Combine

@main
struct BrrowApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let persistenceController = PersistenceController.shared
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var localizationManager = LocalizationManager.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("HasAgreedToTerms") private var hasAgreedToTerms = false
    @State private var showingPasswordReset = false
    @State private var passwordResetToken = ""
    @State private var splashComplete = false
    @State private var deepLinkedListingId: String? = nil
    @State private var showingDeepLinkedListing = false
    @State private var pendingDeepLink: URL? = nil
    
    var body: some Scene {
        WindowGroup {
            Group {
                if !splashComplete {
                    EnhancedSplashView(isComplete: $splashComplete)
                } else if !hasCompletedOnboarding {
                    ModernOnboardingView()
                } else if !hasAgreedToTerms {
                    ComplianceAgreementView(hasAgreedToTerms: $hasAgreedToTerms)
                } else if authManager.isValidatingToken {
                    // Show loading while validating token
                    ZStack {
                        Color(.systemBackground)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 20) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(1.2)
                            
                            Text(LocalizationHelper.localizedString("authenticating"))
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    }
                } else if authManager.isAuthenticated {
                    NativeMainTabView()
                        .applyRTLIfNeeded()
                        .withUniversalListingDetail()
                        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                            // Update widget data when app becomes active
                            WidgetDataManager.shared.handleAppBecameActive()
                            WidgetIntegrationService.shared.refreshWidgetsOnAppActivation()
                        }
                } else {
                    ModernAuthView()
                        .applyRTLIfNeeded()
                        .withUniversalListingDetail()
                }
            }
            .environmentObject(authManager)
            .environmentObject(notificationManager)
            .environmentObject(localizationManager)
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
            .applyColorScheme()
            .sheet(isPresented: $showingDeepLinkedListing) {
                if let listingId = deepLinkedListingId {
                    NavigationView {
                        DeepLinkedListingView(listingId: listingId)
                    }
                }
            }
            .onAppear {
                setupApp()
                
                // Track achievement for opening app
                if authManager.isAuthenticated {
                    AchievementManager.shared.trackAppOpened()
                }
                
                // Handle pending deep link if any
                if let url = pendingDeepLink {
                    handleDeepLink(url)
                    pendingDeepLink = nil
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .navigateToChat)) { notification in
                handleNotificationNavigation(notification)
            }
            .onReceive(NotificationCenter.default.publisher(for: .navigateToEarnings)) { _ in
                // Navigate to earnings tab
            }
            .onOpenURL { url in
                // Store the deep link if we're not ready to handle it yet
                if !splashComplete || !hasAgreedToTerms {
                    pendingDeepLink = url
                } else {
                    handleDeepLink(url)
                }
            }
            .sheet(isPresented: $showingPasswordReset) {
                NavigationView {
                    ResetPasswordView(email: "")
                        .onAppear {
                            // Pre-fill the token if available
                            if !passwordResetToken.isEmpty {
                                // Token will be handled in the view
                            }
                        }
                }
            }
        }
    }
    
    private func setupApp() {
        // Clear the crash flag to prevent false positives
        // This flag persists across debug sessions causing "Oops" alerts
        UserDefaults.standard.removeObject(forKey: "app_crashed_last_time")
        UserDefaults.standard.synchronize()

        // Initialize PEST Control System
        PESTControlSystem.configure()
        print("🐛 PEST Control System initialized")

        // Configure app appearance
        configureAppearance()

        // Initialize language settings
        initializeLanguage()

        // Initialize Shaiitech systems
        initializeShaiitech()
    }
    
    private func initializeLanguage() {
        // Apply saved language preference on app launch
        if let savedLanguage = UserDefaults.standard.string(forKey: "AppLanguage"),
           let language = LocalizationManager.Language(rawValue: savedLanguage) {
            Bundle.setLanguage(language.code)
            
            // Also set AppleLanguages for system components
            UserDefaults.standard.set([language.code], forKey: "AppleLanguages")
            UserDefaults.standard.synchronize()
        }
    }
    
    private func configureAppearance() {
        // Configure tab bar appearance
        UITabBar.appearance().backgroundColor = UIColor(Theme.Colors.cardBackground)
        UITabBar.appearance().tintColor = UIColor(Theme.Colors.primary)
        
        // Configure navigation bar appearance
        UINavigationBar.appearance().backgroundColor = UIColor(Theme.Colors.cardBackground)
        UINavigationBar.appearance().tintColor = UIColor(Theme.Colors.primary)
    }
    
    private func initializeShaiitech() {
        // Initialize production configuration
        ProductionConfig.configure()
        ProductionConfig.printBuildInfo()
        
        // Initialize Shaiitech Warrior X10 (Core Data)
        _ = persistenceController.container
        
        // Initialize notification manager
        notificationManager.initialize()
        
        // Initialize offline manager
        _ = OfflineManager.shared
        
        // Configure app store metadata
        AppStoreMetadata.configureForProduction()
        
        // Initialize performance optimization
        Task {
            await AppOptimizationService.shared.optimizeAppLaunch()
        }
        
        // Start performance monitoring
        PerformanceManager.shared.startMonitoring()
        PerformanceManager.shared.trackAppLaunchCompleted()
        
        print("🎉 Brrow initialization complete - Ready for production!")
    }
    
    private func handleNotificationNavigation(_ notification: Notification) {
        // Handle deep linking from push notifications
        guard let userInfo = notification.userInfo else { return }
        
        if let username = userInfo["username"] as? String {
            // Navigate to specific chat
            print("Navigating to chat with \(username)")
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        // Handle deep links like brrowapp://reset-password?token=xyz or brrowapp://idme/callback
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
        
        switch components.host {
        case "reset-password":
            if let token = components.queryItems?.first(where: { $0.name == "token" })?.value {
                passwordResetToken = token
                showingPasswordReset = true
            }
        case "idme", "verification":
            // Handle ID.me verification callback
            _ = IDmeService.shared.handleRedirectURL(url)
        
        // Widget deep links
        case "listings":
            // Navigate to marketplace tab (index 1)
            TabSelectionManager.shared.selectedTab = 1
            
        case "messages":
            // Navigate to messages tab (index 3)
            TabSelectionManager.shared.selectedTab = 3
            
        case "earnings":
            // Navigate to profile then earnings (index 4)
            TabSelectionManager.shared.selectedTab = 4
            NotificationCenter.default.post(name: .openEarnings, object: nil)
            
        case "nearby":
            // Navigate to marketplace with location filter (index 1)
            TabSelectionManager.shared.selectedTab = 1
            NotificationCenter.default.post(name: .filterNearby, object: nil)
            
        case "create-listing":
            // Open create listing modal
            NotificationCenter.default.post(name: .createNewListing, object: nil)
            
        case "listing":
            // Handle listing deep link: brrowapp://listing?id=123
            if let listingId = components.queryItems?.first(where: { $0.name == "id" })?.value {
                // Use the universal listing navigation manager
                ListingNavigationManager.shared.showListingById(listingId)
            }
            
        default:
            // Check if it's a web URL format: https://brrowapp.com/listing/123
            let path = components.path ?? ""
            if path.hasPrefix("/listing/") {
                let listingId = String(path.dropFirst("/listing/".count))
                // Use the universal listing navigation manager
                ListingNavigationManager.shared.showListingById(listingId)
            }
            break
        }
    }
}
