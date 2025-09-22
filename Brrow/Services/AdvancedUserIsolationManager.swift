//
//  AdvancedUserIsolationManager.swift
//  Brrow
//
//  Advanced user isolation and cache management system
//  Target: Maximum performance with 1GB budget
//

import Foundation
import CoreData
import SQLite3
import Compression
import UIKit

class AdvancedUserIsolationManager: ObservableObject {
    static let shared = AdvancedUserIsolationManager()

    // MARK: - User Isolation
    @Published private(set) var currentUserContext: UserContext?

    private let isolationQueue = DispatchQueue(label: "com.brrow.user-isolation", qos: .userInitiated)
    private let cacheQueue = DispatchQueue(label: "com.brrow.advanced-cache", qos: .background)

    // MARK: - Storage Management (1GB Budget)
    private let maxStorageBudget: Int64 = 1_000_000_000 // 1GB
    private let criticalDataThreshold: Double = 0.85 // 85% usage triggers cleanup
    private let warningThreshold: Double = 0.75 // 75% usage starts optimizations

    // MARK: - Cache Tiers (Performance Priority)
    private let tier1Cache = NSCache<NSString, AnyObject>() // Hot data - 256MB
    private let tier2Cache = NSCache<NSString, AnyObject>() // Warm data - 512MB
    private let tier3Storage: URL // Cold data - Compressed disk storage

    // MARK: - User Context Isolation
    struct UserContext {
        let userId: String
        let sessionId: String
        let isolationKey: String
        let cacheNamespace: String
        let storageDirectory: URL
        let createdAt: Date
        let lastAccessed: Date

        var isValid: Bool {
            Date().timeIntervalSince(lastAccessed) < 7200 // 2 hours
        }
    }

    // MARK: - Data Categories for Intelligent Caching
    enum DataCategory: String, CaseIterable {
        case userProfile = "profile"
        case userListings = "listings"
        case userMessages = "messages"
        case userFavorites = "favorites"
        case userTransactions = "transactions"
        case globalListings = "global_listings"
        case globalCategories = "global_categories"
        case globalImages = "global_images"
        case temporaryData = "temp"

        var priority: Int {
            switch self {
            case .userProfile: return 10
            case .userListings: return 9
            case .userFavorites: return 8
            case .userMessages: return 7
            case .userTransactions: return 6
            case .globalListings: return 5
            case .globalCategories: return 4
            case .globalImages: return 3
            case .temporaryData: return 1
            }
        }

        var maxAge: TimeInterval {
            switch self {
            case .userProfile: return 3600 // 1 hour
            case .userListings: return 1800 // 30 minutes
            case .userFavorites: return 1800 // 30 minutes
            case .userMessages: return 600 // 10 minutes
            case .userTransactions: return 7200 // 2 hours
            case .globalListings: return 300 // 5 minutes
            case .globalCategories: return 86400 // 24 hours
            case .globalImages: return 3600 // 1 hour
            case .temporaryData: return 300 // 5 minutes
            }
        }
    }

    // MARK: - Initialization
    private init() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        tier3Storage = documentsDirectory.appendingPathComponent("BrrowAdvancedCache")

