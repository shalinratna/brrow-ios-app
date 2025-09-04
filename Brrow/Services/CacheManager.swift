//
//  CacheManager.swift
//  Brrow
//
//  Professional caching system inspired by Instagram/Pinterest's cache architecture
//  Implements multi-layer caching with memory, disk, and network fallback
//

import Foundation
import UIKit
import CryptoKit

// MARK: - Cache Policy
enum CachePolicy {
    case ignoreCache           // Always fetch fresh data
    case cacheFirst           // Use cache if available, then network
    case networkFirst         // Try network first, fallback to cache
    case cacheOnly           // Only use cached data
    case refreshCache        // Fetch new data and update cache
}

// MARK: - Cache Expiration
enum CacheExpiration {
    case never
    case seconds(TimeInterval)
    case minutes(Int)
    case hours(Int)
    case days(Int)
    case custom(Date)
    
    var expirationDate: Date {
        switch self {
        case .never:
            return Date.distantFuture
        case .seconds(let seconds):
            return Date().addingTimeInterval(seconds)
        case .minutes(let minutes):
            return Date().addingTimeInterval(TimeInterval(minutes * 60))
        case .hours(let hours):
            return Date().addingTimeInterval(TimeInterval(hours * 3600))
        case .days(let days):
            return Date().addingTimeInterval(TimeInterval(days * 86400))
        case .custom(let date):
            return date
        }
    }
}

// MARK: - Cache Entry
struct CacheEntry<T: Codable>: Codable {
    let data: T
    let timestamp: Date
    let expirationDate: Date
    let etag: String?
    
    var isExpired: Bool {
        return Date() > expirationDate
    }
}

// MARK: - Cache Manager
class CacheManager {
    static let shared = CacheManager()
    
    // Memory cache using NSCache for automatic memory management
    private let memoryCache = NSCache<NSString, AnyObject>()
    
    // Disk cache directory
    private let diskCacheURL: URL
    
    // Cache configuration
    private let maxMemoryCost = 50 * 1024 * 1024 // 50MB
    private let maxDiskSize = 200 * 1024 * 1024 // 200MB
    
    // Queue for disk operations
    private let diskQueue = DispatchQueue(label: "com.brrow.cache.disk", attributes: .concurrent)
    
    // Cache statistics
    private var cacheHits = 0
    private var cacheMisses = 0
    
    init() {
        // Setup memory cache
        memoryCache.totalCostLimit = maxMemoryCost
        memoryCache.countLimit = 1000
        
        // Setup disk cache directory
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        diskCacheURL = cacheDirectory.appendingPathComponent("BrrowCache")
        
        // Create cache directory if needed
        try? FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
        
        // Start cache cleanup
        startCacheCleanup()
    }
    
    // MARK: - Public API
    
    /// Save data to cache
    func save<T: Codable>(_ object: T, forKey key: String, expiration: CacheExpiration = .hours(24), etag: String? = nil) {
        let entry = CacheEntry(
            data: object,
            timestamp: Date(),
            expirationDate: expiration.expirationDate,
            etag: etag
        )
        
        // Save to memory cache
        let cost = MemoryLayout<T>.size(ofValue: object)
        memoryCache.setObject(entry as AnyObject, forKey: key as NSString, cost: cost)
        
        // Save to disk cache asynchronously
        diskQueue.async(flags: .barrier) { [weak self] in
            self?.saveToDisk(entry, forKey: key)
        }
    }
    
    /// Load data from cache
    func load<T: Codable>(_ type: T.Type, forKey key: String, policy: CachePolicy = .cacheFirst) -> T? {
        switch policy {
        case .ignoreCache:
            return nil
            
        case .cacheFirst, .cacheOnly:
            // Try memory cache first
            if let entry = memoryCache.object(forKey: key as NSString) as? CacheEntry<T> {
                if !entry.isExpired {
                    cacheHits += 1
                    print("📦 Cache hit (memory): \(key)")
                    return entry.data
                } else {
                    memoryCache.removeObject(forKey: key as NSString)
                }
            }
            
            // Try disk cache
            if let entry = loadFromDisk(type, forKey: key) {
                if !entry.isExpired {
                    // Restore to memory cache
                    let cost = MemoryLayout<T>.size(ofValue: entry.data)
                    memoryCache.setObject(entry as AnyObject, forKey: key as NSString, cost: cost)
                    cacheHits += 1
                    print("📦 Cache hit (disk): \(key)")
                    return entry.data
                } else {
                    // Remove expired entry
                    removeDiskCache(forKey: key)
                }
            }
            
            cacheMisses += 1
            print("📦 Cache miss: \(key)")
            return nil
            
        case .networkFirst, .refreshCache:
            // These policies should fetch from network first
            return nil
        }
    }
    
    /// Remove specific cache entry
    func remove(forKey key: String) {
        memoryCache.removeObject(forKey: key as NSString)
        removeDiskCache(forKey: key)
    }
    
    /// Clear all cache
    func clearAll() {
        memoryCache.removeAllObjects()
        clearDiskCache()
    }
    
    /// Get cache size
    func getCacheSize() -> (memory: Int, disk: Int) {
        let diskSize = calculateDiskCacheSize()
        return (memory: 0, disk: diskSize) // NSCache doesn't expose current size
    }
    
    /// Cache statistics
    func getCacheStatistics() -> (hits: Int, misses: Int, hitRate: Double) {
        let total = cacheHits + cacheMisses
        let hitRate = total > 0 ? Double(cacheHits) / Double(total) : 0
        return (hits: cacheHits, misses: cacheMisses, hitRate: hitRate)
    }
    
