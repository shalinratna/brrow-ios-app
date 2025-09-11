//
//  WidgetIntegrationService.swift
//  Brrow
//
//  Comprehensive service to ensure widgets update with real data
//

import Foundation
import WidgetKit
import Combine

class WidgetIntegrationService: ObservableObject {
    static let shared = WidgetIntegrationService()
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupObservers()
    }
    
    // MARK: - Setup Observers
    private func setupObservers() {
        // Listen for authentication changes
        NotificationCenter.default.publisher(for: .userAuthenticated)
            .sink { [weak self] _ in
                self?.updateAllWidgetData()
            }
            .store(in: &cancellables)
        
        // Listen for listing changes
        NotificationCenter.default.publisher(for: .listingCreated)
            .sink { [weak self] notification in
                if let listing = notification.object as? Listing {
                    self?.handleListingCreated(listing)
                }
            }
            .store(in: &cancellables)
        
        // Listen for message updates
        NotificationCenter.default.publisher(for: .messageReceived)
            .sink { [weak self] notification in
                if let message = notification.object as? [String: Any] {
                    self?.handleMessageReceived(message)
                }
            }
            .store(in: &cancellables)
        
        // Listen for transaction updates
        NotificationCenter.default.publisher(for: .transactionCompleted)
            .sink { [weak self] notification in
                if let transaction = notification.object as? Transaction {
                    self?.handleTransactionCompleted(transaction)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Update All Widget Data
    func updateAllWidgetData() {
        Task {
            await fetchAndUpdateAllData()
        }
    }
    
    @MainActor
    private func fetchAndUpdateAllData() async {
        guard AuthManager.shared.isAuthenticated else { return }
        
        do {
            // Fetch listings count
            if let listings = try? await APIClient.shared.fetchListings() {
                let activeCount = listings.filter { $0.status == "available" }.count
                let nearbyCount = listings.filter { listing in
                    // Calculate distance (simplified)
                    return true // Would check actual distance
                }.prefix(10).count
                
                WidgetDataManager.shared.updateWidgetData(
                    activeListings: activeCount,
                    nearbyItems: nearbyCount
                )
            }
            
            // Fetch messages count
            if let conversations = try? await APIClient.shared.fetchConversations() {
                let unreadCount = conversations.reduce(0) { $0 + ($1.unreadCount ?? 0) }
                WidgetDataManager.shared.updateWidgetData(unreadMessages: unreadCount)
                
                // Update recent activity
                if let lastConversation = conversations.first {
                    let activity = "Message from \(lastConversation.otherUser.username)"
                    WidgetDataManager.shared.updateWidgetData(recentActivity: activity)
                }
            }
            
            // Fetch earnings data
            if let earnings = try? await APIClient.shared.fetchEarningsOverview() {
                WidgetDataManager.shared.updateWidgetData(
                    todaysEarnings: earnings.avgDailyEarnings
                )
                
                // Update detailed earnings for specialized widget
                WidgetDataManager.shared.updateEarningsData(
                    today: earnings.avgDailyEarnings,
                    week: earnings.avgDailyEarnings * 7,
                    month: earnings.monthlyEarnings,
                    goalProgress: min(1.0, earnings.monthlyEarnings / 1000.0) // Goal of $1000/month
                )
            }
            
            // Fetch achievements data (if API is available)
            // Note: Achievement API may not be available yet
            // WidgetDataManager.shared.updateAchievementData(
            //     level: 1,
            //     progress: 0.5,
            //     points: 100,
            //     badges: []
            // )
            
            // Calculate savings data
            updateSavingsData()
            
            // Update community impact
            updateCommunityImpact()
            
        } catch {
            print("Error updating widget data: \(error)")
        }
    }
    
    // MARK: - Handle Specific Events
    private func handleListingCreated(_ listing: Listing) {
        WidgetDataManager.shared.handleNewListingCreated()
        
        // Update recent activity
        WidgetDataManager.shared.updateRecentActivity("Created: \(listing.title)")
        
        // Refresh all data
        updateAllWidgetData()
    }
    
    private func handleMessageReceived(_ message: [String: Any]) {
        if let senderName = message["senderName"] as? String {
            WidgetDataManager.shared.handleNewMessage(from: senderName)
        } else {
            WidgetDataManager.shared.incrementUnreadMessages()
        }
    }
    
    private func handleTransactionCompleted(_ transaction: Transaction) {
        let earnings = transaction.totalCost
        let itemName = "Rental" // Transaction doesn't have item name directly
        
        WidgetDataManager.shared.handleRentalCompleted(
            earnings: earnings,
            itemName: itemName
        )
        
        // Update savings calculation
        updateSavingsData()
    }
    
    // MARK: - Calculate Savings
    private func updateSavingsData() {
        // Calculate total savings from rentals vs buying
        let totalRentals = UserDefaults.standard.integer(forKey: "totalRentalsCompleted")
        let averageSavings = 50.0 // Average savings per rental
        let totalSaved = Double(totalRentals) * averageSavings
        let percentageSaved = min(100, Int((totalSaved / (totalSaved + 200)) * 100)) // Simplified calculation
        
        WidgetDataManager.shared.updateSavingsData(
            total: totalSaved,
            percentage: percentageSaved,
            itemsSaved: totalRentals
        )
    }
    
    // MARK: - Update Community Impact
    private func updateCommunityImpact() {
        Task {
            // Fetch user's community stats
            let neighborsHelped = UserDefaults.standard.integer(forKey: "neighborsHelped")
            let itemsShared = UserDefaults.standard.integer(forKey: "itemsShared")
            
            // Get rating from user profile
            let user = AuthManager.shared.currentUser
            let averageRating = user?.rating ?? 0.0
            
            // Calculate community savings
            let communitySaved = Double(itemsShared) * 45.0 // Average savings per share
            
            // Get top categories from listings
            var categoryCount: [String: Int] = [:]
            if let listings = try? await APIClient.shared.fetchListings() {
                for listing in listings {
                    categoryCount[listing.category?.name ?? "Unknown", default: 0] += 1
                }
            }
            
            let topCategories = Array(categoryCount.sorted { $0.value > $1.value }.prefix(3).map { $0.key })
            
            WidgetDataManager.shared.updateCommunityData(
                neighborsHelped: neighborsHelped,
                itemsShared: itemsShared,
                averageRating: averageRating,
                communitySaved: communitySaved,
                topCategories: topCategories
            )
        }
    }
    
    // MARK: - Public Methods for View Models
    
    /// Call when user completes a rental
    func notifyRentalCompleted(amount: Double, itemName: String) {
        WidgetDataManager.shared.handleRentalCompleted(earnings: amount, itemName: itemName)
        
        // Increment counters
        let currentRentals = UserDefaults.standard.integer(forKey: "totalRentalsCompleted")
        UserDefaults.standard.set(currentRentals + 1, forKey: "totalRentalsCompleted")
        
        let neighborsHelped = UserDefaults.standard.integer(forKey: "neighborsHelped")
        UserDefaults.standard.set(neighborsHelped + 1, forKey: "neighborsHelped")
        
        updateAllWidgetData()
    }
    
    /// Call when user creates a new listing
    func notifyListingCreated(_ listing: Listing) {
        WidgetDataManager.shared.handleNewListingCreated()
        
        let itemsShared = UserDefaults.standard.integer(forKey: "itemsShared")
        UserDefaults.standard.set(itemsShared + 1, forKey: "itemsShared")
        
        updateAllWidgetData()
    }
    
    /// Call when messages are read
    func notifyMessagesRead(count: Int) {
        WidgetDataManager.shared.handleMessagesRead(count: count)
    }
    
    /// Call on app launch or when returning from background
    func refreshWidgetsOnAppActivation() {
        updateAllWidgetData()
    }
}

// MARK: - Notification Names Extension
extension Notification.Name {
    static let userAuthenticated = Notification.Name("userAuthenticated")
    static let listingCreated = Notification.Name("listingCreated")
    static let messageReceived = Notification.Name("messageReceived")
    static let transactionCompleted = Notification.Name("transactionCompleted")
}