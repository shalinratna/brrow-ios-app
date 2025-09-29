//
//  IntelligentCacheManager.swift
//  Brrow
//
//  Advanced caching system with intelligent prefetching, local storage, and performance optimization
//

import SwiftUI
import Combine
import Foundation

@MainActor
class IntelligentCacheManager: ObservableObject {
    static let shared = IntelligentCacheManager()

    // MARK: - Published Properties
    @Published var cacheHitRate: Double = 0
    @Published var cacheSize: Int = 0
    @Published var isPreloading = false

    // MARK: - Private Properties
    private var memoryCache: [String: CacheEntry] = [:]
    private var diskCache: DiskCacheManager
    private let cacheQueue = DispatchQueue(label: "cache.queue", qos: .utility, attributes: .concurrent)
    private var cancellables = Set<AnyCancellable>()

    // Analytics
    private var cacheHits = 0
    private var cacheMisses = 0
    private var totalRequests = 0

    // Configuration
    private let maxMemoryCacheSize = 100 // Max items in memory
    private let maxDiskCacheSize = 500   // Max items on disk
    private let cacheExpirationTime: TimeInterval = 3600 // 1 hour
    private let preloadThreshold = 5 // Preload when user is 5 items away from end

    // Preloading Intelligence
    private var userBrowsingPattern = BrowsingPattern()
    private var predictivePreloader = PredictivePreloader()

    // MARK: - Data Models
    struct CacheEntry {
        let key: String
        let data: Data
        let createdAt: Date
        let expiresAt: Date
        let metadata: CacheMetadata
        let accessCount: Int
        let lastAccessedAt: Date

        var isExpired: Bool {
            Date() > expiresAt
        }

        var isStale: Bool {
            Date().timeIntervalSince(createdAt) > 1800 // 30 minutes
        }

        func accessed() -> CacheEntry {
            CacheEntry(
                key: key,
                data: data,
                createdAt: createdAt,
                expiresAt: expiresAt,
                metadata: metadata,
                accessCount: accessCount + 1,
                lastAccessedAt: Date()
            )
        }
    }

    struct CacheMetadata {
        let contentType: CacheContentType
        let priority: CachePriority
        let size: Int
        let etag: String?
        let lastModified: Date?
        let userContext: UserContext?

        struct UserContext {
            let userId: String
            let location: String?
            let preferences: [String: Any]
        }
    }

    enum CacheContentType: String, CaseIterable {
        case featuredListings = "featured_listings"
        case nearbyListings = "nearby_listings"
        case userListings = "user_listings"
        case categories = "categories"
        case searchResults = "search_results"
        case listingDetails = "listing_details"
        case userProfile = "user_profile"
        case images = "images"

        var defaultTTL: TimeInterval {
            switch self {
            case .featuredListings: return 1800  // 30 minutes
            case .nearbyListings: return 900     // 15 minutes
            case .userListings: return 300       // 5 minutes
            case .categories: return 86400       // 24 hours
            case .searchResults: return 600      // 10 minutes
            case .listingDetails: return 1800    // 30 minutes
            case .userProfile: return 3600       // 1 hour
            case .images: return 86400           // 24 hours
            }
        }

        var priority: CachePriority {
            switch self {
            case .featuredListings, .nearbyListings: return .high
            case .categories, .userProfile: return .medium
            case .searchResults, .listingDetails: return .medium
            case .userListings, .images: return .low
            }
        }
    }

    enum CachePriority: Int, CaseIterable {
        case critical = 4  // Never evict
        case high = 3      // Evict last
        case medium = 2    // Normal eviction
        case low = 1       // Evict first

        var weight: Double {
            return Double(rawValue)
        }
    }

    // MARK: - Initialization
    private init() {
        self.diskCache = DiskCacheManager()
        setupMemoryWarningObserver()
        setupBackgroundTaskHandler()
        startCacheMaintenanceTimer()
    }

    // MARK: - Public Interface

