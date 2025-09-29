//
//  BatchUploadManager.swift
//  Brrow
//
//  Intelligent batch upload system with queue management, retry logic, and load balancing
//

import SwiftUI
import Combine
import UIKit

@MainActor
class BatchUploadManager: ObservableObject {
    static let shared = BatchUploadManager()

    // MARK: - Published Properties
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0
    @Published var uploadedCount = 0
    @Published var totalCount = 0
    @Published var currentBatchId: String?
    @Published var uploadSpeed: Double = 0 // KB/s

    // MARK: - Private Properties
    private var uploadQueue: [UploadBatch] = []
    private var activeUploads: [String: Task<UploadResult, Error>] = [:]
    private var completedUploads: [String: UploadResult] = [:]
    private var failedUploads: [String: UploadFailure] = [:]

    // Configuration
    private let maxConcurrentUploads = 3 // Optimal balance between speed and server load
    private let maxRetries = 3
    private let retryDelayBase: Double = 1.0 // Base delay for exponential backoff
    private let batchTimeout: TimeInterval = 60.0 // 60 seconds timeout per batch
    private let uploadTimeout: TimeInterval = 30.0 // 30 seconds timeout per individual upload

    // Speed tracking
    private var speedTracker = SpeedTracker()

    // MARK: - Data Models
    struct UploadBatch {
        let id: String
        let images: [ProcessedImageData]
        let priority: UploadPriority
        let configuration: UploadConfiguration
        let createdAt: Date
        let cancellationToken: CancellationToken

        struct ProcessedImageData {
            let id: String
            let base64Data: String
            let originalSize: Int
            let compressedSize: Int
            let compressionQuality: CGFloat
            let metadata: ImageMetadata
        }

        struct ImageMetadata {
            let originalDimensions: CGSize
            let finalDimensions: CGSize
            let hasLocationData: Bool
            let processingTime: TimeInterval
        }
    }

    enum UploadPriority: Int, CaseIterable {
        case high = 3    // User actively waiting
        case normal = 2  // Standard listing creation
        case low = 1     // Background/predictive uploads

        var maxRetries: Int {
            switch self {
            case .high: return 5
            case .normal: return 3
            case .low: return 1
            }
        }

        var timeoutMultiplier: Double {
            switch self {
            case .high: return 2.0
            case .normal: return 1.0
            case .low: return 0.5
            }
        }
    }

    struct UploadConfiguration {
        let useMultipartUpload: Bool
        let enableCompression: Bool
        let preserveMetadata: Bool
        let endpoint: UploadEndpoint
        let retryStrategy: RetryStrategy

        static let listing = UploadConfiguration(
            useMultipartUpload: false, // Currently using base64, TODO: implement multipart
            enableCompression: true,
            preserveMetadata: true,
            endpoint: .listing,
            retryStrategy: .exponentialBackoff
        )

        static let profile = UploadConfiguration(
            useMultipartUpload: false,
            enableCompression: true,
            preserveMetadata: false,
            endpoint: .profile,
            retryStrategy: .linear
        )
    }

    enum UploadEndpoint: String {
        case listing = "/api/upload"
        case profile = "/api/profile/upload-picture"
        case batch = "/api/upload/batch" // TODO: Implement batch endpoint

        var supportsMultiple: Bool {
            switch self {
            case .batch: return true
            case .listing, .profile: return false
            }
        }
    }

    enum RetryStrategy {
        case none
        case linear
        case exponentialBackoff
    }

    struct UploadResult {
        let id: String
        let url: String
        let publicId: String?
        let uploadTime: TimeInterval
        let size: Int
        let retryCount: Int
    }

    struct UploadFailure {
        let id: String
        let error: Error
        let retryCount: Int
        let lastAttempt: Date
        let canRetry: Bool
    }

    class CancellationToken {
        private var isCancelled = false
        private let lock = NSLock()

        var cancelled: Bool {
            lock.lock()
            defer { lock.unlock() }
            return isCancelled
        }

        func cancel() {
            lock.lock()
            defer { lock.unlock() }
            isCancelled = true
        }
    }

    // MARK: - Initialization
    private init() {
        setupSpeedTracking()
    }

    // MARK: - Public Interface

