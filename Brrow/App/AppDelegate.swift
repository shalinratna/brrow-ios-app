//
//  AppDelegate.swift
//  Brrow
//
//  App Delegate for Push Notifications and Background Tasks
//

import UIKit
import UserNotifications
import GoogleSignIn
import FirebaseCore
import FirebaseMessaging
import BackgroundTasks
// import OneSignalFramework // Temporarily disabled - install via Xcode

class AppDelegate: NSObject, UIApplicationDelegate {

    // Store background completion handler for URLSession
    var backgroundCompletionHandler: (() -> Void)?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Initialize Firebase first
        FirebaseApp.configure()

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

        // Configure Firebase Messaging
        configureFirebaseMessaging()

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
        
        // Register background upload tasks
        BackgroundUploadTaskManager.shared.registerBackgroundTasks()

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
        // Pass device token to Firebase Messaging
        Messaging.messaging().apnsToken = deviceToken

        // Also pass to our NotificationManager
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
    
    // MARK: - Firebase Messaging Configuration

    private func configureFirebaseMessaging() {
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self

        // Register for remote notifications
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }

        print("✅ Firebase Messaging configured")
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

    // MARK: - Background URL Session Handling

    func application(
        _ application: UIApplication,
        handleEventsForBackgroundURLSession identifier: String,
        completionHandler: @escaping () -> Void
    ) {
        print("📤 [AppDelegate] Background URL session events for identifier: \(identifier)")

        // Store completion handler
        backgroundCompletionHandler = completionHandler

        // Listen for completion notification from FileUploadService
        NotificationCenter.default.addObserver(
            forName: .backgroundUploadComplete,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("📤 [AppDelegate] Background upload complete - calling completion handler")
            self?.backgroundCompletionHandler?()
            self?.backgroundCompletionHandler = nil
        }
    }
}

// MARK: - API Client Extensions

// MARK: - Firebase Messaging Delegate
extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }

        print("✅ Firebase FCM token received: \(String(token.prefix(20)))...")

        // Send token to your server
        Task {
            do {
                let tokenData: [String: Any] = [
                    "device_token": token,
                    "platform": "ios",
                    "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
                    "device_model": UIDevice.current.model,
                    "os_version": UIDevice.current.systemVersion
                ]

                let _ = try await APIClient.shared.registerDeviceToken(parameters: tokenData)
                print("✅ FCM token registered with server")
            } catch {
                print("❌ Failed to register FCM token: \(error)")
            }
        }
    }
}

// MARK: - UNUserNotificationCenter Delegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.alert, .badge, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        print("🔔 [AppDelegate] Notification tapped, userInfo: \(userInfo)")

        // Handle notification tap
        if let chatId = userInfo["chatId"] as? String {
            print("🔔 [AppDelegate] Extracted chatId: \(chatId)")

            // CRITICAL FIX: Delay navigation to ensure app UI is fully loaded
            // This prevents race conditions when app launches from notification
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("🔔 [AppDelegate] Posting navigateToChat notification")
                NotificationCenter.default.post(
                    name: .navigateToChat,
                    object: nil,
                    userInfo: ["chatId": chatId]
                )
            }
        } else {
            print("⚠️ [AppDelegate] No chatId found in notification payload")
        }

        completionHandler()
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