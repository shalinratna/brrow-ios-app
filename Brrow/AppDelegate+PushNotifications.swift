//
//  AppDelegate+PushNotifications.swift
//  Brrow
//
//  Push notification handling extension for AppDelegate
//

import UIKit
import UserNotifications

extension AppDelegate {
    
    // MARK: - Push Notification Setup
    
    func setupPushNotifications() {
        UNUserNotificationCenter.current().delegate = PushNotificationManager.shared
        registerForPushNotifications()
    }
    
    func registerForPushNotifications() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
                print("Permission granted: \(granted)")
                
                guard granted else { return }
                
                self?.getNotificationSettings()
            }
    }
    
    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("Notification settings: \(settings)")
            
            guard settings.authorizationStatus == .authorized else { return }
            
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    // MARK: - Device Token
    // These methods are implemented in AppDelegate.swift to avoid duplication
    
    // MARK: - Handle Notifications
    
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        // Process notification data
        if let aps = userInfo["aps"] as? [String: Any] {
            print("Received notification: \(aps)")
            
            // Update badge count if present
            if let badge = aps["badge"] as? Int {
                application.applicationIconBadgeNumber = badge
            }
            
            // Refresh notifications in background
            Task {
                await PushNotificationManager.shared.fetchNotifications()
                completionHandler(.newData)
            }
        } else {
            completionHandler(.noData)
        }
    }
    
    // MARK: - Application Lifecycle
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Clear badge when app becomes active
        if application.applicationIconBadgeNumber > 0 {
            PushNotificationManager.shared.clearBadge()
            
            // Refresh notifications
            Task {
                await PushNotificationManager.shared.fetchNotifications()
            }
        }
    }
}