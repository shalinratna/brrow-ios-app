//
//  WidgetDataManager.swift
//  Brrow
//
//  Manages data sharing between the main app and widgets
//

import Foundation
import WidgetKit

class WidgetDataManager {
    static let shared = WidgetDataManager()
    
    // App Group identifier - you need to set this up in your app capabilities
    private let appGroupIdentifier = "group.com.brrowapp.widgets"
    
    private var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroupIdentifier)
    }
    
    // MARK: - Data Keys
    private enum Keys {
        static let activeListings = "widget.activeListings"
        static let unreadMessages = "widget.unreadMessages"
        static let todaysEarnings = "widget.todaysEarnings"
        static let nearbyItems = "widget.nearbyItems"
        static let recentActivity = "widget.recentActivity"
        static let lastUpdated = "widget.lastUpdated"
    }
    
    // MARK: - Update Widget Data
    func updateWidgetData(
        activeListings: Int? = nil,
        unreadMessages: Int? = nil,
        todaysEarnings: Double? = nil,
        nearbyItems: Int? = nil,
        recentActivity: String? = nil
    ) {
        guard let defaults = sharedDefaults else { return }
        
        if let activeListings = activeListings {
            defaults.set(activeListings, forKey: Keys.activeListings)
        }
        
        if let unreadMessages = unreadMessages {
            defaults.set(unreadMessages, forKey: Keys.unreadMessages)
        }
        
        if let todaysEarnings = todaysEarnings {
            defaults.set(todaysEarnings, forKey: Keys.todaysEarnings)
        }
        
        if let nearbyItems = nearbyItems {
            defaults.set(nearbyItems, forKey: Keys.nearbyItems)
        }
        
        if let recentActivity = recentActivity {
            defaults.set(recentActivity, forKey: Keys.recentActivity)
        }
        
        defaults.set(Date(), forKey: Keys.lastUpdated)
        
        // Trigger widget refresh
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // MARK: - Get Widget Data
    func getWidgetData() -> WidgetDataModel {
        guard let defaults = sharedDefaults else {
            return WidgetDataModel.empty
        }
        
        return WidgetDataModel(
            activeListings: defaults.integer(forKey: Keys.activeListings),
            unreadMessages: defaults.integer(forKey: Keys.unreadMessages),
            todaysEarnings: defaults.double(forKey: Keys.todaysEarnings),
            nearbyItems: defaults.integer(forKey: Keys.nearbyItems),
            recentActivity: defaults.string(forKey: Keys.recentActivity) ?? "No recent activity",
            lastUpdated: defaults.object(forKey: Keys.lastUpdated) as? Date ?? Date()
        )
    }
    
    // MARK: - Specific Updates
    func incrementUnreadMessages() {
        let current = sharedDefaults?.integer(forKey: Keys.unreadMessages) ?? 0
        updateWidgetData(unreadMessages: current + 1)
    }
    
    func decrementUnreadMessages() {
        let current = sharedDefaults?.integer(forKey: Keys.unreadMessages) ?? 0
        updateWidgetData(unreadMessages: max(0, current - 1))
    }
    
    func updateListingCount(_ count: Int) {
        updateWidgetData(activeListings: count)
    }
    
    func updateTodaysEarnings(_ amount: Double) {
        updateWidgetData(todaysEarnings: amount)
    }
    
    func updateNearbyItems(_ count: Int) {
        updateWidgetData(nearbyItems: count)
    }
    
    func updateRecentActivity(_ activity: String) {
        updateWidgetData(recentActivity: activity)
    }
    
    // MARK: - Refresh All Data
    func refreshAllWidgetData() {
        // This would typically fetch fresh data from your API or Core Data
        // For now, we'll use example data
        
        Task {
            // Simulate fetching data
            let listings = await fetchActiveListingsCount()
            let messages = await fetchUnreadMessagesCount()
            let earnings = await fetchTodaysEarnings()
            let nearby = await fetchNearbyItemsCount()
            let activity = await fetchRecentActivity()
            
            updateWidgetData(
                activeListings: listings,
                unreadMessages: messages,
                todaysEarnings: earnings,
                nearbyItems: nearby,
                recentActivity: activity
            )
        }
    }
    
    // MARK: - Mock Data Fetchers (Replace with real implementations)
    private func fetchActiveListingsCount() async -> Int {
        // Replace with actual API call or Core Data fetch
        return UserDefaults.standard.integer(forKey: "userActiveListings")
    }
    
    private func fetchUnreadMessagesCount() async -> Int {
        // Replace with actual API call or Core Data fetch
        return UserDefaults.standard.integer(forKey: "userUnreadMessages")
    }
    
    private func fetchTodaysEarnings() async -> Double {
        // Replace with actual API call or Core Data fetch
        return UserDefaults.standard.double(forKey: "userTodaysEarnings")
    }
    
    private func fetchNearbyItemsCount() async -> Int {
        // Replace with actual API call or Core Data fetch
        return UserDefaults.standard.integer(forKey: "userNearbyItems")
    }
    
    private func fetchRecentActivity() async -> String {
        // Replace with actual API call or Core Data fetch
        return UserDefaults.standard.string(forKey: "userRecentActivity") ?? "Check the app for updates"
    }
}