    // MARK: - Image Caching
    
    /// Cache image data
    func cacheImage(_ image: UIImage, forURL url: String, expiration: CacheExpiration = .days(7)) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        let key = cacheKey(for: url)
        save(data, forKey: key, expiration: expiration)
    }
    
    /// Load cached image
    func loadCachedImage(forURL url: String) -> UIImage? {
        let key = cacheKey(for: url)
        
        if let data = load(Data.self, forKey: key) {
            return UIImage(data: data)
        }
        return nil
    }
    
    // MARK: - API Response Caching
    
    /// Cache API response with ETag support
    func cacheAPIResponse<T: Codable>(_ response: T, endpoint: String, parameters: [String: Any]? = nil, expiration: CacheExpiration = .minutes(30), etag: String? = nil) {
        let key = apiCacheKey(endpoint: endpoint, parameters: parameters)
        save(response, forKey: key, expiration: expiration, etag: etag)
    }
    
    /// Load cached API response
    func loadCachedAPIResponse<T: Codable>(_ type: T.Type, endpoint: String, parameters: [String: Any]? = nil) -> (data: T?, etag: String?) {
        let key = apiCacheKey(endpoint: endpoint, parameters: parameters)
        
        if let entry = memoryCache.object(forKey: key as NSString) as? CacheEntry<T> {
            if !entry.isExpired {
                return (data: entry.data, etag: entry.etag)
            }
        }
        
        if let entry = loadFromDisk(type, forKey: key) {
            if !entry.isExpired {
                return (data: entry.data, etag: entry.etag)
            }
        }
        
        return (data: nil, etag: nil)
    }
    
    // MARK: - Private Methods
    
    private func saveToDisk<T: Codable>(_ entry: CacheEntry<T>, forKey key: String) {
        let fileURL = diskCacheURL.appendingPathComponent(key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key)
        
        do {
            let data = try JSONEncoder().encode(entry)
            try data.write(to: fileURL)
        } catch {
            print("❌ Failed to save to disk cache: \(error)")
        }
    }
    
    private func loadFromDisk<T: Codable>(_ type: T.Type, forKey key: String) -> CacheEntry<T>? {
        let fileURL = diskCacheURL.appendingPathComponent(key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key)
        
        do {
            let data = try Data(contentsOf: fileURL)
            let entry = try JSONDecoder().decode(CacheEntry<T>.self, from: data)
            return entry
        } catch {
            return nil
        }
    }
    
    private func removeDiskCache(forKey key: String) {
        let fileURL = diskCacheURL.appendingPathComponent(key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key)
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    private func clearDiskCache() {
        try? FileManager.default.removeItem(at: diskCacheURL)
        try? FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
    }
    
    private func calculateDiskCacheSize() -> Int {
        var size = 0
        
        if let files = try? FileManager.default.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: [.fileSizeKey]) {
            for file in files {
                if let fileSize = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    size += fileSize
                }
            }
        }
        
        return size
    }
    
    private func cacheKey(for urlString: String) -> String {
        // Use SHA256 hash for consistent key generation
        let inputData = Data(urlString.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    func apiCacheKey(endpoint: String, parameters: [String: Any]?) -> String {
        var keyString = endpoint
        
        if let params = parameters {
            let sortedParams = params.sorted { $0.key < $1.key }
            let paramString = sortedParams.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
            keyString += "?" + paramString
        }
        
        return cacheKey(for: keyString)
    }
    
    // MARK: - Cache Cleanup
    
    private func startCacheCleanup() {
        // Run cleanup every hour
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            self?.performCacheCleanup()
        }
        
        // Also cleanup on memory warning
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc private func handleMemoryWarning() {
        // Clear 50% of memory cache on memory warning
        memoryCache.totalCostLimit = maxMemoryCost / 2
        
        // Restore limit after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            self?.memoryCache.totalCostLimit = self?.maxMemoryCost ?? 0
        }
    }
    
    private func performCacheCleanup() {
        diskQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            // Remove expired items
            if let files = try? FileManager.default.contentsOfDirectory(at: self.diskCacheURL, includingPropertiesForKeys: [.contentModificationDateKey]) {
                for file in files {
                    // Try to load and check expiration
                    if let data = try? Data(contentsOf: file),
                       let entry = try? JSONDecoder().decode(CacheEntry<Data>.self, from: data),
                       entry.isExpired {
                        try? FileManager.default.removeItem(at: file)
                    }
                }
            }
            
            // Check total size and remove oldest if needed
            if self.calculateDiskCacheSize() > self.maxDiskSize {
                self.removeOldestDiskCacheFiles()
            }
        }
    }
    
    private func removeOldestDiskCacheFiles() {
        if let files = try? FileManager.default.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]) {
            let sortedFiles = files.sorted { file1, file2 in
                let date1 = (try? file1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                let date2 = (try? file2.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                return date1 < date2
            }
            
            var currentSize = calculateDiskCacheSize()
            let targetSize = maxDiskSize * 3 / 4 // Remove until 75% of max
            
            for file in sortedFiles {
                if currentSize <= targetSize { break }
                
                if let fileSize = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    try? FileManager.default.removeItem(at: file)
                    currentSize -= fileSize
                }
            }
        }
    }
}

// MARK: - Cacheable Protocol
protocol Cacheable: Codable {
    static var cacheKey: String { get }
    static var cacheExpiration: CacheExpiration { get }
}

// Default implementation
extension Cacheable {
    static var cacheExpiration: CacheExpiration {
        return .hours(1)
    }
}