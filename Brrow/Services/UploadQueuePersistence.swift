//
//  UploadQueuePersistence.swift
//  Brrow
//
//  Production-grade upload queue persistence system with crash recovery
//  Handles persistent storage of upload queue state across app crashes
//

import Foundation
import UIKit

// MARK: - Persisted Upload Item Model

/// Represents a single upload item that can be persisted and restored
struct PersistedUploadItem: Codable {
    let id: String                          // Unique identifier for this upload
    let imageFileName: String               // File name in Documents directory
    let listingId: String?                  // Associated listing ID (nil for standalone uploads)
    let uploadType: UploadType              // Type of upload (listing, profile, etc.)
    let progress: Double                    // Upload progress (0.0 to 1.0)
    let timestamp: Date                     // When this upload was queued
    let attemptCount: Int                   // Number of upload attempts
    let metadata: [String: String]          // Additional metadata (category, title, etc.)

    enum UploadType: String, Codable {
        case listing
        case profile
        case message
        case general
    }

    /// Check if this upload has expired (older than 24 hours)
    var isExpired: Bool {
        let expirationInterval: TimeInterval = 24 * 60 * 60 // 24 hours
        return Date().timeIntervalSince(timestamp) > expirationInterval
    }

    /// Check if upload should be retried (less than max attempts)
    var shouldRetry: Bool {
        return attemptCount < 3 && !isExpired
    }
}

// MARK: - Upload Queue Persistence Manager

@MainActor
class UploadQueuePersistence: ObservableObject {

    // MARK: - Singleton
    static let shared = UploadQueuePersistence()

    // MARK: - Published Properties
    @Published var pendingUploads: [PersistedUploadItem] = []
    @Published var isRestoring = false
    @Published var restoredCount = 0

    // MARK: - Constants
    private let userDefaultsKey = "brrow_upload_queue_v1"
    private let imageStorageDirectory = "PendingUploads"
    private let maxStoredImages = 50 // Prevent storage bloat
    private let maxFileSize = 10 * 1024 * 1024 // 10MB max per image

    // MARK: - Initialization
    private init() {
        createImageStorageDirectoryIfNeeded()
        loadPendingUploads()
        cleanupExpiredUploads()
    }

    // MARK: - Directory Management

    private func createImageStorageDirectoryIfNeeded() {
        guard let documentsURL = getDocumentsDirectory() else { return }
        let uploadDirURL = documentsURL.appendingPathComponent(imageStorageDirectory)

        if !FileManager.default.fileExists(atPath: uploadDirURL.path) {
            do {
                try FileManager.default.createDirectory(
                    at: uploadDirURL,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
                print("📁 [PERSISTENCE] Created upload storage directory: \(uploadDirURL.path)")
            } catch {
                print("❌ [PERSISTENCE] Failed to create directory: \(error)")
            }
        }
    }

    private func getDocumentsDirectory() -> URL? {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }

    private func getUploadStorageDirectory() -> URL? {
        guard let documentsURL = getDocumentsDirectory() else { return nil }
        return documentsURL.appendingPathComponent(imageStorageDirectory)
    }

    // MARK: - Save Image to Persistent Storage

    /// Save image to persistent storage and return file path
    private func saveImageToDisk(_ image: UIImage, fileName: String) -> String? {
        guard let uploadDirURL = getUploadStorageDirectory() else {
            print("❌ [PERSISTENCE] Cannot access upload directory")
            return nil
        }

        let fileURL = uploadDirURL.appendingPathComponent(fileName)

        // Compress image for storage (balance quality and size)
        guard let imageData = image.jpegData(compressionQuality: 0.85) else {
            print("❌ [PERSISTENCE] Failed to compress image")
            return nil
        }

        // Check file size limit
        if imageData.count > maxFileSize {
            print("⚠️ [PERSISTENCE] Image exceeds max size (\(imageData.count / 1024 / 1024)MB), compressing further")

            // Try lower quality
            guard let reducedData = image.jpegData(compressionQuality: 0.6) else {
                print("❌ [PERSISTENCE] Failed to reduce image size")
                return nil
            }

            if reducedData.count > maxFileSize {
                print("❌ [PERSISTENCE] Image still too large after compression")
                return nil
            }

            // Save reduced data
            do {
                try reducedData.write(to: fileURL)
                print("✅ [PERSISTENCE] Saved reduced image: \(fileName) (\(reducedData.count / 1024)KB)")
                return fileName
            } catch {
                print("❌ [PERSISTENCE] Failed to save reduced image: \(error)")
                return nil
            }
        }

        // Save normal quality image
        do {
            try imageData.write(to: fileURL)
            print("✅ [PERSISTENCE] Saved image: \(fileName) (\(imageData.count / 1024)KB)")
            return fileName
        } catch {
            print("❌ [PERSISTENCE] Failed to save image: \(error)")
            return nil
        }
    }

    // MARK: - Load Image from Persistent Storage

    /// Load image from persistent storage
    func loadImageFromDisk(_ fileName: String) -> UIImage? {
        guard let uploadDirURL = getUploadStorageDirectory() else {
            print("❌ [PERSISTENCE] Cannot access upload directory")
            return nil
        }

        let fileURL = uploadDirURL.appendingPathComponent(fileName)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("⚠️ [PERSISTENCE] Image file not found: \(fileName)")
            return nil
        }

        guard let imageData = try? Data(contentsOf: fileURL),
              let image = UIImage(data: imageData) else {
            print("❌ [PERSISTENCE] Failed to load image from: \(fileName)")
            return nil
        }

        print("✅ [PERSISTENCE] Loaded image: \(fileName)")
        return image
    }