// MARK: - Widget Data Model
struct WidgetDataModel {
    let activeListings: Int
    let unreadMessages: Int
    let todaysEarnings: Double
    let nearbyItems: Int
    let recentActivity: String
    let lastUpdated: Date
    
    static let empty = WidgetDataModel(
        activeListings: 0,
        unreadMessages: 0,
        todaysEarnings: 0,
        nearbyItems: 0,
        recentActivity: "No data available",
        lastUpdated: Date()
    )
}

// MARK: - Widget Update Extension
extension WidgetDataManager {
    /// Call this when the app becomes active to refresh widget data
    func handleAppBecameActive() {
        refreshAllWidgetData()
    }
    
    /// Call this when a new listing is created
    func handleNewListingCreated() {
        let currentCount = sharedDefaults?.integer(forKey: Keys.activeListings) ?? 0
        updateWidgetData(
            activeListings: currentCount + 1,
            recentActivity: "New listing created"
        )
    }
    
    /// Call this when a rental is completed
    func handleRentalCompleted(earnings: Double, itemName: String) {
        let currentEarnings = sharedDefaults?.double(forKey: Keys.todaysEarnings) ?? 0
        updateWidgetData(
            todaysEarnings: currentEarnings + earnings,
            recentActivity: "Rental completed: \(itemName)"
        )
    }
    
    /// Call this when a new message is received
    func handleNewMessage(from username: String) {
        incrementUnreadMessages()
        updateWidgetData(recentActivity: "New message from \(username)")
    }
    
    /// Call this when messages are read
    func handleMessagesRead(count: Int) {
        let current = sharedDefaults?.integer(forKey: Keys.unreadMessages) ?? 0
        updateWidgetData(unreadMessages: max(0, current - count))
    }
    
    // MARK: - Additional Widget Updates
    
    /// Update earnings data for the Earnings Tracker widget
    func updateEarningsData(today: Double, week: Double, month: Double, goalProgress: Double) {
        guard let defaults = sharedDefaults else { return }
        
        defaults.set(today, forKey: "widget.earnings.today")
        defaults.set(week, forKey: "widget.earnings.week")
        defaults.set(month, forKey: "widget.earnings.month")
        defaults.set(goalProgress, forKey: "widget.earnings.goalProgress")
        
        WidgetCenter.shared.reloadTimelines(ofKind: "EarningsWidget")
    }
    
    /// Update active rentals for the Active Rentals widget
    func updateActiveRentals(_ rentals: [[String: Any]]) {
        guard let defaults = sharedDefaults else { return }
        
        if let data = try? JSONSerialization.data(withJSONObject: rentals) {
            defaults.set(data, forKey: "widget.activeRentals")
            WidgetCenter.shared.reloadTimelines(ofKind: "ActiveRentalsWidget")
        }
    }
    
    /// Update achievement data for the Achievements widget
    func updateAchievementData(level: Int, progress: Double, points: Int, badges: [String]) {
        guard let defaults = sharedDefaults else { return }
        
        defaults.set(level, forKey: "widget.achievements.level")
        defaults.set(progress, forKey: "widget.achievements.progress")
        defaults.set(points, forKey: "widget.achievements.points")
        defaults.set(badges, forKey: "widget.achievements.badges")
        
        WidgetCenter.shared.reloadTimelines(ofKind: "AchievementsWidget")
    }
    
    /// Update savings data for the Savings Calculator widget
    func updateSavingsData(total: Double, percentage: Int, itemsSaved: Int) {
        guard let defaults = sharedDefaults else { return }
        
        defaults.set(total, forKey: "widget.savings.total")
        defaults.set(percentage, forKey: "widget.savings.percentage")
        defaults.set(itemsSaved, forKey: "widget.savings.itemsSaved")
        
        WidgetCenter.shared.reloadTimelines(ofKind: "SavingsWidget")
    }
    
    /// Update community data for the Community Impact widget
    func updateCommunityData(
        neighborsHelped: Int,
        itemsShared: Int,
        averageRating: Double,
        communitySaved: Double,
        topCategories: [String]
    ) {
        guard let defaults = sharedDefaults else { return }
        
        defaults.set(neighborsHelped, forKey: "widget.community.neighborsHelped")
        defaults.set(itemsShared, forKey: "widget.community.itemsShared")
        defaults.set(averageRating, forKey: "widget.community.averageRating")
        defaults.set(communitySaved, forKey: "widget.community.moneySaved")
        defaults.set(topCategories, forKey: "widget.community.topCategories")
        
        WidgetCenter.shared.reloadTimelines(ofKind: "CommunityWidget")
    }
}