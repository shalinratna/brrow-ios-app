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
    @AppStorage("shouldShowWelcomeOnboarding") private var shouldShowWelcomeOnboarding = false
    @AppStorage("shouldStartInSignupMode") private var shouldStartInSignupMode = false
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
                } else if shouldShowWelcomeOnboarding && authManager.isAuthenticated {
                    // Show welcome onboarding ONLY after first successful registration
                    WelcomeOnboardingView()
                        .transition(.opacity)
                        .onDisappear {
                            shouldShowWelcomeOnboarding = false
                        }
                } else if authManager.isAuthenticated {
                    NativeMainTabView()
                        .applyRTLIfNeeded()
                        .connectionStatusBanner()  // Show connection status banner
                        .withUniversalListingDetail()
                        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                            // Update widget data when app becomes active
                            WidgetDataManager.shared.handleAppBecameActive()
                            WidgetIntegrationService.shared.refreshWidgetsOnAppActivation()

                            // Refresh marketplace data in background to ensure fresh listings
                            MarketplaceDataPreloader.shared.refreshInBackground()
                        }
                } else {
                    ModernAuthView()
                        .applyRTLIfNeeded()
                        .connectionStatusBanner()  // Show connection status banner
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

                // Track app opened
                AnalyticsService.shared.trackAppOpened(source: pendingDeepLink != nil ? "deeplink" : "direct")

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
            .onReceive(NotificationCenter.default.publisher(for: .navigateToPurchase)) { notification in
                handlePurchaseNavigation(notification)
            }
            .onReceive(NotificationCenter.default.publisher(for: .openTransactions)) { notification in
                // This is handled by the Profile view - just switching tab is enough
                // The Profile view will detect the openTransactions notification and navigate
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

        // Initialize widget data on app launch
        if authManager.isAuthenticated {
            WidgetIntegrationService.shared.updateAllWidgetData()
        }

        // CRITICAL: Preload ALL app data immediately for instant responsiveness
        // This loads marketplace, conversations, favorites, and more in parallel
        // so every tab is ready instantly when user taps on it
        if authManager.isAuthenticated && !authManager.isGuestUser {
            Task {
                // Start preloading immediately - no delay needed
                // The comprehensive preloader loads everything in parallel
                print("🚀 [APP] Starting comprehensive data preload...")
                AppDataPreloader.shared.preloadAllData()
            }
        }

        // Check for pending uploads from previous session (crash recovery)
        checkAndResumePendingUploads()
    }

    /// Check for and resume pending uploads after app launch (crash recovery)
    private func checkAndResumePendingUploads() {
        // Lightweight check first
        FileUploadService.shared.checkPendingUploadsOnLaunch()

        // Only resume if user is authenticated
        guard authManager.isAuthenticated else {
            print("ℹ️ [CRASH RECOVERY] User not authenticated, skipping upload resume")
            return
        }

        // Check if there are pending uploads
        if UploadQueuePersistence.shared.hasPendingUploads() {
            // Resume uploads in background after app is fully loaded
            Task {
                // Wait a bit for app to fully initialize
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

                await FileUploadService.shared.resumePendingUploads()
            }
        }
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
        // Handle navigation from messaging buttons and push notifications
        guard let userInfo = notification.userInfo else { return }

        // Handle messaging button navigation (from listing detail views)
        if let chatId = userInfo["chatId"] as? String,
           let listingId = userInfo["listingId"] as? String,
           let listingTitle = userInfo["listingTitle"] as? String {

            print("🔔 Navigating to chat: \(chatId)")
            print("🔔 For listing: \(listingTitle) (\(listingId))")

            // Switch to Messages tab and navigate to specific chat
            // Note: selectedTab is managed by MainTabView, use notification to switch tabs
            NotificationCenter.default.post(name: .navigateToMessages, object: nil)

            // Use ChatListViewModel to handle the navigation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NotificationCenter.default.post(
                    name: .openSpecificChat,
                    object: nil,
                    userInfo: [
                        "chatId": chatId,
                        "listingId": listingId,
                        "listingTitle": listingTitle
                    ]
                )
            }

            return
        }

        // Handle legacy push notification navigation
        if let username = userInfo["username"] as? String {
            print("Navigating to chat with \(username)")
            NotificationCenter.default.post(name: .navigateToMessages, object: nil)
        }
    }

    private func handlePurchaseNavigation(_ notification: Notification) {
        // Handle navigation from purchase notifications
        guard let userInfo = notification.userInfo,
              let purchaseId = userInfo["purchaseId"] as? String else {
            print("⚠️ [BrrowApp] No purchaseId in purchase notification")
            return
        }

        print("💰 [BrrowApp] Navigating to transaction: \(purchaseId)")

        // Navigate to Profile tab (tab 4)
        TabSelectionManager.shared.selectedTab = 4

        // Wait for tab to switch, then navigate to Transactions with specific purchase
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            NotificationCenter.default.post(
                name: .openTransactions,
                object: nil,
                userInfo: ["purchaseId": purchaseId]
            )
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
        case "identity":
            // Handle Stripe Identity verification callback
            // Path will be: brrow://identity/verification/complete
            // The IdentityVerificationWebView handles the completion logic
            print("✅ [Deep Link] Stripe Identity verification completed")
        
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

        case "payment":
            // Handle payment return from Stripe Checkout Sessions
            // Expected URLs:
            // - brrowapp://payment/success?session_id={CHECKOUT_SESSION_ID}&listing_id={listingId}
            // - brrowapp://payment/cancel?listing_id={listingId}
            let path = components.path ?? ""

            if path == "/success" {
                // Payment completed successfully via Checkout Session
                let sessionId = components.queryItems?.first(where: { $0.name == "session_id" })?.value
                let listingId = components.queryItems?.first(where: { $0.name == "listing_id" })?.value
                let purchaseId = components.queryItems?.first(where: { $0.name == "purchase_id" })?.value

                print("✅ [PAYMENT] Checkout Session completed")
                print("   - session_id: \(sessionId ?? "none")")
                print("   - listing_id: \(listingId ?? "none")")
                print("   - purchase_id: \(purchaseId ?? "none")")
                print("   - Full URL: \(url.absoluteString)")

                // Validate that we have a session ID
                guard let validSessionId = sessionId, !validSessionId.isEmpty else {
                    print("❌ [PAYMENT] ERROR: Missing session_id in payment callback")
                    print("   - This might indicate a problem with Stripe checkout configuration")
                    print("   - Expected URL format: brrowapp://payment/success?session_id={CHECKOUT_SESSION_ID}")

                    // Show user-friendly error
                    ToastManager.shared.showError(
                        title: "Payment Verification Failed",
                        message: "Unable to verify payment. Please check your transactions or contact support."
                    )
                    return
                }

                // Post notification for CheckoutFlowContainer and other payment views
                // This notification is used by both Checkout Sessions (new) and legacy PaymentSheet flows
                NotificationCenter.default.post(
                    name: Notification.Name("ShowPaymentSuccess"),
                    object: nil,
                    userInfo: [
                        "sessionId": validSessionId,
                        "listingId": listingId ?? "",
                        "purchaseId": purchaseId ?? ""
                    ]
                )

            } else if path == "/cancel" {
                // Payment canceled by user
                let listingId = components.queryItems?.first(where: { $0.name == "listing_id" })?.value
                let purchaseId = components.queryItems?.first(where: { $0.name == "purchase_id" })?.value

                print("❌ [PAYMENT] Checkout Session canceled")
                print("   - listing_id: \(listingId ?? "none")")
                print("   - purchase_id: \(purchaseId ?? "none")")

                // Post notification for CheckoutFlowContainer and other payment views
                // User can retry payment after cancellation
                NotificationCenter.default.post(
                    name: Notification.Name("ShowPaymentCanceled"),
                    object: nil,
                    userInfo: [
                        "listingId": listingId ?? "",
                        "purchaseId": purchaseId ?? ""
                    ]
                )
            }

        case "verified":
            // Handle email verification success callback from web browser
            print("✅ [EMAIL VERIFICATION] Email verified via web - refreshing user state")

            // Refresh user profile to get updated email_verified_at status
            Task {
                await AuthManager.shared.refreshUserProfile()
                print("✅ [EMAIL VERIFICATION] User profile refreshed")

                await MainActor.run {
                    // Show success toast
                    ToastManager.shared.showSuccess(
                        title: "Email Verified!",
                        message: "Your email has been verified successfully. You now have full marketplace access!"
                    )

                    // Navigate to profile tab to show updated verification status
                    TabSelectionManager.shared.selectedTab = 4
                }
            }

        default:
            // Check if it's a web URL format: https://brrowapp.com/listing/123 or https://brrowapp.com/profile/456
            let path = components.path ?? ""

            if path.hasPrefix("/listing/") {
                // Extract the listing ID - supports both formats:
                // Old: /listing/f923e46e-71f9-481e-8f39-21926fa4055f
                // New: /listing/canon-camera-x7k2p?id=f923e46e-71f9-481e-8f39-21926fa4055f
                let listingId = extractListingId(from: url, components: components, pathPrefix: "/listing/")
                print("🔗 [Deep Link] Opening listing from web URL: \(listingId)")
                // Use the universal listing navigation manager
                ListingNavigationManager.shared.showListingById(listingId)
            } else if path.hasPrefix("/profile/") {
                // Extract the user ID - supports both formats:
                // Old: /profile/f923e46e-71f9-481e-8f39-21926fa4055f
                // New: /profile/john-doe-a3f9k2?id=f923e46e-71f9-481e-8f39-21926fa4055f
                let userId = extractListingId(from: url, components: components, pathPrefix: "/profile/")
                print("🔗 [Deep Link] Opening profile from web URL: \(userId)")

                // Navigate to profile view with specific user ID
                TabSelectionManager.shared.selectedTab = 4 // Profile tab

                // Wait for tab switch, then show the specific user's profile
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    NotificationCenter.default.post(
                        name: Notification.Name("ShowUserProfile"),
                        object: nil,
                        userInfo: ["userId": userId]
                    )
                }
            }
            break
        }
    }

    /// Extracts the UUID from either slug-based or direct UUID URLs
    /// Supports:
    /// - New format: /listing/canon-camera-x7k2p?id=uuid
    /// - Old format: /listing/uuid
    private func extractListingId(from url: URL, components: URLComponents, pathPrefix: String) -> String {
        // First, check for ?id= query parameter (new slug-based format)
        if let idParam = components.queryItems?.first(where: { $0.name == "id" })?.value {
            print("🔗 [Deep Link] Extracted UUID from query param: \(idParam)")
            return idParam
        }

        // Fallback: extract from path (old UUID format or if query param missing)
        let path = components.path ?? ""
        let pathId = String(path.dropFirst(pathPrefix.count))

        // Check if this looks like a UUID (backward compatibility)
        let uuidPattern = "^[a-fA-F0-9-]{36}$"
        if pathId.range(of: uuidPattern, options: .regularExpression) != nil {
            print("🔗 [Deep Link] Using UUID from path (old format): \(pathId)")
            return pathId
        }

        // If it's a slug without query param, treat the whole slug as the ID
        // (This handles edge cases where the website might not include ?id=)
        print("🔗 [Deep Link] Using slug as ID (fallback): \(pathId)")
        return pathId
    }
}
