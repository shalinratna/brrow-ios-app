//
//  ImageCacheManager.swift
//  Brrow
//
//  Advanced image caching system with memory and disk caching
//

import SwiftUI
import Combine
import CryptoKit

class ImageCacheManager: ObservableObject {
    static let shared = ImageCacheManager()
    
    // Memory cache
    private let memoryCache = NSCache<NSString, UIImage>()
    
    // Disk cache directory
    private let diskCacheURL: URL
    
    // Image download queue
    private let downloadQueue = DispatchQueue(label: "com.brrow.imagecache", qos: .userInitiated, attributes: .concurrent)
    
    // Active downloads to prevent duplicate requests
    private var activeDownloads = [String: [((UIImage?) -> Void)]]()
    private let downloadLock = NSLock()
    
    // Cache configuration
    private let maxMemoryCacheSize = 100 * 1024 * 1024 // 100 MB
    private let maxDiskCacheSize = 500 * 1024 * 1024 // 500 MB
    private let cacheExpirationDays = 7
    
    init() {
        // Setup disk cache directory
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        diskCacheURL = cacheDirectory.appendingPathComponent("BrrowImageCache")
        
        // Create directory if needed
        try? FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
        
        // Configure memory cache
        memoryCache.countLimit = 100 // Max 100 images in memory
        memoryCache.totalCostLimit = maxMemoryCacheSize
        
        // Clean old cache on init
        cleanExpiredCache()
        
        // Listen for memory warnings
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    // MARK: - Public Methods
    
    // Check memory cache instantly
    func getFromMemoryCache(for urlString: String) -> UIImage? {
        let cacheKey = getCacheKey(for: urlString)
        return memoryCache.object(forKey: cacheKey as NSString)
    }
    
    // Check disk cache (async)
    func getFromDiskCache(for urlString: String) async -> UIImage? {
        let cacheKey = getCacheKey(for: urlString)
        return await withCheckedContinuation { continuation in
            downloadQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: nil)
                    return
                }
                let image = self.loadFromDisk(key: cacheKey)
                continuation.resume(returning: image)
            }
        }
    }
    
    // Async/await version of loadImage
    func loadImage(from urlString: String) async throws -> UIImage {
        // Check memory cache first
        if let cached = getFromMemoryCache(for: urlString) {
            return cached
        }
        
        // Check disk cache
        if let diskCached = await getFromDiskCache(for: urlString) {
            // Add to memory cache
            let cacheKey = getCacheKey(for: urlString)
            memoryCache.setObject(diskCached, forKey: cacheKey as NSString)
            return diskCached
        }
        
        // Download from network
        return try await downloadImageAsync(from: urlString)
    }
    
    // Async download method
    private func downloadImageAsync(from urlString: String) async throws -> UIImage {
        // Add base URL if the path is relative
        let fullUrlString: String
        if urlString.hasPrefix("/uploads/") || urlString.hasPrefix("uploads/") {
            // This is a relative path from our backend
            fullUrlString = "https://brrow-backend-nodejs-production.up.railway.app\(urlString.hasPrefix("/") ? "" : "/")\(urlString)"
        } else {
            fullUrlString = urlString
        }
        
        guard let url = URL(string: fullUrlString) else {
            throw NSError(domain: "ImageCache", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL: \(urlString)"])
        }
        
        let cacheKey = getCacheKey(for: urlString)
        
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        let session = URLSession(configuration: config)
        
        let (data, response) = try await session.data(from: url)
        
        guard let image = UIImage(data: data) else {
            throw NSError(domain: "ImageCache", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid image data"])
        }
        
        // Optimize and cache
        let optimizedImage = optimizeImage(image)
        memoryCache.setObject(optimizedImage, forKey: cacheKey as NSString, cost: data.count)
        saveToDisk(image: optimizedImage, key: cacheKey)
        
        return optimizedImage
    }
    
    func loadImage(from urlString: String?, completion: @escaping (UIImage?) -> Void) {
        guard let urlString = urlString, !urlString.isEmpty else {
            completion(nil)
            return
        }
        
        let cacheKey = getCacheKey(for: urlString)
        
        // Check memory cache first
        if let cachedImage = memoryCache.object(forKey: cacheKey as NSString) {
            completion(cachedImage)
            return
        }
        
        // Check disk cache
        if let diskImage = loadFromDisk(key: cacheKey) {
            memoryCache.setObject(diskImage, forKey: cacheKey as NSString, cost: diskImage.jpegData(compressionQuality: 0.8)?.count ?? 0)
            completion(diskImage)
            return
        }
        
        // Check if already downloading
        downloadLock.lock()
        if activeDownloads[cacheKey] != nil {
            activeDownloads[cacheKey]?.append(completion)
            downloadLock.unlock()
            return
        } else {
            activeDownloads[cacheKey] = [completion]
            downloadLock.unlock()
        }
        
        // Download image
        downloadImage(from: urlString, cacheKey: cacheKey)
    }
    
    func preloadImages(_ urls: [String]) {
        urls.forEach { url in
            loadImage(from: url) { _ in }
        }
    }
    
    func clearCache() {
        memoryCache.removeAllObjects()
        
        if let files = try? FileManager.default.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: nil) {
            files.forEach { file in
                try? FileManager.default.removeItem(at: file)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func downloadImage(from urlString: String, cacheKey: String) {
        // Add base URL if the path is relative
        let fullUrlString: String
        if urlString.hasPrefix("/uploads/") || urlString.hasPrefix("uploads/") {
            // This is a relative path from our backend
            fullUrlString = "https://brrow-backend-nodejs-production.up.railway.app\(urlString.hasPrefix("/") ? "" : "/")\(urlString)"
        } else {
            fullUrlString = urlString
        }
        
        print("🌐 Downloading image from: \(fullUrlString)")
        guard let url = URL(string: fullUrlString) else {
            print("❌ Invalid URL: \(urlString) -> \(fullUrlString)")
            completeDownload(for: cacheKey, with: nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("image/*", forHTTPHeaderField: "Accept")
        request.cachePolicy = .returnCacheDataElseLoad
        request.timeoutInterval = 30
        
        // Configure session for optimal performance
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.urlCache = URLCache(
            memoryCapacity: 10 * 1024 * 1024,
            diskCapacity: 50 * 1024 * 1024,
            diskPath: "brrow_images"
        )
        
        let session = URLSession(configuration: config)
        
        session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Network error downloading image: \(error.localizedDescription)")
                self.completeDownload(for: cacheKey, with: nil)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 HTTP Response code: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    print("❌ Non-200 status code for image URL")
                }
            }
            
            if let data = data, let image = UIImage(data: data) {
                print("✅ Image downloaded successfully, size: \(data.count) bytes")
                // Process and optimize image
                let optimizedImage = self.optimizeImage(image)
                
                // Save to caches
                self.memoryCache.setObject(optimizedImage, forKey: cacheKey as NSString, cost: data.count)
                self.saveToDisk(image: optimizedImage, key: cacheKey)
                
                self.completeDownload(for: cacheKey, with: optimizedImage)
            } else {
                print("❌ Failed to create UIImage from data")
                self.completeDownload(for: cacheKey, with: nil)
            }
        }.resume()
    }
    
    private func optimizeImage(_ image: UIImage) -> UIImage {
        let maxSize: CGFloat = 1024 // Max 1024 pixels on longest side
        
        let size = image.size
        let ratio = min(maxSize / size.width, maxSize / size.height)
        
        if ratio >= 1 {
            return image // Already small enough
        }
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let optimized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return optimized ?? image
    }
    
    private func completeDownload(for key: String, with image: UIImage?) {
        downloadLock.lock()
        let callbacks = activeDownloads[key] ?? []
        activeDownloads.removeValue(forKey: key)
        downloadLock.unlock()
        
        DispatchQueue.main.async {
            callbacks.forEach { $0(image) }
        }
    }
    
    private func getCacheKey(for urlString: String) -> String {
        // Create hash of URL for cache key
        let inputData = Data(urlString.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func saveToDisk(image: UIImage, key: String) {
        downloadQueue.async { [weak self] in
            guard let self = self else { return }
            
            let fileURL = self.diskCacheURL.appendingPathComponent(key)
            
            if let data = image.jpegData(compressionQuality: 0.8) {
                try? data.write(to: fileURL)
            }
        }
    }
    
    private func loadFromDisk(key: String) -> UIImage? {
        let fileURL = diskCacheURL.appendingPathComponent(key)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        // Check if expired
        if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
           let modificationDate = attributes[.modificationDate] as? Date {
            
            let expirationDate = Calendar.current.date(byAdding: .day, value: cacheExpirationDays, to: modificationDate)!
            
            if Date() > expirationDate {
                try? FileManager.default.removeItem(at: fileURL)
                return nil
            }
        }
        
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        
        return image
    }
    
    private func cleanExpiredCache() {
        downloadQueue.async { [weak self] in
            guard let self = self else { return }
            
            let fileManager = FileManager.default
            
            guard let files = try? fileManager.contentsOfDirectory(
                at: self.diskCacheURL,
                includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]
            ) else { return }
            
            var totalSize = 0
            var fileInfos: [(url: URL, date: Date, size: Int)] = []
            
            for file in files {
                guard let attributes = try? file.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey]),
                      let modificationDate = attributes.contentModificationDate,
                      let fileSize = attributes.fileSize else {
                    continue
                }
                
                // Remove expired files
                let expirationDate = Calendar.current.date(byAdding: .day, value: self.cacheExpirationDays, to: modificationDate)!
                
                if Date() > expirationDate {
                    try? fileManager.removeItem(at: file)
                } else {
                    totalSize += fileSize
                    fileInfos.append((file, modificationDate, fileSize))
                }
            }
            
            // Remove oldest files if cache is too large
            if totalSize > self.maxDiskCacheSize {
                fileInfos.sort { $0.date < $1.date }
                
                for fileInfo in fileInfos {
                    try? fileManager.removeItem(at: fileInfo.url)
                    totalSize -= fileInfo.size
                    
                    if totalSize <= self.maxDiskCacheSize {
                        break
                    }
                }
            }
        }
    }
    
    @objc private func handleMemoryWarning() {
        memoryCache.removeAllObjects()
    }
    
    // MARK: - Preloading
    
    /// Preload images for listings to improve performance
    func preloadImages(from urls: [String]) {
        downloadQueue.async { [weak self] in
            guard let self = self else { return }
            
            for urlString in urls {
                let key = self.getCacheKey(for: urlString)
                
                // Skip if already cached
                if self.memoryCache.object(forKey: key as NSString) != nil {
                    continue
                }
                
                if self.loadFromDisk(key: key) != nil {
                    continue
                }
                
                // Download in background with low priority
                self.loadImage(from: urlString) { _ in
                    // Image cached, no action needed
                }
            }
        }
    }
    
    /// Preload images for marketplace listings
    func preloadMarketplaceImages(listings: [Listing]) {
        var imageURLs: [String] = []
        
        for listing in listings.prefix(20) { // Preload first 20 listings
            if let firstImage = listing.imageUrls.first {
                imageURLs.append(firstImage)
            }
        }
        
        preloadImages(from: imageURLs)
    }
}

// MARK: - Cached Image View

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: String?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var loadFailed = false
    
    init(url: String?, 
         @ViewBuilder content: @escaping (Image) -> Content,
         @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image = image {
                content(Image(uiImage: image))
                    .onAppear {
                        print("✅ Image displayed successfully for URL: \(url ?? "nil")")
                    }
            } else if isLoading {
                ZStack {
                    Color.gray.opacity(0.1)
                    ProgressView()
                        .scaleEffect(0.8)
                }
            } else if loadFailed {
                ZStack {
                    Color.gray.opacity(0.1)
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 24))
                            .foregroundColor(.gray.opacity(0.4))
                        Text("Failed to load")
                            .font(.system(size: 12))
                            .foregroundColor(.gray.opacity(0.4))
                    }
                }
            } else {
                placeholder()
            }
        }
        .onAppear {
            loadImage()
        }
        .onChange(of: url) { _ in
            // Reload if URL changes
            image = nil
            loadFailed = false
            loadImage()
        }
    }
    
    private func loadImage() {
        guard !isLoading else { return }
        guard let urlString = url, !urlString.isEmpty else {
            print("📷 CachedAsyncImage: No URL provided")
            loadFailed = true
            return
        }
        
        print("📷 CachedAsyncImage loading URL: \(urlString)")
        
        isLoading = true
        loadFailed = false
        
        ImageCacheManager.shared.loadImage(from: urlString) { loadedImage in
            DispatchQueue.main.async {
                if let loadedImage = loadedImage {
                    print("✅ Image loaded successfully from: \(urlString)")
                    self.image = loadedImage
                    self.loadFailed = false
                } else {
                    print("❌ Failed to load image from: \(urlString)")
                    self.loadFailed = true
                }
                self.isLoading = false
            }
        }
    }
}

// MARK: - Convenience Extension
extension CachedAsyncImage where Content == AnyView, Placeholder == AnyView {
    init(url: String?, placeholder: Image = Image(systemName: "photo")) {
        self.init(
            url: url,
            content: { image in 
                AnyView(
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipped()
                )
            },
            placeholder: { 
                AnyView(
                    ZStack {
                        Color.gray.opacity(0.1)
                        placeholder
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.3))
                    }
                )
            }
        )
    }
}