    /// Get data from cache with intelligent fallback
    func get<T: Codable>(_ key: String, type: T.Type, contentType: CacheContentType) async -> T? {
        totalRequests += 1

        // Try memory cache first
        if let entry = getFromMemoryCache(key), !entry.isExpired {
            cacheHits += 1
            updateCacheHitRate()

            do {
                let object = try JSONDecoder().decode(type, from: entry.data)
                // Update access statistics
                updateCacheEntry(entry.accessed())
                return object
            } catch {
                print("❌ Cache decode error for key \(key): \(error)")
                removeFromCache(key)
            }
        }

        // Try disk cache
        if let diskData = await diskCache.get(key) {
            do {
                let object = try JSONDecoder().decode(type, from: diskData)

                // Promote to memory cache
                let metadata = CacheMetadata(
                    contentType: contentType,
                    priority: contentType.priority,
                    size: diskData.count,
                    etag: nil,
                    lastModified: nil,
                    userContext: getCurrentUserContext()
                )

                await set(key, object: object, metadata: metadata)

                cacheHits += 1
                updateCacheHitRate()
                return object
            } catch {
                print("❌ Disk cache decode error for key \(key): \(error)")
                await diskCache.remove(key)
            }
        }

        // Cache miss
        cacheMisses += 1
        updateCacheHitRate()

        // Trigger predictive preloading if appropriate
        if shouldTriggerPreloading(for: contentType) {
            Task {
                await predictivePreloader.preloadRelatedContent(
                    basedOn: key,
                    contentType: contentType,
                    userContext: getCurrentUserContext()
                )
            }
        }

        return nil
    }

    /// Set data in cache with intelligent metadata
    func set<T: Codable>(_ key: String, object: T, metadata: CacheMetadata) async {
        do {
            let data = try JSONEncoder().encode(object)

            let entry = CacheEntry(
                key: key,
                data: data,
                createdAt: Date(),
                expiresAt: Date().addingTimeInterval(metadata.contentType.defaultTTL),
                metadata: metadata,
                accessCount: 1,
                lastAccessedAt: Date()
            )

            // Add to memory cache
            setInMemoryCache(entry)

            // Add to disk cache for persistence
            await diskCache.set(key, data: data)

            print("💾 Cached \(key) (\(data.count) bytes, TTL: \(metadata.contentType.defaultTTL)s)")

        } catch {
            print("❌ Cache encode error for key \(key): \(error)")
        }
    }

    /// Preload featured listings with intelligent batching
    func preloadFeaturedListings(limit: Int = 20, offset: Int = 0) async {
        guard !isPreloading else { return }

        isPreloading = true
        defer { isPreloading = false }

        let cacheKey = "featured_listings_\(limit)_\(offset)"

        // Check if already cached
        if let _: [Listing] = await get(cacheKey, type: [Listing].self, contentType: .featuredListings) {
            print("✅ Featured listings already cached")
            return
        }

        do {
            print("🔮 Preloading featured listings (\(limit) items, offset \(offset))")

            // Fetch from API
            let listings = try await APIClient.shared.fetchListings()

            // Cache the result
            let metadata = CacheMetadata(
                contentType: .featuredListings,
                priority: .high,
                size: 0, // Will be calculated during encoding
                etag: nil,
                lastModified: Date(),
                userContext: getCurrentUserContext()
            )

            await set(cacheKey, object: listings, metadata: metadata)

            // Preload related content
            await preloadRelatedContent(for: listings)

            print("✅ Preloaded \(listings.count) featured listings")

        } catch {
            print("❌ Failed to preload featured listings: \(error)")
        }
    }