    /// Queue images for batch upload with intelligent processing
    func queueBatchUpload(
        images: [IntelligentImageProcessor.ProcessedImageSet],
        priority: UploadPriority = .normal,
        configuration: UploadConfiguration = .listing
    ) -> (batchId: String, cancellationToken: CancellationToken) {

        let batchId = "batch_\(UUID().uuidString)"
        let cancellationToken = CancellationToken()

        let processedImages = images.map { processedSet in
            UploadBatch.ProcessedImageData(
                id: processedSet.id,
                base64Data: processedSet.base64Data,
                originalSize: Int(processedSet.originalImage.size.width * processedSet.originalImage.size.height * 4),
                compressedSize: processedSet.finalSize,
                compressionQuality: processedSet.compressionQuality,
                metadata: UploadBatch.ImageMetadata(
                    originalDimensions: processedSet.originalImage.size,
                    finalDimensions: processedSet.optimizedImage.size,
                    hasLocationData: false, // TODO: Implement location data detection
                    processingTime: processedSet.processingTime
                )
            )
        }

        let batch = UploadBatch(
            id: batchId,
            images: processedImages,
            priority: priority,
            configuration: configuration,
            createdAt: Date(),
            cancellationToken: cancellationToken
        )

        // Add to queue with priority ordering
        insertBatchInQueue(batch)

        print("📦 Queued batch \(batchId) with \(images.count) images (priority: \(priority))")

        // Start processing if not already running
        if !isUploading {
            startUploadProcessing()
        }

        return (batchId, cancellationToken)
    }

    /// Upload images immediately with highest priority
    func uploadImagesImmediately(
        images: [IntelligentImageProcessor.ProcessedImageSet],
        configuration: UploadConfiguration = .listing
    ) async throws -> [UploadResult] {

        let (batchId, _) = queueBatchUpload(images: images, priority: .high, configuration: configuration)

        // Wait for this specific batch to complete
        return try await waitForBatchCompletion(batchId: batchId)
    }

    /// Cancel a specific batch upload
    func cancelBatch(_ batchId: String) {
        // Find and cancel the batch
        if let batchIndex = uploadQueue.firstIndex(where: { $0.id == batchId }) {
            uploadQueue[batchIndex].cancellationToken.cancel()
            uploadQueue.remove(at: batchIndex)
            print("🚫 Cancelled queued batch \(batchId)")
        }

        // Cancel active uploads for this batch
        activeUploads.keys.filter { $0.hasPrefix(batchId) }.forEach { uploadId in
            activeUploads[uploadId]?.cancel()
            activeUploads.removeValue(forKey: uploadId)
        }

        updateUploadState()
    }

    /// Get upload progress for a specific batch
    func getBatchProgress(_ batchId: String) -> (completed: Int, total: Int, progress: Double) {
        let completedCount = completedUploads.keys.filter { $0.hasPrefix(batchId) }.count
        let failedCount = failedUploads.keys.filter { $0.hasPrefix(batchId) }.count
        let activeCount = activeUploads.keys.filter { $0.hasPrefix(batchId) }.count

        let totalCount = completedCount + failedCount + activeCount

        if let batch = uploadQueue.first(where: { $0.id == batchId }) {
            let batchTotal = batch.images.count
            let progress = totalCount > 0 ? Double(completedCount) / Double(batchTotal) : 0
            return (completedCount, batchTotal, progress)
        }

        let progress = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0
        return (completedCount, totalCount, progress)
    }

    // MARK: - Private Methods

    private func insertBatchInQueue(_ batch: UploadBatch) {
        // Insert batch based on priority
        if uploadQueue.isEmpty {
            uploadQueue.append(batch)
        } else {
            let insertIndex = uploadQueue.firstIndex { $0.priority.rawValue < batch.priority.rawValue } ?? uploadQueue.count
            uploadQueue.insert(batch, at: insertIndex)
        }
    }

    private func startUploadProcessing() {
        guard !isUploading && !uploadQueue.isEmpty else { return }

        isUploading = true

        Task {
            await processUploadQueue()
        }
    }

    private func processUploadQueue() async {
        while !uploadQueue.isEmpty {
            let batch = uploadQueue.removeFirst()

            // Check if batch was cancelled
            if batch.cancellationToken.cancelled {
                print("🚫 Skipping cancelled batch \(batch.id)")
                continue
            }

            currentBatchId = batch.id
            totalCount = batch.images.count
            uploadedCount = 0

            print("🚀 Processing batch \(batch.id) with \(batch.images.count) images")

            await uploadBatch(batch)
        }

        isUploading = false
        currentBatchId = nil
        uploadProgress = 0
        uploadedCount = 0
        totalCount = 0
    }

