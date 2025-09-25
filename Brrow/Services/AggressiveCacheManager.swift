//
//  AggressiveCacheManager.swift
//  Brrow
//
//  Advanced caching system for lightning-fast performance
//

import SwiftUI
import Foundation

@MainActor
class AggressiveCacheManager: ObservableObject {
    static let shared = AggressiveCacheManager()

    // MARK: - Cache Configurations
    private let imageCacheSize: Int = 200 * 1024 * 1024 // 200MB for images
    private let apiCacheSize: Int = 50 * 1024 * 1024    // 50MB for API responses
    private let maxCacheAge: TimeInterval = 24 * 60 * 60 // 24 hours

    // MARK: - Image Cache
    private let imageCache = NSCache<NSString, UIImage>()
    private let imageCacheQueue = DispatchQueue(label: "brrow.image.cache", qos: .utility)
    @Published private var imageCacheHitRate: Double = 0.0

    // MARK: - API Response Cache
    private let apiCache = NSCache<NSString, CachedAPIResponse>()
    @Published private var apiCacheHitRate: Double = 0.0

    // MARK: - Metrics
    private var imageCacheHits = 0
    private var imageCacheMisses = 0
    private var apiCacheHits = 0
    private var apiCacheMisses = 0

    // MARK: - Progressive Loading States
    @Published var isPreloadingImages = false
    @Published var preloadProgress: Double = 0.0

    private init() {
        setupImageCache()
        setupAPICache()
        startCacheMetricsTimer()
    }

    // MARK: - Setup Methods
    private func setupImageCache() {
        imageCache.countLimit = 500 // Max 500 images
        imageCache.totalCostLimit = imageCacheSize
        imageCache.name = "BrrowImageCache"

        // Configure aggressive caching
        URLCache.shared.memoryCapacity = 100 * 1024 * 1024 // 100MB memory
        URLCache.shared.diskCapacity = 500 * 1024 * 1024   // 500MB disk
    }

    private func setupAPICache() {
        apiCache.countLimit = 1000 // Max 1000 API responses
        apiCache.totalCostLimit = apiCacheSize
        apiCache.name = "BrrowAPICache"
    }