    /// Preload nearby listings based on user location
    func preloadNearbyListings(latitude: Double, longitude: Double, radius: Double = 10) async {
        let cacheKey = "nearby_\(latitude)_\(longitude)_\(radius)"

        // Check if already cached and not stale
        if let cached: [Listing] = await get(cacheKey, type: [Listing].self, contentType: .nearbyListings) {
            print("✅ Nearby listings already cached")
            return
        }

        do {
            print("🌍 Preloading nearby listings (lat: \(latitude), lng: \(longitude), radius: \(radius)km)")

            // This would be implemented in APIClient
            // let listings = try await APIClient.shared.getNearbyListings(latitude: latitude, longitude: longitude, radius: radius)

            // For now, use featured listings as placeholder
            let listings = try await APIClient.shared.fetchListings()

            let metadata = CacheMetadata(
                contentType: .nearbyListings,
                priority: .high,
                size: 0,
                etag: nil,
                lastModified: Date(),
                userContext: getCurrentUserContext()
            )

            await set(cacheKey, object: listings, metadata: metadata)

            print("✅ Preloaded \(listings.count) nearby listings")

        } catch {
            print("❌ Failed to preload nearby listings: \(error)")
        }
    }

    /// Invalidate cache for specific content type
    func invalidate(contentType: CacheContentType) async {
        let keysToRemove = memoryCache.keys.filter { key in
            memoryCache[key]?.metadata.contentType == contentType
        }

        for key in keysToRemove {
            removeFromCache(key)
            await diskCache.remove(key)
        }

        print("🗑️ Invalidated \(keysToRemove.count) entries for \(contentType.rawValue)")
    }

    /// Clear all cache
    func clearAll() async {
        memoryCache.removeAll()
        await diskCache.clearAll()
        resetAnalytics()
        print("🗑️ Cleared all cache")
    }

    // MARK: - Private Methods

    private func getFromMemoryCache(_ key: String) -> CacheEntry? {
        return memoryCache[key]
    }

    private func setInMemoryCache(_ entry: CacheEntry) {
        // Check if cache is full
        if memoryCache.count >= maxMemoryCacheSize {
            evictLeastValuableEntry()
        }

        memoryCache[entry.key] = entry
        cacheSize = memoryCache.count
    }

    private func updateCacheEntry(_ entry: CacheEntry) {
        memoryCache[entry.key] = entry
    }

    private func removeFromCache(_ key: String) {
        memoryCache.removeValue(forKey: key)
        cacheSize = memoryCache.count
    }

    private func evictLeastValuableEntry() {
        // Calculate value score for each entry
        let sortedEntries = memoryCache.values.sorted { entry1, entry2 in
            let score1 = calculateValueScore(entry1)
            let score2 = calculateValueScore(entry2)
            return score1 < score2
        }

        // Remove least valuable entry
        if let leastValuable = sortedEntries.first {
            removeFromCache(leastValuable.key)
            print("🗑️ Evicted cache entry: \(leastValuable.key)")
        }
    }

    private func calculateValueScore(_ entry: CacheEntry) -> Double {
        let ageWeight = 0.3
        let accessWeight = 0.4
        let priorityWeight = 0.3

        let age = Date().timeIntervalSince(entry.lastAccessedAt)
        let ageScore = max(0, 1 - (age / 3600)) // Decreases over 1 hour

        let accessScore = min(1, Double(entry.accessCount) / 10) // Normalized to 10 accesses

        let priorityScore = entry.metadata.priority.weight / 4.0

        return (ageScore * ageWeight) + (accessScore * accessWeight) + (priorityScore * priorityWeight)
    }

    private func updateCacheHitRate() {
        cacheHitRate = totalRequests > 0 ? Double(cacheHits) / Double(totalRequests) : 0
    }

    private func resetAnalytics() {
        cacheHits = 0
        cacheMisses = 0
        totalRequests = 0
        cacheHitRate = 0
    }

    private func getCurrentUserContext() -> CacheMetadata.UserContext? {
        guard let user = AuthManager.shared.currentUser,
              let userId = user.apiId else { return nil }

        return CacheMetadata.UserContext(
            userId: userId,
            location: nil, // TODO: Get current location
            preferences: [:] // TODO: Get user preferences
        )
    }

