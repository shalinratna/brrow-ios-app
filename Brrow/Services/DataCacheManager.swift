//
//  DataCacheManager.swift
//  Brrow
//
//  Local data caching for fast app loading
//

import Foundation
import CoreData

class DataCacheManager {
    static let shared = DataCacheManager()
    
    private let cacheQueue = DispatchQueue(label: "com.brrow.datacache", qos: .background)
    private let cacheDirectory: URL
    private let userDefaults = UserDefaults.standard
    
    // Cache keys
    private let listingsCacheKey = "cached_listings"
    private let userProfileCacheKey = "cached_user_profile"
    private let categoriesCacheKey = "cached_categories"
    private let favoritesCacheKey = "cached_favorites"
    private let messagesCacheKey = "cached_messages"
    
    // Cache expiration times (in seconds)
    private let shortCacheDuration: TimeInterval = 60 // 1 minute for featured items
    private let mediumCacheDuration: TimeInterval = 300 // 5 minutes
    private let longCacheDuration: TimeInterval = 86400 // 24 hours
    
    init() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        cacheDirectory = documentsDirectory.appendingPathComponent("BrrowCache")
        
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Listings Cache
    
    func cacheListings(_ listings: [Listing], category: String? = nil) {
        cacheQueue.async { [weak self] in
            guard let self = self else { return }
            
            let key = category != nil ? "\(self.listingsCacheKey)_\(category!)" : self.listingsCacheKey
            self.saveToCache(listings, key: key, expiration: self.mediumCacheDuration)
            
            // Also preload images for cached listings
            let imageURLs = listings.compactMap { listing in
                listing.imageUrls.first
            }
            ImageCacheManager.shared.preloadImages(imageURLs)
        }
    }
    
    func getCachedListings(category: String? = nil) -> [Listing]? {
        let key = category != nil ? "\(listingsCacheKey)_\(category!)" : listingsCacheKey
        return loadFromCache(key: key, type: [Listing].self)
    }
    
    // MARK: - User Profile Cache
    
    func cacheUserProfile(_ user: User) {
        saveToCache(user, key: userProfileCacheKey, expiration: longCacheDuration)
    }
    
    func getCachedUserProfile() -> User? {
        return loadFromCache(key: userProfileCacheKey, type: User.self)
    }
    
    // MARK: - Categories Cache
    
    func cacheCategories(_ categories: [String]) {
        saveToCache(categories, key: categoriesCacheKey, expiration: longCacheDuration)
    }
    
    func getCachedCategories() -> [String]? {
        return loadFromCache(key: categoriesCacheKey, type: [String].self)
    }
    
    // MARK: - Favorites Cache
    
    func cacheFavorites(_ favorites: [String]) {
        saveToCache(favorites, key: favoritesCacheKey, expiration: shortCacheDuration)
    }
    
    func getCachedFavorites() -> [String]? {
        return loadFromCache(key: favoritesCacheKey, type: [String].self)
    }
    
    // MARK: - Messages Cache
    
    func cacheMessages(_ messages: [ChatMessage], conversationId: String) {
        let key = "\(messagesCacheKey)_\(conversationId)"
        saveToCache(messages, key: key, expiration: shortCacheDuration)
    }
    
    func getCachedMessages(conversationId: String) -> [ChatMessage]? {
        let key = "\(messagesCacheKey)_\(conversationId)"
        return loadFromCache(key: key, type: [ChatMessage].self)
    }
    
    // MARK: - Generic Cache Methods
    
    private func saveToCache<T: Codable>(_ object: T, key: String, expiration: TimeInterval) {
        cacheQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(object)
                
                let fileURL = self.cacheDirectory.appendingPathComponent("\(key).cache")
                try data.write(to: fileURL)
                
                // Save expiration time
                self.userDefaults.set(Date().addingTimeInterval(expiration), forKey: "\(key)_expiration")
            } catch {
                print("Failed to cache data for key \(key): \(error)")
            }
        }
    }
    
    private func loadFromCache<T: Decodable>(key: String, type: T.Type) -> T? {
        // Check expiration
        if let expirationDate = userDefaults.object(forKey: "\(key)_expiration") as? Date {
            if Date() > expirationDate {
                // Cache expired, remove it
                clearCache(for: key)
                return nil
            }
        }
        
        let fileURL = cacheDirectory.appendingPathComponent("\(key).cache")
        
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            print("Failed to decode cached data for key \(key): \(error)")
            return nil
        }
    }
    
    func clearCache(for key: String? = nil) {
        cacheQueue.async { [weak self] in
            guard let self = self else { return }
            
            if let key = key {
                // Clear specific cache
                let fileURL = self.cacheDirectory.appendingPathComponent("\(key).cache")
                try? FileManager.default.removeItem(at: fileURL)
                self.userDefaults.removeObject(forKey: "\(key)_expiration")
            } else {
                // Clear all cache
                if let files = try? FileManager.default.contentsOfDirectory(at: self.cacheDirectory, includingPropertiesForKeys: nil) {
                    files.forEach { file in
                        try? FileManager.default.removeItem(at: file)
                    }
                }
                
                // Clear all expiration keys
                let keys = self.userDefaults.dictionaryRepresentation().keys.filter { $0.hasSuffix("_expiration") }
                keys.forEach { self.userDefaults.removeObject(forKey: $0) }
            }
        }
    }
    
    func getCacheSize() -> Int64 {
        var size: Int64 = 0
        
        if let files = try? FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            for file in files {
                if let attributes = try? file.resourceValues(forKeys: [.fileSizeKey]),
                   let fileSize = attributes.fileSize {
                    size += Int64(fileSize)
                }
            }
        }
        
        return size
    }
    
    func preloadEssentialData() {
        // Preload categories if not cached
        if getCachedCategories() == nil {
            Task {
                do {
                    // Fetch categories from listings endpoint
                    let categories = ["Electronics", "Tools", "Sports", "Home & Garden", "Vehicles", "Clothing", "Books", "Toys", "Other"]
                    cacheCategories(categories)
                } catch {
                    print("Failed to preload categories: \(error)")
                }
            }
        }
        
        // Preload user profile if logged in
        if AuthManager.shared.isAuthenticated,
           let userId = AuthManager.shared.currentUser?.apiId,
           getCachedUserProfile() == nil {
            Task {
                do {
                    let user = try await APIClient.shared.fetchProfile()
                    cacheUserProfile(user)
                } catch {
                    print("Failed to preload user profile: \(error)")
                }
            }
        }
    }
}