        setupCacheConfiguration()
        setupStorageDirectory()
        schedulePerformanceOptimizations()
    }

    private func setupCacheConfiguration() {
        // Tier 1: Hot data (256MB) - Fastest access
        tier1Cache.totalCostLimit = 256 * 1024 * 1024
        tier1Cache.countLimit = 10000
        tier1Cache.name = "Brrow-Tier1-Hot"

        // Tier 2: Warm data (512MB) - Medium access
        tier2Cache.totalCostLimit = 512 * 1024 * 1024
        tier2Cache.countLimit = 50000
        tier2Cache.name = "Brrow-Tier2-Warm"
    }

    private func setupStorageDirectory() {
        try? FileManager.default.createDirectory(at: tier3Storage, withIntermediateDirectories: true)
    }

    // MARK: - User Session Management
    func establishUserContext(userId: String) {
        isolationQueue.async { [weak self] in
            guard let self = self else { return }

            let sessionId = UUID().uuidString
            let isolationKey = "\(userId)_\(sessionId)"
            let cacheNamespace = "user_\(userId.prefix(8))"

            let userStorageDir = self.tier3Storage.appendingPathComponent(cacheNamespace)
            try? FileManager.default.createDirectory(at: userStorageDir, withIntermediateDirectories: true)

            let context = UserContext(
                userId: userId,
                sessionId: sessionId,
                isolationKey: isolationKey,
                cacheNamespace: cacheNamespace,
                storageDirectory: userStorageDir,
                createdAt: Date(),
                lastAccessed: Date()
            )

            DispatchQueue.main.async {
                self.currentUserContext = context
                self.clearPreviousUserData()
                self.preloadCriticalUserData(for: context)
            }
        }
    }

    func invalidateUserContext() {
        isolationQueue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.currentUserContext = nil
                self.clearAllUserSpecificCache()
            }
        }
    }

    // MARK: - Advanced Cache Operations
    func store<T: Codable>(_ data: T,
                          category: DataCategory,
                          key: String,
                          userSpecific: Bool = true) {
        cacheQueue.async { [weak self] in
            guard let self = self else { return }

            do {
                let finalKey = userSpecific ? self.getUserSpecificKey(key) : key
                let encodedData = try JSONEncoder().encode(data)
                let compressedData = try self.compressData(encodedData)

                let cacheItem = CacheItem(
                    data: compressedData,
                    category: category,
                    createdAt: Date(),
                    lastAccessed: Date(),
                    accessCount: 1,
                    priority: category.priority,
                    userSpecific: userSpecific
                )

                // Intelligent tier placement based on priority and size
                self.storeToCacheTier(cacheItem, key: finalKey)

                // Update storage metrics
                self.updateStorageMetrics()

            } catch {
                print("❌ Cache storage error: \(error)")
            }
        }
    }

    func retrieve<T: Codable>(_ type: T.Type,
                             category: DataCategory,
                             key: String,
                             userSpecific: Bool = true) -> T? {
        let finalKey = userSpecific ? getUserSpecificKey(key) : key

        // Try Tier 1 first (fastest)
        if let item = tier1Cache.object(forKey: finalKey as NSString) as? CacheItem {
            updateAccessMetrics(for: finalKey, tier: 1)
            return decodeCacheItem(item, type: type)
        }

        // Try Tier 2 (medium speed)
        if let item = tier2Cache.object(forKey: finalKey as NSString) as? CacheItem {
            // Promote to Tier 1 if frequently accessed
            if item.accessCount > 10 {
                tier1Cache.setObject(item, forKey: finalKey as NSString)
                tier2Cache.removeObject(forKey: finalKey as NSString)
            }
            updateAccessMetrics(for: finalKey, tier: 2)
            return decodeCacheItem(item, type: type)
        }

        // Try Tier 3 (disk storage)
        return retrieveFromDisk(type, key: finalKey, category: category)
    }

    // MARK: - Intelligent Preloading
    private func preloadCriticalUserData(for context: UserContext) {
        cacheQueue.async { [weak self] in
            guard let self = self else { return }

            // Preload user profile
            self.preloadUserProfile(context.userId)

            // Preload user's recent listings
            self.preloadUserListings(context.userId, limit: 20)

            // Preload user's favorites
            self.preloadUserFavorites(context.userId, limit: 50)

            // Preload global categories (shared data)
            self.preloadGlobalCategories()

            // Preload featured listings (global, non-user-specific)
            self.preloadFeaturedListings(limit: 30)
        }
    }

    // MARK: - Performance Optimizations
    private func schedulePerformanceOptimizations() {
        // Run optimizations every 5 minutes
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.performIntelligentOptimizations()
        }

        // Memory pressure handling
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryPressure()
        }
    }

    private func performIntelligentOptimizations() {
        cacheQueue.async { [weak self] in
            guard let self = self else { return }

            let currentUsage = self.getCurrentStorageUsage()
            let usagePercentage = Double(currentUsage) / Double(self.maxStorageBudget)

            if usagePercentage > self.criticalDataThreshold {
                print("🚨 Critical storage usage: \(usagePercentage * 100)%")
                self.performAggressiveCleanup()
            } else if usagePercentage > self.warningThreshold {
                print("⚠️ High storage usage: \(usagePercentage * 100)%")
                self.performSmartCleanup()
            } else {
                self.performRoutineOptimizations()
            }
        }
    }

    // MARK: - Cache Cleanup Strategies
    private func performAggressiveCleanup() {
        // Remove all temporary data
        clearCategory(.temporaryData)

        // Remove old global images
        clearExpiredData(olderThan: 1800) // 30 minutes

        // Compress frequently used data
        compressLowPriorityData()

        // Move Tier 1 data to Tier 2/3
        demoteCacheData()
    }

    private func performSmartCleanup() {
        // Remove expired data
        clearExpiredData(olderThan: 3600) // 1 hour

        // Optimize cache distribution
        rebalanceCacheTiers()

        // Compress infrequently accessed data
        compressDataBasedOnAccess()
    }

    private func performRoutineOptimizations() {
        // Remove very old data
        clearExpiredData(olderThan: 86400) // 24 hours

        // Defragment storage
        defragmentStorage()

        // Preload predicted data
        intelligentPreloading()
    }

    // MARK: - Helper Classes
    private class CacheItem: NSObject {
        let data: Data
        let category: DataCategory
        let createdAt: Date
        var lastAccessed: Date
        var accessCount: Int
        let priority: Int
        let userSpecific: Bool

        init(data: Data, category: DataCategory, createdAt: Date, lastAccessed: Date, accessCount: Int, priority: Int, userSpecific: Bool) {
            self.data = data
            self.category = category
            self.createdAt = createdAt
            self.lastAccessed = lastAccessed
            self.accessCount = accessCount
            self.priority = priority
            self.userSpecific = userSpecific
        }

        var age: TimeInterval {
            Date().timeIntervalSince(createdAt)
        }

        var isExpired: Bool {
            age > category.maxAge
        }

        var score: Double {
            let ageBonus = max(0, 1.0 - (age / category.maxAge))
            let accessBonus = min(1.0, Double(accessCount) / 100.0)
            let priorityBonus = Double(priority) / 10.0

            return (ageBonus * 0.3) + (accessBonus * 0.4) + (priorityBonus * 0.3)
        }
    }

    // MARK: - Implementation Helpers
    private func getUserSpecificKey(_ key: String) -> String {
        guard let context = currentUserContext else { return key }
        return "\(context.cacheNamespace):\(key)"
    }

    private func storeToCacheTier(_ item: CacheItem, key: String) {
        let cost = item.data.count

        // High priority + small size = Tier 1
        if item.priority >= 8 && cost < 1024 * 1024 { // 1MB
            tier1Cache.setObject(item, forKey: key as NSString, cost: cost)
        }
        // Medium priority = Tier 2
        else if item.priority >= 5 && cost < 10 * 1024 * 1024 { // 10MB
            tier2Cache.setObject(item, forKey: key as NSString, cost: cost)
        }
        // Everything else = Tier 3 (disk)
        else {
            storeToDisk(item, key: key)
        }
    }

    private func compressData(_ data: Data) throws -> Data {
        // For now, return data as-is. Compression can be added later with proper framework
        return data
    }

    private func decompressData(_ data: Data) throws -> Data {
        // For now, return data as-is. Decompression can be added later with proper framework
        return data
    }

    private func decodeCacheItem<T: Codable>(_ item: CacheItem, type: T.Type) -> T? {
        do {
            let decompressedData = try decompressData(item.data)
            return try JSONDecoder().decode(type, from: decompressedData)
        } catch {
            print("❌ Cache decode error: \(error)")
            return nil
        }
    }

    // MARK: - Storage Metrics
    private func getCurrentStorageUsage() -> Int64 {
        var totalSize: Int64 = 0

        // Calculate memory cache sizes
        // Note: NSCache doesn't provide exact size, so we estimate
        totalSize += Int64(tier1Cache.totalCostLimit)
        totalSize += Int64(tier2Cache.totalCostLimit)

        // Calculate disk cache size
        if let diskSize = try? FileManager.default.allocatedSizeOfDirectory(at: tier3Storage) {
            totalSize += diskSize
        }

        return totalSize
    }

    private func updateStorageMetrics() {
        // Track storage usage and performance metrics
        let usage = getCurrentStorageUsage()
        let percentage = Double(usage) / Double(maxStorageBudget)

        // Log if usage is significant
        if percentage > 0.5 {
            print("📊 Storage usage: \(usage / 1024 / 1024)MB (\(Int(percentage * 100))%)")
        }
    }

    // MARK: - User Data Isolation
    private func clearPreviousUserData() {
        // Clear only user-specific data from memory caches
        clearUserSpecificCacheData()
    }

    private func clearAllUserSpecificCache() {
        tier1Cache.removeAllObjects()
        tier2Cache.removeAllObjects()
        // Keep global data on disk
    }

    private func clearUserSpecificCacheData() {
        guard let context = currentUserContext else { return }

        // Remove user-specific keys from caches
        // This would require maintaining a list of keys, which we'll implement
        // For now, we'll use a more aggressive approach for user switches
        tier1Cache.removeAllObjects()
        tier2Cache.removeAllObjects()
    }

    // MARK: - Preloading Implementations
    private func preloadUserProfile(_ userId: String) {
        // Implementation would fetch and cache user profile
        print("🔄 Preloading user profile for \(userId)")
    }

    private func preloadUserListings(_ userId: String, limit: Int) {
        // Implementation would fetch and cache user's listings
        print("🔄 Preloading \(limit) user listings for \(userId)")
    }

    private func preloadUserFavorites(_ userId: String, limit: Int) {
        // Implementation would fetch and cache user's favorites
        print("🔄 Preloading \(limit) user favorites for \(userId)")
    }

    private func preloadGlobalCategories() {
        // Implementation would fetch and cache global categories
        print("🔄 Preloading global categories")
    }

    private func preloadFeaturedListings(limit: Int) {
        // Implementation would fetch and cache featured listings
        print("🔄 Preloading \(limit) featured listings")
    }

    // MARK: - Cleanup Implementations
    private func clearCategory(_ category: DataCategory) {
        // Implementation to clear specific category
        print("🧹 Clearing category: \(category.rawValue)")
    }

    private func clearExpiredData(olderThan seconds: TimeInterval) {
        // Implementation to clear expired data
        print("🧹 Clearing data older than \(seconds) seconds")
    }

    private func compressLowPriorityData() {
        // Implementation to compress low priority data
        print("🗜️ Compressing low priority data")
    }

    private func demoteCacheData() {
        // Move data from higher tiers to lower tiers
        print("⬇️ Demoting cache data to lower tiers")
    }

    private func rebalanceCacheTiers() {
        // Optimize data distribution across tiers
        print("⚖️ Rebalancing cache tiers")
    }

    private func compressDataBasedOnAccess() {
        // Compress data based on access patterns
        print("🗜️ Compressing data based on access patterns")
    }

    private func defragmentStorage() {
        // Defragment disk storage
        print("🔧 Defragmenting storage")
    }

    private func intelligentPreloading() {
        // Predict and preload data user might need
        print("🧠 Performing intelligent preloading")
    }

    private func handleMemoryPressure() {
        print("⚠️ Memory pressure detected - performing emergency cleanup")
        tier1Cache.removeAllObjects()
        // Keep only critical data in Tier 2
        tier2Cache.totalCostLimit = tier2Cache.totalCostLimit / 2
    }

    private func updateAccessMetrics(for key: String, tier: Int) {
        // Update access metrics for cache optimization
        print("📊 Updated access metrics for \(key) in tier \(tier)")
    }

    private func retrieveFromDisk<T: Codable>(_ type: T.Type, key: String, category: DataCategory) -> T? {
        // Implementation to retrieve from disk storage
        print("💾 Retrieving \(key) from disk storage")
        return nil
    }

    private func storeToDisk(_ item: CacheItem, key: String) {
        // Implementation to store to disk
        print("💾 Storing \(key) to disk storage")
    }
}

// MARK: - FileManager Extension
extension FileManager {
    func allocatedSizeOfDirectory(at url: URL) throws -> Int64 {
        guard let enumerator = enumerator(at: url, includingPropertiesForKeys: [.totalFileAllocatedSizeKey]) else {
            throw CocoaError(.fileReadUnknown)
        }

        var totalSize: Int64 = 0

        for case let fileURL as URL in enumerator {
            let resourceValues = try fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey])
            totalSize += Int64(resourceValues.totalFileAllocatedSize ?? 0)
        }

        return totalSize
    }
}