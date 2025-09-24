//
//  AppDelegate.swift
//  Brrow
//
//  App Delegate for Push Notifications and Background Tasks
//

import UIKit
import UserNotifications
import GoogleSignIn
// import OneSignalFramework // Temporarily disabled - install via Xcode

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Initialize language settings early
        if let savedLanguage = UserDefaults.standard.string(forKey: "AppLanguage") {
            Bundle.setLanguage(savedLanguage)
            UserDefaults.standard.set([savedLanguage], forKey: "AppleLanguages")
            UserDefaults.standard.synchronize()
        }
        
        // Initialize caching system for fast loading
        initializeCaching()
        
        // Initialize notification manager
        NotificationManager.shared.initialize()
        
        // Check permission status
        NotificationManager.shared.checkPermissionStatus()
        
        // Initialize Google Sign-In
        configureGoogleSignIn()
        
        // Initialize OneSignal - Uncomment after installing SDK via Xcode
        /*
        OneSignal.initialize("ebb64d61-971c-4415-8ca3-53aa7b4a2ca0", withLaunchOptions: launchOptions)
        
        // Request permission for push notifications
        OneSignal.Notifications.requestPermission({ accepted in
            print("User accepted notifications: \(accepted)")
        }, fallbackToSettings: true)
        
        // Set external user ID for targeting specific users
        if let userApiId = AuthManager.shared.currentUser?.apiId {
            OneSignal.login(userApiId)
        }
        */
        
        // Preload garage sales data in background for smooth UX
        Task {
            do {
                let garageSales = try await APIClient.shared.fetchGarageSales()
                // Preloaded \(garageSales.count) garage sales at app startup
                // Data is now cached in APIClient's response cache
            } catch {
                print("⚠️ Failed to preload garage sales: \(error)")
            }
        }
        
        return true
    }
    
    // MARK: - Push Notification Registration
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        NotificationManager.shared.setDeviceToken(deviceToken)
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        NotificationManager.shared.handleRegistrationError(error)
    }
    
    // MARK: - Background App Refresh
    
    func application(
        _ application: UIApplication,
        performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        // Perform background sync
        Task {
            do {
                let hasNewData = try await performBackgroundSync()
                completionHandler(hasNewData ? .newData : .noData)
            } catch {
                completionHandler(.failed)
            }
        }
    }
    
    private func performBackgroundSync() async throws -> Bool {
        // Sync messages, notifications, etc.
        var hasNewData = false
        
        // Check for new messages
        if let userId = AuthManager.shared.currentUser?.apiId {
            let newMessages = try await APIClient.shared.checkForNewMessages(userId: userId)
            if !newMessages.isEmpty {
                hasNewData = true
                
                // Update badge count
                let badgeResponse = try await APIClient.shared.getNotificationBadgeCount()
                if let badgeData = badgeResponse.data {
                    NotificationManager.shared.updateBadgeCount(badgeData.unreadCount)
                }
            }
        }
        
        return hasNewData
    }
    
    // MARK: - Caching Initialization
    
    private func initializeCaching() {
        // Initialize image cache manager
        _ = ImageCacheManager.shared
        
        // Initialize data cache manager
        _ = DataCacheManager.shared
        
        // Preload essential data in background
        Task {
            DataCacheManager.shared.preloadEssentialData()
        }
        
        // Set cache size limits
        URLCache.shared.memoryCapacity = 50 * 1024 * 1024 // 50 MB
        URLCache.shared.diskCapacity = 200 * 1024 * 1024 // 200 MB
        
        print("✅ Caching system initialized for fast loading")
    }
    
    // MARK: - Google Sign-In Configuration
    
    private func configureGoogleSignIn() {
        // Use the actual Google Client ID provided
        let clientId = "13144810708-cdf0vg3j0u7krgff4m68pjj6qb6n2dlr.apps.googleusercontent.com"

        let config = GIDConfiguration(clientID: clientId)
        GIDSignIn.sharedInstance.configuration = config
        print("✅ Google Sign-In configured with client ID: \(String(clientId.prefix(20)))...")
    }
    
    // MARK: - URL Handling
    
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        // Handle Google Sign-In callback
        if GIDSignIn.sharedInstance.handle(url) {
            return true
        }
        
        // Handle other URL schemes (existing implementation can be added here)
        return false
    }
    
    // MARK: - Interface Orientation Support
    
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        // Support all orientations for RTL languages
        if LocalizationManager.shared.currentLanguage.isRTL {
            return .allButUpsideDown
        }
        // Default to portrait for LTR languages
        return .portrait
    }
}

// MARK: - API Client Extensions

extension APIClient {
    func checkForNewMessages(userId: String) async throws -> [ChatMessage] {
        // Implementation would check for new messages
        try await Task.sleep(nanoseconds: 500_000_000)
        return []
    }
    
    func getUnreadMessageCount(userId: String) async throws -> Int {
        // Implementation would get unread count
        try await Task.sleep(nanoseconds: 300_000_000)
        return 0
    }
}