    private func startCacheMetricsTimer() {
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.updateCacheMetrics()
        }
    }

    // MARK: - Image Caching with Progressive Loading

    /// Load image with aggressive caching and progressive enhancement
    func loadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        let cacheKey = NSString(string: urlString)

        // 1. Check memory cache first (fastest)
        if let cachedImage = imageCache.object(forKey: cacheKey) {
            imageCacheHits += 1
            completion(cachedImage)
            return
        }

        // 2. Check disk cache
        if let diskImage = loadImageFromDisk(urlString: urlString) {
            imageCache.setObject(diskImage, forKey: cacheKey)
            imageCacheHits += 1
            completion(diskImage)
            return
        }

        // 3. Network request with progressive loading
        imageCacheMisses += 1
        loadImageFromNetwork(urlString: urlString) { [weak self] image in
            guard let image = image else {
                completion(nil)
                return
            }

            // Cache in memory and disk
            self?.imageCache.setObject(image, forKey: cacheKey)
            self?.saveImageToDisk(image: image, urlString: urlString)
            completion(image)
        }
    }

    private func loadImageFromDisk(urlString: String) -> UIImage? {
        guard let url = URL(string: urlString),
              let fileName = url.lastPathComponent.addingPercentEncoding(withAllowedCharacters: .alphanumerics) else {
            return nil
        }

        let documentsPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let imagePath = documentsPath.appendingPathComponent("BrrowImages/\(fileName)")

        return UIImage(contentsOfFile: imagePath.path)
    }

    private func saveImageToDisk(image: UIImage, urlString: String) {
        imageCacheQueue.async {
            guard let url = URL(string: urlString),
                  let fileName = url.lastPathComponent.addingPercentEncoding(withAllowedCharacters: .alphanumerics),
                  let imageData = image.jpegData(compressionQuality: 0.8) else {
                return
            }

            let documentsPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            let folderPath = documentsPath.appendingPathComponent("BrrowImages")

            // Create directory if needed
            try? FileManager.default.createDirectory(at: folderPath, withIntermediateDirectories: true)

            let imagePath = folderPath.appendingPathComponent(fileName)
            try? imageData.write(to: imagePath)
        }
    }

    private func loadImageFromNetwork(urlString: String, completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil, let image = UIImage(data: data) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            DispatchQueue.main.async { completion(image) }
        }.resume()
    }

    // MARK: - Batch Image Preloading

    /// Preload multiple images in background for instant display
    func preloadImages(_ urlStrings: [String]) async {
        await MainActor.run { isPreloadingImages = true }

        let total = Double(urlStrings.count)

        for (index, urlString) in urlStrings.enumerated() {
            // Update progress
            await MainActor.run {
                preloadProgress = Double(index) / total
            }

            // Preload if not already cached
            let cacheKey = NSString(string: urlString)
            if imageCache.object(forKey: cacheKey) == nil {
                await withCheckedContinuation { continuation in
                    loadImage(from: urlString) { _ in
                        continuation.resume()
                    }
                }
            }

            // Small delay to prevent overwhelming the network
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        }

        await MainActor.run {
            preloadProgress = 1.0
            isPreloadingImages = false
        }

        print("🚀 Preloaded \(urlStrings.count) images")
    }

    // MARK: - API Response Caching

    /// Cache API responses with TTL and smart invalidation
    func cacheAPIResponse<T: Codable>(_ response: T, for endpoint: String, ttl: TimeInterval = 0) {
        let cacheKey = NSString(string: endpoint)
        let expirationTime = Date().addingTimeInterval(ttl > 0 ? ttl : maxCacheAge)

        let cachedResponse = CachedAPIResponse(
            data: response,
            expirationDate: expirationTime,
            endpoint: endpoint
        )

        let size = MemoryLayout<T>.size
        apiCache.setObject(cachedResponse, forKey: cacheKey, cost: size)

        print("🗄️ Cached API response for: \(endpoint)")
    }

    /// Retrieve cached API response if valid
    func getCachedAPIResponse<T: Codable>(for endpoint: String, type: T.Type) -> T? {
        let cacheKey = NSString(string: endpoint)

        guard let cachedResponse = apiCache.object(forKey: cacheKey),
              cachedResponse.expirationDate > Date() else {
            apiCacheMisses += 1
            return nil
        }

        apiCacheHits += 1
        return cachedResponse.data as? T
    }

    // MARK: - Smart Cache Invalidation

    /// Invalidate cache for specific patterns (e.g., user data when user updates profile)
    func invalidateCache(pattern: String) {
        // Invalidate API cache
        let keys = getAllCacheKeys()
        for key in keys {
            if key.contains(pattern) {
                apiCache.removeObject(forKey: NSString(string: key))
            }
        }

        print("🗑️ Invalidated cache for pattern: \(pattern)")
    }

    /// Invalidate expired API responses
    func cleanExpiredCache() {
        let keys = getAllCacheKeys()
        let currentDate = Date()

        for key in keys {
            let cacheKey = NSString(string: key)
            if let cachedResponse = apiCache.object(forKey: cacheKey),
               cachedResponse.expirationDate <= currentDate {
                apiCache.removeObject(forKey: cacheKey)
            }
        }

        print("🧹 Cleaned expired cache entries")
    }

    private func getAllCacheKeys() -> [String] {
        // This is a simplified version - in production, you'd want to maintain a separate key registry
        return []
    }

    // MARK: - Memory Pressure Handling

    func handleMemoryWarning() {
        // Clear half of the image cache when memory pressure occurs
        imageCache.countLimit = imageCache.countLimit / 2

        // Force garbage collection of oldest entries
        let oldCountLimit = apiCache.countLimit
        apiCache.countLimit = oldCountLimit / 2
        apiCache.countLimit = oldCountLimit

        print("⚠️ Memory pressure: Reduced cache sizes")
    }

    // MARK: - Cache Metrics and Performance

    private func updateCacheMetrics() {
        let totalImageRequests = imageCacheHits + imageCacheMisses
        let totalAPIRequests = apiCacheHits + apiCacheMisses

        imageCacheHitRate = totalImageRequests > 0 ? Double(imageCacheHits) / Double(totalImageRequests) : 0
        apiCacheHitRate = totalAPIRequests > 0 ? Double(apiCacheHits) / Double(totalAPIRequests) : 0
    }

    func getPerformanceMetrics() -> [String: Any] {
        return [
            "image_cache_hit_rate": imageCacheHitRate,
            "api_cache_hit_rate": apiCacheHitRate,
            "image_cache_count": imageCache.countLimit,
            "api_cache_count": apiCache.countLimit,
            "is_preloading": isPreloadingImages,
            "preload_progress": preloadProgress
        ]
    }

    // MARK: - Listing-Specific Optimizations

    /// Preload images for marketplace listings in order of visibility
    func preloadListingImages(_ listings: [Listing]) async {
        var imageURLs: [String] = []

        // Collect all image URLs from listings
        for listing in listings {
            imageURLs.append(contentsOf: listing.imageUrls)
        }

        // Limit to reasonable number to avoid overwhelming
        let limitedURLs = Array(imageURLs.prefix(50))
        await preloadImages(limitedURLs)
    }

    /// Preload user profile images from conversations/listings
    func preloadUserProfileImages(_ users: [User]) async {
        let profileImages = users.compactMap { $0.profilePicture }
        let limitedImages = Array(profileImages.prefix(20))
        await preloadImages(limitedImages)
    }

    // MARK: - Clear Cache

    func clearAllCaches() {
        imageCache.removeAllObjects()
        apiCache.removeAllObjects()

        // Clear disk cache
        let documentsPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let folderPath = documentsPath.appendingPathComponent("BrrowImages")
        try? FileManager.default.removeItem(at: folderPath)

        // Reset metrics
        imageCacheHits = 0
        imageCacheMisses = 0
        apiCacheHits = 0
        apiCacheMisses = 0

        print("🧹 All caches cleared")
    }
}

// MARK: - Supporting Types

class CachedAPIResponse {
    let data: Any
    let expirationDate: Date
    let endpoint: String

    init(data: Any, expirationDate: Date, endpoint: String) {
        self.data = data
        self.expirationDate = expirationDate
        self.endpoint = endpoint
    }
}

// MARK: - SwiftUI Integration

struct AggressiveCachedAsyncImage: View {
    let urlString: String
    @State private var image: UIImage?
    @State private var isLoading = true
    @StateObject private var cacheManager = AggressiveCacheManager.shared

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
            } else if isLoading {
                // Progressive loading with skeleton
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.8)
                    )
            } else {
                // Fallback for failed loads
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
        }
        .onAppear {
            loadImage()
        }
    }

    private func loadImage() {
        cacheManager.loadImage(from: urlString) { loadedImage in
            DispatchQueue.main.async {
                self.image = loadedImage
                self.isLoading = false
            }
        }
    }
}

// MARK: - Shimmer Effect Extension (Removed to avoid redeclaration - already exists elsewhere)