    private func uploadBatch(_ batch: UploadBatch) async {
        await withTaskGroup(of: Void.self) { group in
            var semaphore = 0

            for image in batch.images {
                // Check cancellation
                if batch.cancellationToken.cancelled {
                    break
                }

                // Limit concurrent uploads
                while semaphore >= maxConcurrentUploads {
                    await Task.yield()
                    semaphore = activeUploads.count
                }

                group.addTask { [weak self] in
                    await self?.uploadSingleImage(image, batch: batch)
                }

                semaphore += 1
            }

            // Wait for all uploads to complete
            await group.waitForAll()
        }
    }

    private func uploadSingleImage(_ image: UploadBatch.ProcessedImageData, batch: UploadBatch) async {
        let uploadId = "\(batch.id)_\(image.id)"
        let startTime = CFAbsoluteTimeGetCurrent()

        let uploadTask = Task<UploadResult, Error> {
            try await performUpload(image: image, batch: batch)
        }

        activeUploads[uploadId] = uploadTask

        do {
            let result = try await uploadTask.value
            let uploadTime = CFAbsoluteTimeGetCurrent() - startTime

            completedUploads[uploadId] = UploadResult(
                id: image.id,
                url: result.url,
                publicId: result.publicId,
                uploadTime: uploadTime,
                size: image.compressedSize,
                retryCount: result.retryCount
            )

            uploadedCount += 1
            uploadProgress = Double(uploadedCount) / Double(totalCount)

            // Update speed tracking
            speedTracker.recordUpload(size: image.compressedSize, duration: uploadTime)
            uploadSpeed = speedTracker.currentSpeed

            print("✅ Uploaded \(image.id) (\(image.compressedSize / 1024)KB in \(String(format: "%.2f", uploadTime))s)")

        } catch {
            let failure = UploadFailure(
                id: image.id,
                error: error,
                retryCount: 0,
                lastAttempt: Date(),
                canRetry: shouldRetry(error: error, batch: batch)
            )

            failedUploads[uploadId] = failure

            // Attempt retry if appropriate
            if failure.canRetry {
                await retryUpload(image: image, batch: batch, previousFailure: failure)
            } else {
                print("❌ Failed to upload \(image.id): \(error.localizedDescription)")
            }
        }

        activeUploads.removeValue(forKey: uploadId)
    }

    private func performUpload(image: UploadBatch.ProcessedImageData, batch: UploadBatch) async throws -> UploadResult {
        let payload: [String: Any] = [
            "image": image.base64Data,
            "type": "listing",
            "preserve_metadata": batch.configuration.preserveMetadata,
            "entity_type": "listing",
            "media_type": "image"
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            throw BatchUploadError.serialization
        }

        let baseURL = await APIEndpointManager.shared.getBestEndpoint()
        guard let url = URL(string: "\(baseURL)\(batch.configuration.endpoint.rawValue)") else {
            throw BatchUploadError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = uploadTimeout * batch.priority.timeoutMultiplier

        // Add auth headers
        if let token = AuthManager.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let user = AuthManager.shared.currentUser {
            request.setValue(user.apiId, forHTTPHeaderField: "X-User-API-ID")
        }

        request.httpBody = jsonData

        let (responseData, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BatchUploadError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw BatchUploadError.serverError(httpResponse.statusCode)
        }

        // Parse response
        guard let json = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any],
              let success = json["success"] as? Bool,
              success,
              let data = json["data"] as? [String: Any],
              let fileUrl = data["url"] as? String else {
            throw BatchUploadError.invalidResponse
        }

        let publicId = data["public_id"] as? String

        return UploadResult(
            id: image.id,
            url: fileUrl,
            publicId: publicId,
            uploadTime: 0, // Will be calculated by caller
            size: image.compressedSize,
            retryCount: 0
        )
    }