    // MARK: - Delete Image from Persistent Storage

    private func deleteImageFromDisk(_ fileName: String) {
        guard let uploadDirURL = getUploadStorageDirectory() else { return }
        let fileURL = uploadDirURL.appendingPathComponent(fileName)

        do {
            try FileManager.default.removeItem(at: fileURL)
            print("🗑️ [PERSISTENCE] Deleted image: \(fileName)")
        } catch {
            print("⚠️ [PERSISTENCE] Failed to delete image: \(error)")
        }
    }

    // MARK: - Queue Persistence (UserDefaults)

    /// Save current upload queue to UserDefaults
    private func savePendingUploads() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(pendingUploads)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
            UserDefaults.standard.synchronize()
            print("💾 [PERSISTENCE] Saved \(pendingUploads.count) pending uploads")
        } catch {
            print("❌ [PERSISTENCE] Failed to save pending uploads: \(error)")
        }
    }

    /// Load upload queue from UserDefaults
    private func loadPendingUploads() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            print("ℹ️ [PERSISTENCE] No pending uploads found")
            return
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let uploads = try decoder.decode([PersistedUploadItem].self, from: data)
            pendingUploads = uploads
            print("📥 [PERSISTENCE] Loaded \(uploads.count) pending uploads")
        } catch {
            print("❌ [PERSISTENCE] Failed to load pending uploads: \(error)")
            // Clear corrupted data
            UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        }
    }

    // MARK: - Public API: Add Upload to Queue

    /// Add a new upload to the persistent queue
    func addUpload(
        image: UIImage,
        listingId: String? = nil,
        uploadType: PersistedUploadItem.UploadType,
        metadata: [String: String] = [:]
    ) -> String? {

        // Check storage limits
        if pendingUploads.count >= maxStoredImages {
            print("⚠️ [PERSISTENCE] Upload queue full, removing oldest expired uploads")
            cleanupExpiredUploads()

            // Still full? Remove oldest item
            if pendingUploads.count >= maxStoredImages {
                if let oldest = pendingUploads.min(by: { $0.timestamp < $1.timestamp }) {
                    removeUpload(id: oldest.id)
                }
            }
        }

        // Generate unique filename
        let uploadId = UUID().uuidString
        let fileName = "\(uploadId).jpg"

        // Save image to disk
        guard let savedFileName = saveImageToDisk(image, fileName: fileName) else {
            print("❌ [PERSISTENCE] Failed to save image to disk")
            return nil
        }

        // Create upload item
        let uploadItem = PersistedUploadItem(
            id: uploadId,
            imageFileName: savedFileName,
            listingId: listingId,
            uploadType: uploadType,
            progress: 0.0,
            timestamp: Date(),
            attemptCount: 0,
            metadata: metadata
        )

        // Add to queue
        pendingUploads.append(uploadItem)
        savePendingUploads()

        print("✅ [PERSISTENCE] Added upload to queue: \(uploadId)")
        print("   Type: \(uploadType.rawValue), Listing: \(listingId ?? "nil")")

        return uploadId
    }

    // MARK: - Public API: Update Upload Progress

    /// Update progress for an upload in the queue
    func updateProgress(id: String, progress: Double) {
        guard let index = pendingUploads.firstIndex(where: { $0.id == id }) else {
            return
        }

        var item = pendingUploads[index]
        pendingUploads[index] = PersistedUploadItem(
            id: item.id,
            imageFileName: item.imageFileName,
            listingId: item.listingId,
            uploadType: item.uploadType,
            progress: progress,
            timestamp: item.timestamp,
            attemptCount: item.attemptCount,
            metadata: item.metadata
        )

        savePendingUploads()
    }

    // MARK: - Public API: Increment Attempt Count

    /// Increment attempt count for retry logic
    func incrementAttemptCount(id: String) {
        guard let index = pendingUploads.firstIndex(where: { $0.id == id }) else {
            return
        }

        var item = pendingUploads[index]
        pendingUploads[index] = PersistedUploadItem(
            id: item.id,
            imageFileName: item.imageFileName,
            listingId: item.listingId,
            uploadType: item.uploadType,
            progress: item.progress,
            timestamp: item.timestamp,
            attemptCount: item.attemptCount + 1,
            metadata: item.metadata
        )

        savePendingUploads()
    }

    // MARK: - Public API: Remove Upload from Queue

    /// Remove upload from queue after successful completion
    func removeUpload(id: String) {
        guard let index = pendingUploads.firstIndex(where: { $0.id == id }) else {
            print("⚠️ [PERSISTENCE] Upload not found: \(id)")
            return
        }

        let item = pendingUploads[index]

        // Delete image from disk
        deleteImageFromDisk(item.imageFileName)

        // Remove from queue
        pendingUploads.remove(at: index)
        savePendingUploads()

        print("✅ [PERSISTENCE] Removed upload from queue: \(id)")
    }

    // MARK: - Public API: Clear All Uploads

    /// Clear entire upload queue (for user-initiated clear or logout)
    func clearAllUploads() {
        print("🗑️ [PERSISTENCE] Clearing all pending uploads")

        // Delete all images from disk
        for upload in pendingUploads {
            deleteImageFromDisk(upload.imageFileName)
        }

        // Clear queue
        pendingUploads.removeAll()
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        UserDefaults.standard.synchronize()

        print("✅ [PERSISTENCE] Upload queue cleared")
    }

    // MARK: - Cleanup Utilities

    /// Remove expired uploads (older than 24 hours)
    func cleanupExpiredUploads() {
        let expiredUploads = pendingUploads.filter { $0.isExpired }

        if expiredUploads.isEmpty {
            return
        }

        print("🧹 [PERSISTENCE] Cleaning up \(expiredUploads.count) expired uploads")

        for upload in expiredUploads {
            removeUpload(id: upload.id)
        }
    }

    /// Remove failed uploads that shouldn't be retried
    func cleanupFailedUploads() {
        let failedUploads = pendingUploads.filter { !$0.shouldRetry }

        if failedUploads.isEmpty {
            return
        }

        print("🧹 [PERSISTENCE] Cleaning up \(failedUploads.count) failed uploads")

        for upload in failedUploads {
            removeUpload(id: upload.id)
        }
    }

    // MARK: - Recovery & Statistics

    /// Get upload queue statistics
    func getQueueStatistics() -> (total: Int, expired: Int, shouldRetry: Int) {
        let total = pendingUploads.count
        let expired = pendingUploads.filter { $0.isExpired }.count
        let shouldRetry = pendingUploads.filter { $0.shouldRetry }.count

        return (total, expired, shouldRetry)
    }

    /// Get uploads that should be retried
    func getRetryableUploads() -> [PersistedUploadItem] {
        return pendingUploads.filter { $0.shouldRetry }
    }

    /// Check if there are pending uploads
    func hasPendingUploads() -> Bool {
        return !pendingUploads.isEmpty
    }

    // MARK: - Debug Utilities

    func printQueueStatus() {
        print("📊 [PERSISTENCE] Upload Queue Status:")
        print("   Total: \(pendingUploads.count)")
        print("   Expired: \(pendingUploads.filter { $0.isExpired }.count)")
        print("   Should Retry: \(pendingUploads.filter { $0.shouldRetry }.count)")

        for upload in pendingUploads {
            print("   • \(upload.id)")
            print("     Type: \(upload.uploadType.rawValue)")
            print("     Progress: \(Int(upload.progress * 100))%")
            print("     Attempts: \(upload.attemptCount)")
            print("     Age: \(Int(Date().timeIntervalSince(upload.timestamp) / 60))m")
        }
    }
}
