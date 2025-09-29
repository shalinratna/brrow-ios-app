//
//  IntelligentImageProcessor.swift
//  Brrow
//
//  Advanced image processing with predictive preloading and memory optimization
//

import SwiftUI
import Combine
import UIKit

@MainActor
class IntelligentImageProcessor: ObservableObject {
    static let shared = IntelligentImageProcessor()

    // MARK: - Published Properties
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0
    @Published var processedImageCount = 0
    @Published var totalImageCount = 0

    // MARK: - Private Properties
    private var processingTasks: [String: Task<ProcessedImageSet, Error>] = [:]
    private var processedImageCache: [String: ProcessedImageSet] = [:]
    private var memoryPressureObserver: NSObjectProtocol?

    // Configuration
    private let maxCacheSize = 50 // Maximum processed images to keep in memory
    private let compressionQueue = DispatchQueue(label: "image.compression", qos: .userInitiated, attributes: .concurrent)
    private let processingQueue = DispatchQueue(label: "image.processing", qos: .userInitiated, attributes: .concurrent)

    // MARK: - Data Models
    struct ProcessedImageSet {
        let id: String
        let originalImage: UIImage
        let optimizedImage: UIImage
        let base64Data: String
        let compressionQuality: CGFloat
        let finalSize: Int
        let processingTime: TimeInterval
        let isReady: Bool

        var memoryFootprint: Int {
            // Estimate memory usage
            let originalBytes = Int(originalImage.size.width * originalImage.size.height * 4)
            let optimizedBytes = Int(optimizedImage.size.width * optimizedImage.size.height * 4)
            let base64Bytes = base64Data.count
            return originalBytes + optimizedBytes + base64Bytes
        }
    }

    struct ProcessingConfiguration {
        let maxDimension: CGFloat
        let targetFileSize: Int
        let minCompressionQuality: CGFloat
        let maxCompressionQuality: CGFloat
        let enablePredictiveProcessing: Bool

        static let highQuality = ProcessingConfiguration(
            maxDimension: 2048,
            targetFileSize: 3 * 1024 * 1024, // 3MB for better quality
            minCompressionQuality: 0.85,
            maxCompressionQuality: 0.95,
            enablePredictiveProcessing: true
        )

        static let balanced = ProcessingConfiguration(
            maxDimension: 1440,
            targetFileSize: 1 * 1024 * 1024, // 1MB
            minCompressionQuality: 0.65,
            maxCompressionQuality: 0.85,
            enablePredictiveProcessing: true
        )

        static let fast = ProcessingConfiguration(
            maxDimension: 1080,
            targetFileSize: 512 * 1024, // 512KB
            minCompressionQuality: 0.60,
            maxCompressionQuality: 0.80,
            enablePredictiveProcessing: true
        )
    }

    // MARK: - Initialization
    private init() {
        setupMemoryPressureMonitoring()
    }

    deinit {
        if let observer = memoryPressureObserver {
            NotificationCenter.default.removeObserver(observer)
        }

        // Cancel all processing tasks
        processingTasks.values.forEach { $0.cancel() }
    }

    // MARK: - Public Interface

    /// Start predictive processing of images as user selects them
    func startPredictiveProcessing(images: [UIImage], configuration: ProcessingConfiguration = .highQuality) {
        guard configuration.enablePredictiveProcessing else { return }

        print("🔮 Starting predictive processing for \(images.count) images")

        Task {
            await processImagesInBackground(images: images, configuration: configuration)
        }
    }

    /// Get processed images immediately if ready, or start processing if not
    func getProcessedImages(for images: [UIImage], configuration: ProcessingConfiguration = .highQuality) async throws -> [ProcessedImageSet] {
        print("📤 Requesting processed images for \(images.count) images")

        var results: [ProcessedImageSet] = []
        var imagesToProcess: [UIImage] = []

        // Check cache first
        for image in images {
            let imageId = generateImageId(for: image)

            if let cached = processedImageCache[imageId] {
                print("💨 Cache hit for image \(imageId)")
                results.append(cached)
            } else {
                imagesToProcess.append(image)
            }
        }

        // Process remaining images
        if !imagesToProcess.isEmpty {
            let newlyProcessed = await processImagesInBackground(images: imagesToProcess, configuration: configuration)
            results.append(contentsOf: newlyProcessed)
        }

        return results
    }

    /// Cancel processing for specific images
    func cancelProcessing(for images: [UIImage]) {
        for image in images {
            let imageId = generateImageId(for: image)
            processingTasks[imageId]?.cancel()
            processingTasks.removeValue(forKey: imageId)
        }

        updateProcessingState()
    }

    /// Clear all cached processed images
    func clearCache() {
        processedImageCache.removeAll()
        processingTasks.values.forEach { $0.cancel() }
        processingTasks.removeAll()

        print("🗑️ Cleared image processing cache")
    }

    // MARK: - Private Methods