    private func retryUpload(image: UploadBatch.ProcessedImageData, batch: UploadBatch, previousFailure: UploadFailure) async {
        let retryCount = previousFailure.retryCount + 1
        let maxRetries = batch.priority.maxRetries

        guard retryCount <= maxRetries else {
            print("❌ Max retries exceeded for \(image.id)")
            return
        }

        // Calculate delay based on retry strategy
        let delay = calculateRetryDelay(retryCount: retryCount, strategy: batch.configuration.retryStrategy)

        print("🔄 Retrying upload for \(image.id) (attempt \(retryCount)/\(maxRetries)) after \(delay)s delay")

        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

        // Check if still cancelled
        if batch.cancellationToken.cancelled {
            return
        }

        await uploadSingleImage(image, batch: batch)
    }

    private func calculateRetryDelay(retryCount: Int, strategy: RetryStrategy) -> Double {
        switch strategy {
        case .none:
            return 0
        case .linear:
            return retryDelayBase * Double(retryCount)
        case .exponentialBackoff:
            return retryDelayBase * pow(2.0, Double(retryCount - 1))
        }
    }

    private func shouldRetry(error: Error, batch: UploadBatch) -> Bool {
        // Determine if error is retryable
        if error is CancellationError {
            return false
        }

        if let batchError = error as? BatchUploadError {
            switch batchError {
            case .serialization, .invalidURL, .cancelled:
                return false // These won't improve with retry
            case .networkError, .timeout, .serverError(_), .invalidResponse:
                return true // These might improve with retry
            }
        }

        return true // Default to retryable for unknown errors
    }

    private func waitForBatchCompletion(batchId: String) async throws -> [UploadResult] {
        // Wait for batch to complete with timeout
        let startTime = CFAbsoluteTimeGetCurrent()

        while CFAbsoluteTimeGetCurrent() - startTime < batchTimeout {
            let (completed, total, _) = getBatchProgress(batchId)

            if completed == total {
                // Batch completed, return results
                let results = completedUploads.compactMap { (key, value) in
                    key.hasPrefix(batchId) ? value : nil
                }
                return results
            }

            // Check if batch was cancelled or failed
            if uploadQueue.first(where: { $0.id == batchId })?.cancellationToken.cancelled == true {
                throw BatchUploadError.cancelled
            }

            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        }

        throw BatchUploadError.timeout
    }

    private func updateUploadState() {
        let hasActiveUploads = !activeUploads.isEmpty || !uploadQueue.isEmpty

        if !hasActiveUploads {
            isUploading = false
            uploadProgress = 0
            uploadedCount = 0
            totalCount = 0
            currentBatchId = nil
        }
    }

    private func setupSpeedTracking() {
        speedTracker.onSpeedUpdate = { [weak self] speed in
            DispatchQueue.main.async {
                self?.uploadSpeed = speed
            }
        }
    }
}

// MARK: - Speed Tracking
private class SpeedTracker {
    private var recentUploads: [(size: Int, time: CFAbsoluteTime)] = []
    private let windowSize: TimeInterval = 10.0 // 10 second window
    var onSpeedUpdate: ((Double) -> Void)?

    var currentSpeed: Double {
        cleanOldEntries()

        let totalSize = recentUploads.reduce(0) { $0 + $1.size }
        let totalTime = recentUploads.count > 0 ? windowSize : 1.0

        return Double(totalSize) / totalTime / 1024.0 // KB/s
    }

    func recordUpload(size: Int, duration: TimeInterval) {
        let now = CFAbsoluteTimeGetCurrent()
        recentUploads.append((size: size, time: now))
        cleanOldEntries()
        onSpeedUpdate?(currentSpeed)
    }

    private func cleanOldEntries() {
        let cutoff = CFAbsoluteTimeGetCurrent() - windowSize
        recentUploads.removeAll { $0.time < cutoff }
    }
}

// MARK: - Error Types
enum BatchUploadError: LocalizedError {
    case serialization
    case invalidURL
    case networkError
    case timeout
    case serverError(Int)
    case invalidResponse
    case cancelled

    var errorDescription: String? {
        switch self {
        case .serialization:
            return "Failed to serialize upload data"
        case .invalidURL:
            return "Invalid upload URL"
        case .networkError:
            return "Network connection error"
        case .timeout:
            return "Upload timed out"
        case .serverError(let code):
            return "Server error: \(code)"
        case .invalidResponse:
            return "Invalid server response"
        case .cancelled:
            return "Upload was cancelled"
        }
    }
}
