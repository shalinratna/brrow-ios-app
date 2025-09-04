//
//  WidgetIntegration.swift
//  Brrow
//
//  Integration points for widget updates throughout the app
//

import Foundation
import WidgetKit
import UIKit

// MARK: - App Delegate Extension
extension AppDelegate {
    func setupWidgetUpdates() {
        // Update widgets when app becomes active
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            WidgetDataManager.shared.handleAppBecameActive()
        }
    }
}

// MARK: - AuthManager Extension
extension AuthManager {
    func updateWidgetAfterLogin() {
        // Refresh all widget data after successful login
        WidgetDataManager.shared.refreshAllWidgetData()
    }
    
    func clearWidgetDataOnLogout() {
        // Clear sensitive widget data on logout
        WidgetDataManager.shared.updateWidgetData(
            activeListings: 0,
            unreadMessages: 0,
            todaysEarnings: 0,
            nearbyItems: 0,
            recentActivity: "Sign in to see your activity"
        )
    }
}

// MARK: - Listing Creation Extension
extension CreateListingViewModel {
    func notifyWidgetOfNewListing() {
        WidgetDataManager.shared.handleNewListingCreated()
    }
}

// MARK: - Chat/Messages Extension (Example)
// Uncomment and adapt when you have a ChatViewModel
/*
extension ChatViewModel {
    func updateWidgetUnreadCount() {
        // Call this when messages are received or read
        let unreadCount = getUnreadMessageCount() // Your existing method
        WidgetDataManager.shared.updateWidgetData(unreadMessages: unreadCount)
    }
    
    func notifyWidgetOfNewMessage(from sender: String) {
        WidgetDataManager.shared.handleNewMessage(from: sender)
    }
}
*/

// MARK: - Earnings Extension (Example)
// Uncomment and adapt when you have an EarningsViewModel
/*
extension EarningsViewModel {
    func updateWidgetEarnings() {
        let todaysEarnings = calculateTodaysEarnings() // Your existing method
        WidgetDataManager.shared.updateTodaysEarnings(todaysEarnings)
    }
}
*/

// MARK: - Location Extension
extension LocationService {
    func updateWidgetNearbyItems(count: Int) {
        // Call this when location updates or nearby items change
        WidgetDataManager.shared.updateNearbyItems(count)
    }
}

// MARK: - Sample Integration Usage
/*
 Here's how to integrate widget updates in your existing code:

 1. After creating a listing:
    createListing() { success in
        if success {
            self.notifyWidgetOfNewListing()
        }
    }

 2. When receiving a message:
    func didReceiveMessage(_ message: Message) {
        // Your existing message handling
        notifyWidgetOfNewMessage(from: message.senderName)
    }

 3. When completing a rental:
    func completeRental(_ rental: Rental) {
        // Your existing rental completion logic
        WidgetDataManager.shared.handleRentalCompleted(
            earnings: rental.earnings,
            itemName: rental.itemName
        )
    }

 4. On app launch in AppDelegate:
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Your existing setup
        setupWidgetUpdates()
        return true
    }

 5. In SceneDelegate when scene becomes active:
    func sceneDidBecomeActive(_ scene: UIScene) {
        WidgetDataManager.shared.handleAppBecameActive()
    }
*/