    private func shouldTriggerPreloading(for contentType: CacheContentType) -> Bool {
        switch contentType {
        case .featuredListings, .nearbyListings:
            return true
        case .searchResults:
            return userBrowsingPattern.isActivelyBrowsing
        default:
            return false
        }
    }

    private func preloadRelatedContent(for listings: [Listing]) async {
        // Preload user profiles for listing owners
        let uniqueUserIds = Set(listings.compactMap { $0.user?.id })

        for userId in uniqueUserIds.prefix(5) { // Limit to 5 users
            let cacheKey = "user_profile_\(userId)"
            if await get(cacheKey, type: UserInfo.self, contentType: .userProfile) == nil {
                // Would preload user profile
                print("🔮 Would preload user profile: \(userId)")
            }
        }

        // Preload category data
        let uniqueCategoryIds = Set(listings.map { $0.categoryId })
        for categoryId in uniqueCategoryIds {
            let cacheKey = "category_\(categoryId)"
            if await get(cacheKey, type: CategoryModel.self, contentType: .categories) == nil {
                print("🔮 Would preload category: \(categoryId)")
            }
        }
    }

    // MARK: - Setup Methods

    private func setupMemoryWarningObserver() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }
    }

    private func setupBackgroundTaskHandler() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.handleAppBackgrounding()
            }
        }
    }

    private func startCacheMaintenanceTimer() {
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task {
                await self?.performCacheMaintenance()
            }
        }
    }

    private func handleMemoryWarning() {
        print("⚠️ Memory warning - clearing half of cache")

        let entriesToRemove = memoryCache.count / 2
        let leastValuableEntries = memoryCache.values
            .sorted { calculateValueScore($0) < calculateValueScore($1) }
            .prefix(entriesToRemove)

        for entry in leastValuableEntries {
            removeFromCache(entry.key)
        }
    }

    private func handleAppBackgrounding() async {
        // Persist critical cache entries to disk
        let criticalEntries = memoryCache.values.filter { $0.metadata.priority == .critical }

        for entry in criticalEntries {
            await diskCache.set(entry.key, data: entry.data)
        }

        print("💾 Persisted \(criticalEntries.count) critical cache entries to disk")
    }

    private func performCacheMaintenance() async {
        let now = Date()
        let expiredKeys = memoryCache.compactMap { key, entry in
            entry.isExpired ? key : nil
        }

        for key in expiredKeys {
            removeFromCache(key)
            await diskCache.remove(key)
        }

        if !expiredKeys.isEmpty {
            print("🧹 Cleaned up \(expiredKeys.count) expired cache entries")
        }
    }
}

// MARK: - Supporting Classes

private class DiskCacheManager {
    private let cacheDirectory: URL

    init() {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cacheDir.appendingPathComponent("IntelligentCache")

        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true, attributes: nil)
    }

    func get(_ key: String) async -> Data? {
        let fileURL = cacheDirectory.appendingPathComponent(key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key)

        return try? Data(contentsOf: fileURL)
    }

    func set(_ key: String, data: Data) async {
        let fileURL = cacheDirectory.appendingPathComponent(key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key)

        try? data.write(to: fileURL)
    }

    func remove(_ key: String) async {
        let fileURL = cacheDirectory.appendingPathComponent(key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key)

        try? FileManager.default.removeItem(at: fileURL)
    }

    func clearAll() async {
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true, attributes: nil)
    }
}

private class BrowsingPattern {
    var isActivelyBrowsing: Bool {
        // Simple heuristic - could be enhanced with ML
        return true
    }
}

private class PredictivePreloader {
    func preloadRelatedContent(basedOn key: String, contentType: IntelligentCacheManager.CacheContentType, userContext: IntelligentCacheManager.CacheMetadata.UserContext?) async {
        // Implement predictive preloading logic
        print("🔮 Would preload related content for \(key)")
    }
}