    private func processImagesInBackground(images: [UIImage], configuration: ProcessingConfiguration) async -> [ProcessedImageSet] {
        isProcessing = true
        totalImageCount = images.count
        processedImageCount = 0

        return await withTaskGroup(of: ProcessedImageSet?.self, returning: [ProcessedImageSet].self) { group in

            for (index, image) in images.enumerated() {
                let imageId = generateImageId(for: image)

                // Skip if already processing or cached
                if processingTasks[imageId] != nil || processedImageCache[imageId] != nil {
                    continue
                }

                group.addTask { [weak self] in
                    guard let self = self else { return nil }

                    let task = Task<ProcessedImageSet, Error> {
                        return try await self.processImage(image, configuration: configuration)
                    }

                    await MainActor.run {
                        self.processingTasks[imageId] = task
                    }

                    do {
                        let result = try await task.value

                        await MainActor.run {
                            self.processedImageCache[imageId] = result
                            self.processingTasks.removeValue(forKey: imageId)
                            self.processedImageCount += 1
                            self.processingProgress = Double(self.processedImageCount) / Double(self.totalImageCount)

                            print("✅ Processed image \(index + 1)/\(images.count) (\(result.finalSize / 1024)KB)")
                        }

                        return result
                    } catch {
                        await MainActor.run {
                            self.processingTasks.removeValue(forKey: imageId)
                        }

                        print("❌ Failed to process image \(index + 1): \(error)")
                        return nil
                    }
                }
            }

            var processedImages: [ProcessedImageSet] = []
            for await result in group {
                if let processed = result {
                    processedImages.append(processed)
                }
            }

            await MainActor.run {
                self.isProcessing = false
                self.manageCacheSize()
            }

            return processedImages
        }
    }

    private func processImage(_ image: UIImage, configuration: ProcessingConfiguration) async throws -> ProcessedImageSet {
        let startTime = CFAbsoluteTimeGetCurrent()
        let imageId = generateImageId(for: image)

        return try await withCheckedThrowingContinuation { continuation in
            processingQueue.async {
                let originalSize = image.size

                // Resize image while maintaining aspect ratio
                let resizedImage = self.resizeImage(image, maxDimension: configuration.maxDimension)

                // Find optimal compression quality
                let (finalData, quality) = self.findOptimalCompression(
                    image: resizedImage,
                    targetSize: configuration.targetFileSize,
                    minQuality: configuration.minCompressionQuality,
                    maxQuality: configuration.maxCompressionQuality
                )

                guard let imageData = finalData else {
                    continuation.resume(throwing: IntelligentProcessingError.compressionFailed)
                    return
                }

                let base64String = imageData.base64EncodedString()
                let processingTime = CFAbsoluteTimeGetCurrent() - startTime

                let processedSet = ProcessedImageSet(
                    id: imageId,
                    originalImage: image,
                    optimizedImage: UIImage(data: imageData) ?? resizedImage,
                    base64Data: base64String,
                    compressionQuality: quality,
                    finalSize: imageData.count,
                    processingTime: processingTime,
                    isReady: true
                )

                continuation.resume(returning: processedSet)
            }
        }
    }

    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let ratio = min(maxDimension / size.width, maxDimension / size.height)

        // Only resize if image is larger than max dimension
        guard ratio < 1 else { return image }

        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    private func findOptimalCompression(image: UIImage, targetSize: Int, minQuality: CGFloat, maxQuality: CGFloat) -> (Data?, CGFloat) {
        var bestData: Data?
        var bestQuality: CGFloat = maxQuality

        // Try different compression levels
        for quality in stride(from: maxQuality, to: minQuality - 0.01, by: -0.05) {
            if let data = image.jpegData(compressionQuality: quality) {
                if data.count <= targetSize {
                    bestData = data
                    bestQuality = quality
                    break
                } else if quality <= minQuality + 0.01 {
                    // Use minimum quality as last resort
                    bestData = data
                    bestQuality = quality
                    break
                }
            }
        }

        return (bestData, bestQuality)
    }

    private func generateImageId(for image: UIImage) -> String {
        // Create a consistent ID based on image properties
        let sizeString = "\(Int(image.size.width))x\(Int(image.size.height))"
        let scaleString = "\(image.scale)"
        return "img_\(sizeString)_\(scaleString)_\(abs(image.hashValue))"
    }

    private func manageCacheSize() {
        while processedImageCache.count > maxCacheSize {
            // Remove oldest entries (simple LRU-like behavior)
            if let oldestKey = processedImageCache.keys.first {
                processedImageCache.removeValue(forKey: oldestKey)
            }
        }
    }

    private func setupMemoryPressureMonitoring() {
        memoryPressureObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryPressure()
        }
    }

    private func handleMemoryPressure() {
        print("⚠️ Memory pressure detected - clearing image cache")

        // Clear half of the cache
        let keysToRemove = Array(processedImageCache.keys.prefix(processedImageCache.count / 2))
        keysToRemove.forEach { processedImageCache.removeValue(forKey: $0) }

        // Cancel non-essential processing tasks
        let tasksToCancel = Array(processingTasks.keys.suffix(processingTasks.count / 2))
        tasksToCancel.forEach { taskId in
            processingTasks[taskId]?.cancel()
            processingTasks.removeValue(forKey: taskId)
        }
    }

    private func updateProcessingState() {
        let activeTaskCount = processingTasks.count
        isProcessing = activeTaskCount > 0

        if activeTaskCount == 0 {
            processingProgress = 0
            processedImageCount = 0
            totalImageCount = 0
        }
    }
}

// MARK: - Error Types
enum IntelligentProcessingError: LocalizedError {
    case compressionFailed
    case invalidImage
    case memoryPressure
    case processingCancelled

    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "Failed to compress image"
        case .invalidImage:
            return "Invalid image data"
        case .memoryPressure:
            return "Processing stopped due to memory pressure"
        case .processingCancelled:
            return "Image processing was cancelled"
        }
    }
}