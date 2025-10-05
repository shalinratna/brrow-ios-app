//
//  FileUploadService+Persistence.swift
//  Brrow
//
//  Crash recovery and persistence extension for FileUploadService
//

import Foundation
import UIKit

// MARK: - FileUploadService Persistence Extension

extension FileUploadService {

    // MARK: - Persistent Upload with Crash Recovery

    /// Upload with crash recovery - automatically saves to persistent queue
    func uploadImageWithPersistence(
        _ image: UIImage,
        listingId: String? = nil,
        uploadType: PersistedUploadItem.UploadType = .listing,
        metadata: [String: String] = [:]
    ) async throws -> String {

        // Add to persistent queue (must be on MainActor)
        let uploadId = await MainActor.run {
            UploadQueuePersistence.shared.addUpload(
                image: image,
                listingId: listingId,
                uploadType: uploadType,
                metadata: metadata
            )
        }

        guard let uploadId = uploadId else {
            throw FileUploadError.uploadFailed
        }

        print("💾 [PERSISTENCE] Upload queued with ID: \(uploadId)")

        do {
            // Attempt upload
            let fileName = "\(uploadId).jpg"
            let url = try await uploadImage(image, fileName: fileName, useBackgroundSession: true)

            // Success - remove from persistent queue (must be on MainActor)
            await MainActor.run {
                UploadQueuePersistence.shared.removeUpload(id: uploadId)
            }
            print("✅ [PERSISTENCE] Upload completed and removed from queue: \(uploadId)")

            return url
        } catch {
            // Failure - increment attempt count (must be on MainActor)
            await MainActor.run {
                UploadQueuePersistence.shared.incrementAttemptCount(id: uploadId)
            }
            print("❌ [PERSISTENCE] Upload failed, attempt count incremented: \(uploadId)")
            throw error
        }
    }

    /// Upload multiple images with persistence (for batch listing uploads)
    func uploadMultipleImagesWithPersistence(
        _ images: [UIImage],
        listingId: String? = nil,
        metadata: [String: String] = [:]
    ) async throws -> [String] {

        var uploadedUrls: [String] = []
        var failureCount = 0
        let maxConsecutiveFailures = 2

        for (index, image) in images.enumerated() {
            do {
                print("📤 Uploading image \(index + 1) of \(images.count) with persistence...")

                let url = try await uploadImageWithPersistence(
                    image,
                    listingId: listingId,
                    uploadType: .listing,
                    metadata: metadata
                )

                uploadedUrls.append(url)
                failureCount = 0 // Reset failure count on success
                print("✅ Successfully uploaded image \(index + 1)")
            } catch {
                failureCount += 1
                print("❌ Failed to upload image \(index + 1): \(error.localizedDescription)")

                // Early failure detection: stop after 2 consecutive failures
                if failureCount >= maxConsecutiveFailures {
                    print("🚨 Early failure detected after \(failureCount) consecutive failures.")

                    // Note: Failed images are still in persistent queue for retry on app relaunch
                    throw FileUploadError.multipleFailures(
                        message: "Upload failed after \(failureCount) consecutive attempts. Remaining images will be uploaded when you reopen the app.",
                        failedAttempts: failureCount,
                        successfulUploads: uploadedUrls.count
                    )
                }

                // Continue trying for non-consecutive failures
                if index < images.count - 1 {
                    print("⚠️ Continuing with next image despite failure...")
                }
            }
        }

        // If we uploaded at least some images, return them
        if uploadedUrls.isEmpty && images.count > 0 {
            throw FileUploadError.uploadFailed
        }

        return uploadedUrls
    }

    /// Resume all pending uploads from persistent queue
    @MainActor
    func resumePendingUploads() async {
        let retryableUploads = UploadQueuePersistence.shared.getRetryableUploads()

        if retryableUploads.isEmpty {
            print("ℹ️ [PERSISTENCE] No pending uploads to resume")
            return
        }

        print("🔄 [PERSISTENCE] Resuming \(retryableUploads.count) pending uploads")
        UploadQueuePersistence.shared.isRestoring = true

        var successCount = 0
        var failureCount = 0

        for uploadItem in retryableUploads {
            // Load image from disk
            guard let image = UploadQueuePersistence.shared.loadImageFromDisk(uploadItem.imageFileName) else {
                print("⚠️ [PERSISTENCE] Cannot load image for upload: \(uploadItem.id)")
                UploadQueuePersistence.shared.removeUpload(id: uploadItem.id)
                failureCount += 1
                continue
            }

            do {
                // Attempt upload
                let fileName = uploadItem.imageFileName
                let url = try await uploadImage(image, fileName: fileName, useBackgroundSession: true)

                // Success - remove from queue
                UploadQueuePersistence.shared.removeUpload(id: uploadItem.id)
                successCount += 1
                print("✅ [PERSISTENCE] Resumed upload succeeded: \(uploadItem.id)")

                // Notify if this was part of a listing
                if let listingId = uploadItem.listingId {
                    NotificationCenter.default.post(
                        name: .uploadResumedSuccess,
                        object: nil,
                        userInfo: [
                            "uploadId": uploadItem.id,
                            "listingId": listingId,
                            "imageUrl": url
                        ]
                    )
                }
            } catch {
                // Increment attempt count
                UploadQueuePersistence.shared.incrementAttemptCount(id: uploadItem.id)
                failureCount += 1
                print("❌ [PERSISTENCE] Resumed upload failed: \(uploadItem.id) - \(error)")

                // Check if should stop retrying
                if uploadItem.attemptCount >= 2 { // Already failed twice, this is third attempt
                    UploadQueuePersistence.shared.removeUpload(id: uploadItem.id)
                    print("🛑 [PERSISTENCE] Max attempts reached, removing: \(uploadItem.id)")
                }
            }
        }

        UploadQueuePersistence.shared.isRestoring = false
        UploadQueuePersistence.shared.restoredCount = successCount

        print("📊 [PERSISTENCE] Resume complete - Success: \(successCount), Failed: \(failureCount)")

        // Cleanup any remaining expired or failed uploads
        UploadQueuePersistence.shared.cleanupExpiredUploads()
        UploadQueuePersistence.shared.cleanupFailedUploads()

        // Show user notification if there were resumed uploads
        if successCount > 0 {
            await showResumeNotification(successCount: successCount, failureCount: failureCount)
        }
    }

    /// Check for pending uploads on app launch (lightweight check)
    func checkPendingUploadsOnLaunch() {
        Task { @MainActor in
            let stats = UploadQueuePersistence.shared.getQueueStatistics()

            if stats.total > 0 {
                print("📋 [PERSISTENCE] Found \(stats.total) pending uploads on launch")
                print("   - Should retry: \(stats.shouldRetry)")
                print("   - Expired: \(stats.expired)")
            }
        }
    }

    /// Show notification about resumed uploads
    @MainActor
    private func showResumeNotification(successCount: Int, failureCount: Int) async {
        let message: String
        if failureCount == 0 {
            message = "Successfully uploaded \(successCount) pending image\(successCount > 1 ? "s" : "")"
        } else {
            message = "Uploaded \(successCount) of \(successCount + failureCount) pending images"
        }

        // Post notification for UI to handle
        NotificationCenter.default.post(
            name: .showUploadResumeAlert,
            object: nil,
            userInfo: ["message": message, "successCount": successCount, "failureCount": failureCount]
        )
    }
}

// MARK: - Notification Names Extension

extension Notification.Name {
    static let uploadResumedSuccess = Notification.Name("uploadResumedSuccess")
    static let showUploadResumeAlert = Notification.Name("showUploadResumeAlert")
}
