//
//  OfflineManager.swift
//  Brrow
//
//  Offline Support and Data Caching
//

import Foundation
import Combine
import Network
import CoreData

@MainActor
class OfflineManager: ObservableObject {
    static let shared = OfflineManager()
    
    @Published var isOnline = true
    @Published var hasPendingSync = false
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var cancellables = Set<AnyCancellable>()
    
    // Cache storage
    private let cache = NSCache<NSString, NSData>()
    private let imageCache = NSCache<NSString, NSData>()
    private let userDefaults = UserDefaults.standard
    
    // Core Data context for offline storage
    private lazy var context: NSManagedObjectContext? = {
        return PersistenceController.shared.container.viewContext
    }()
    
    init() {
        setupNetworkMonitoring()
        setupCache()
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isOnline = path.status == .satisfied
                
                if path.status == .satisfied {
                    self?.syncPendingData()
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    // MARK: - Cache Setup
    
    private func setupCache() {
        // Configure cache limits
        cache.countLimit = 1000
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        
        imageCache.countLimit = 500
        imageCache.totalCostLimit = 100 * 1024 * 1024 // 100MB
    }
    
    // MARK: - Data Caching
    
    func cacheData<T: Codable>(_ data: T, forKey key: String, expiration: TimeInterval = 3600) {
        do {
            let encoded = try JSONEncoder().encode(data)
            let cacheItem = CacheItem(data: encoded, expiration: Date().addingTimeInterval(expiration))
            let itemData = try JSONEncoder().encode(cacheItem)
            
            cache.setObject(itemData as NSData, forKey: key as NSString)
            
            // Also store in UserDefaults for persistence
            userDefaults.set(itemData, forKey: "cache_\(key)")
        } catch {
            print("Failed to cache data for key \(key): \(error)")
        }
    }
    
    func getCachedData<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        // First check in-memory cache
        if let cached = cache.object(forKey: key as NSString) {
            return decodeCacheItem(type, from: cached as Data)
        }
        
        // Fallback to UserDefaults
        if let persistedData = userDefaults.data(forKey: "cache_\(key)") {
            let decoded = decodeCacheItem(type, from: persistedData)
            
            // Re-add to memory cache if valid
            if decoded != nil {
                cache.setObject(persistedData as NSData, forKey: key as NSString)
            }
            
            return decoded
        }
        
        return nil
    }
    
    private func decodeCacheItem<T: Codable>(_ type: T.Type, from data: Data) -> T? {
        do {
            let cacheItem = try JSONDecoder().decode(CacheItem.self, from: data)
            
            // Check if expired
            if cacheItem.expiration < Date() {
                return nil
            }
            
            return try JSONDecoder().decode(type, from: cacheItem.data)
        } catch {
            return nil
        }
    }
    
    // MARK: - Image Caching
    
    func cacheImage(_ data: Data, forURL url: String) {
        let key = url.md5
        imageCache.setObject(data as NSData, forKey: key as NSString)
        
        // Persist to disk
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let imagePath = documentsPath.appendingPathComponent("images").appendingPathComponent("\(key).data")
        
        try? FileManager.default.createDirectory(at: imagePath.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: imagePath)
    }
    
    func getCachedImage(forURL url: String) -> Data? {
        let key = url.md5
        
        // Check memory cache first
        if let cached = imageCache.object(forKey: key as NSString) {
            return cached as Data
        }
        
        // Check disk cache
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let imagePath = documentsPath.appendingPathComponent("images").appendingPathComponent("\(key).data")
        
        if let diskData = try? Data(contentsOf: imagePath) {
            imageCache.setObject(diskData as NSData, forKey: key as NSString)
            return diskData
        }
        
        return nil
    }
    
    // MARK: - Offline Data Storage
    
    func storeOfflineAction(_ action: OfflineAction) {
        guard let context = context else {
            print("⚠️ CoreData context not available")
            return
        }
        do {
            let offlineAction = OfflineActionEntity(context: context)
            offlineAction.id = UUID(uuidString: action.id) ?? UUID()
            offlineAction.actionType = action.type.rawValue
            offlineAction.payload = try JSONEncoder().encode(action.data)
            offlineAction.createdAt = action.timestamp
            offlineAction.retryCount = Int16(action.retryCount)
            offlineAction.syncStatus = "pending"
            
            try context.save()
            hasPendingSync = true
        } catch {
            print("Failed to store offline action: \(error)")
        }
    }
    
    private func getPendingActions() -> [OfflineAction] {
        guard let context = context else {
            print("⚠️ CoreData context not available")
            return []
        }
        
        let request: NSFetchRequest<OfflineActionEntity> = OfflineActionEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        
        do {
            let entities = try context.fetch(request)
            return entities.compactMap { entity in
                guard let id = entity.id,
                      let typeString = entity.actionType,
                      let type = OfflineActionType(rawValue: typeString),
                      let data = entity.payload,
                      let timestamp = entity.createdAt else {
                    return nil
                }
                
                return OfflineAction(
                    id: id.uuidString,
                    type: type,
                    data: data,
                    timestamp: timestamp,
                    retryCount: Int(entity.retryCount)
                )
            }
        } catch {
            print("Failed to fetch pending actions: \(error)")
            return []
        }
    }
    
    // MARK: - Data Synchronization
    
    private func syncPendingData() {
        guard isOnline else { return }
        
        let pendingActions = getPendingActions()
        guard !pendingActions.isEmpty else {
            hasPendingSync = false
            return
        }
        
        Task {
            for action in pendingActions {
                do {
                    try await processOfflineAction(action)
                    await removeOfflineAction(action.id)
                } catch {
                    // Increment retry count
                    await incrementRetryCount(action.id)
                    print("Failed to sync action \(action.id): \(error)")
                }
            }
            
            // Check if any actions remain
            let remainingActions = getPendingActions()
            hasPendingSync = !remainingActions.isEmpty
        }
    }
    
    private func processOfflineAction(_ action: OfflineAction) async throws {
        switch action.type {
        case .createListing:
            try await processCreateListing(action.data)
        case .updateListing:
            try await processUpdateListing(action.data)
        case .sendMessage:
            try await processSendMessage(action.data)
        case .createReview:
            try await processCreateReview(action.data)
        case .updateProfile:
            try await processUpdateProfile(action.data)
        }
    }
    
    private func removeOfflineAction(_ id: String) async {
        guard let context = context else {
            print("⚠️ CoreData context not available")
            return
        }
        
        let request: NSFetchRequest<OfflineActionEntity> = OfflineActionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        
        do {
            let entities = try context.fetch(request)
            for entity in entities {
                context.delete(entity)
            }
            try context.save()
        } catch {
            print("Failed to remove offline action: \(error)")
        }
    }
    
    private func incrementRetryCount(_ id: String) async {
        guard let context = context else {
            print("⚠️ CoreData context not available")
            return
        }
        
        let request: NSFetchRequest<OfflineActionEntity> = OfflineActionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        
        do {
            let entities = try context.fetch(request)
            for entity in entities {
                entity.retryCount += 1
                
                // Remove if retry count exceeds limit
                if entity.retryCount > 5 {
                    context.delete(entity)
                }
            }
            try context.save()
        } catch {
            print("Failed to increment retry count: \(error)")
        }
    }
    
    // MARK: - Action Processors
    
    private func processCreateListing(_ data: Data) async throws {
        // Process with APIClient - data contains the raw action data
        print("Processing create listing offline action")
        // In a real implementation, would decode specific structs and call API
    }
    
    private func processUpdateListing(_ data: Data) async throws {
        // Decode and send to API
        print("Processing update listing offline action")
    }
    
    private func processSendMessage(_ data: Data) async throws {
        // Decode and send to API
        print("Processing send message offline action")
    }
    
    private func processCreateReview(_ data: Data) async throws {
        // Decode and send to API
        print("Processing create review offline action")
    }
    
    private func processUpdateProfile(_ data: Data) async throws {
        // Decode and send to API
        print("Processing update profile offline action")
    }
    
    // MARK: - Cache Management
    
    func clearCache() {
        cache.removeAllObjects()
        imageCache.removeAllObjects()
        
        // Clear UserDefaults cache
        let keys = userDefaults.dictionaryRepresentation().keys.filter { $0.hasPrefix("cache_") }
        for key in keys {
            userDefaults.removeObject(forKey: key)
        }
        
        // Clear disk image cache
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let imagesPath = documentsPath.appendingPathComponent("images")
        try? FileManager.default.removeItem(at: imagesPath)
    }
    
    func getCacheSize() -> Int64 {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let imagesPath = documentsPath.appendingPathComponent("images")
        
        var size: Int64 = 0
        
        if let enumerator = FileManager.default.enumerator(at: imagesPath, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    size += Int64(fileSize)
                }
            }
        }
        
        return size
    }
}

// MARK: - Supporting Models

struct CacheItem: Codable {
    let data: Data
    let expiration: Date
}

struct OfflineAction {
    let id: String
    let type: OfflineActionType
    let data: Data
    let timestamp: Date
    let retryCount: Int
}

enum OfflineActionType: String, CaseIterable {
    case createListing = "create_listing"
    case updateListing = "update_listing"
    case sendMessage = "send_message"
    case createReview = "create_review"
    case updateProfile = "update_profile"
}

// MARK: - String Extension

extension String {
    var md5: String {
        // Simple hash for cache keys
        return String(self.hashValue)
    }
}

// MARK: - Codable Extension for Any

// Note: Using Data directly for offline actions to avoid Codable complexity with Any type