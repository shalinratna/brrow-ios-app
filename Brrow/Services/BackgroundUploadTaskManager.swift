//
//  BackgroundUploadTaskManager.swift
//  Brrow
//
//  Manages background tasks for file uploads to keep them alive when app is backgrounded
//  Uses UIBackgroundTask for short-term (30s) background execution
//  Uses BGTaskScheduler for long-running background processing
//

import Foundation
import UIKit
import BackgroundTasks

/// Manages background upload tasks to prevent interruption when app is backgrounded
class BackgroundUploadTaskManager: ObservableObject {
    static let shared = BackgroundUploadTaskManager()

    // Background task identifiers
    static let uploadTaskIdentifier = "com.brrow.app.upload-task"
    static let processingTaskIdentifier = "com.brrow.app.upload-processing"

    // Active background tasks tracking
    private var activeBackgroundTasks: [String: UIBackgroundTaskIdentifier] = [:]
    private var activeBGTasks: [String: BGTask] = [:]

    // Upload progress tracking
    @Published var activeUploads: [String: UploadProgress] = [:]

    private let queue = DispatchQueue(label: "com.brrow.background-upload", qos: .userInitiated)

    private init() {
        setupNotifications()
    }

    // MARK: - Background Task Registration

    /// Register background task handlers with BGTaskScheduler
    /// Call this from AppDelegate's didFinishLaunchingWithOptions
    func registerBackgroundTasks() {
        // Register short background task handler
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.uploadTaskIdentifier,
            using: nil
        ) { task in
            self.handleUploadBackgroundTask(task: task as! BGProcessingTask)
        }

        // Register processing task handler for long-running uploads
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.processingTaskIdentifier,
            using: nil
        ) { task in
            self.handleProcessingBackgroundTask(task: task as! BGProcessingTask)
        }

        print("✅ [BackgroundUpload] Background tasks registered")
    }

    // MARK: - Upload Task Management

    /// Begin a background task for an upload operation
    /// - Parameters:
    ///   - uploadId: Unique identifier for this upload
    ///   - estimatedDuration: Estimated duration in seconds (helps choose right background mode)
    /// - Returns: The upload ID for tracking
    @discardableResult
    func beginBackgroundTask(for uploadId: String, estimatedDuration: TimeInterval = 10) -> String {
        queue.async {
            // For short uploads (<30s), use UIBackgroundTask
            if estimatedDuration <= 25 {
                self.startUIBackgroundTask(for: uploadId)
            } else {
                // For longer uploads, schedule BGProcessingTask
                self.scheduleBGProcessingTask(for: uploadId)
            }
        }

        // Track upload progress
        let progress = UploadProgress(id: uploadId, startTime: Date(), estimatedDuration: estimatedDuration)
        DispatchQueue.main.async {
            self.activeUploads[uploadId] = progress
        }

        print("📤 [BackgroundUpload] Started background task for upload: \(uploadId)")
        return uploadId
    }

    /// End a background task when upload completes or fails
    /// - Parameter uploadId: The upload ID to end
    func endBackgroundTask(for uploadId: String) {
        queue.async {
            // End UIBackgroundTask if exists
            if let taskId = self.activeBackgroundTasks[uploadId] {
                UIApplication.shared.endBackgroundTask(taskId)
                self.activeBackgroundTasks.removeValue(forKey: uploadId)
                print("✅ [BackgroundUpload] Ended UI background task for: \(uploadId)")
            }

            // Mark BGTask as complete if exists
            if let bgTask = self.activeBGTasks[uploadId] {
                bgTask.setTaskCompleted(success: true)
                self.activeBGTasks.removeValue(forKey: uploadId)
                print("✅ [BackgroundUpload] Completed BG processing task for: \(uploadId)")
            }

            // Remove from tracking
            DispatchQueue.main.async {
                self.activeUploads.removeValue(forKey: uploadId)
            }
        }
    }

    /// Mark an upload as failed
    /// - Parameters:
    ///   - uploadId: The upload ID
    ///   - error: The error that occurred
    func markUploadFailed(uploadId: String, error: Error) {
        queue.async {
            // End tasks with failure status
            if let taskId = self.activeBackgroundTasks[uploadId] {
                UIApplication.shared.endBackgroundTask(taskId)
                self.activeBackgroundTasks.removeValue(forKey: uploadId)
            }

            if let bgTask = self.activeBGTasks[uploadId] {
                bgTask.setTaskCompleted(success: false)
                self.activeBGTasks.removeValue(forKey: uploadId)
            }

            // Update progress with error
            DispatchQueue.main.async {
                if var progress = self.activeUploads[uploadId] {
                    progress.error = error
                    progress.status = .failed
                    self.activeUploads[uploadId] = progress
                }
            }
        }

        print("❌ [BackgroundUpload] Upload failed: \(uploadId), error: \(error.localizedDescription)")
    }

    /// Update upload progress
    /// - Parameters:
    ///   - uploadId: The upload ID
    ///   - progress: Progress value (0.0 to 1.0)
    func updateProgress(uploadId: String, progress: Double) {
        DispatchQueue.main.async {
            if var uploadProgress = self.activeUploads[uploadId] {
                uploadProgress.progress = progress
                uploadProgress.status = .uploading
                self.activeUploads[uploadId] = uploadProgress
            }
        }
    }

    // MARK: - Private Methods

    private func startUIBackgroundTask(for uploadId: String) {
        let taskId = UIApplication.shared.beginBackgroundTask(withName: "Upload-\(uploadId)") {
            // Expiration handler - iOS is about to kill our background time
            print("⚠️ [BackgroundUpload] Background task expiring for: \(uploadId)")
            self.handleBackgroundTaskExpiration(uploadId: uploadId)
        }

        if taskId != .invalid {
            activeBackgroundTasks[uploadId] = taskId
            print("✅ [BackgroundUpload] UI background task started: \(taskId)")
        } else {
            print("❌ [BackgroundUpload] Failed to start UI background task")
        }
    }

    private func scheduleBGProcessingTask(for uploadId: String) {
        let request = BGProcessingTaskRequest(identifier: Self.processingTaskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false

        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ [BackgroundUpload] Scheduled BG processing task for: \(uploadId)")
        } catch {
            print("❌ [BackgroundUpload] Failed to schedule BG task: \(error)")
            // Fallback to UIBackgroundTask
            startUIBackgroundTask(for: uploadId)
        }
    }

    private func handleBackgroundTaskExpiration(uploadId: String) {
        // Save current upload state for later resumption
        if let progress = activeUploads[uploadId] {
            saveUploadState(progress)
        }

        // Clean up
        if let taskId = activeBackgroundTasks[uploadId] {
            UIApplication.shared.endBackgroundTask(taskId)
            activeBackgroundTasks.removeValue(forKey: uploadId)
        }

        // Update status
        DispatchQueue.main.async {
            if var uploadProgress = self.activeUploads[uploadId] {
                uploadProgress.status = .paused
                uploadProgress.pauseReason = "Background time expired"
                self.activeUploads[uploadId] = uploadProgress
            }
        }

        // Schedule for retry when app becomes active
        scheduleRetryOnAppActivation(uploadId: uploadId)

        print("⏸️ [BackgroundUpload] Upload paused due to expiration: \(uploadId)")
    }

    private func handleUploadBackgroundTask(task: BGProcessingTask) {
        print("🔄 [BackgroundUpload] Handling upload background task")

        // Schedule next task for continuity
        scheduleNextBackgroundTask()

        // Set expiration handler
        task.expirationHandler = {
            print("⚠️ [BackgroundUpload] BG task expiring, cleaning up...")
            // Cancel ongoing uploads gracefully
            self.pauseAllActiveUploads()
            task.setTaskCompleted(success: false)
        }

        // Resume any paused uploads
        Task {
            await self.resumePausedUploads()
            task.setTaskCompleted(success: true)
        }
    }

    private func handleProcessingBackgroundTask(task: BGProcessingTask) {
        print("🔄 [BackgroundUpload] Handling processing background task")

        // Store task reference
        if let uploadId = getCurrentProcessingUploadId() {
            activeBGTasks[uploadId] = task
        }

        task.expirationHandler = {
            print("⚠️ [BackgroundUpload] Processing task expiring")
            self.pauseAllActiveUploads()
            task.setTaskCompleted(success: false)
        }

        // Continue upload processing
        Task {
            await self.processQueuedUploads()
            task.setTaskCompleted(success: true)
        }
    }

    private func saveUploadState(_ progress: UploadProgress) {
        // Save to UserDefaults for persistence
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(progress) {
            UserDefaults.standard.set(encoded, forKey: "upload_state_\(progress.id)")
            print("💾 [BackgroundUpload] Saved upload state for: \(progress.id)")
        }
    }

    private func loadUploadState(uploadId: String) -> UploadProgress? {
        guard let data = UserDefaults.standard.data(forKey: "upload_state_\(uploadId)") else {
            return nil
        }

        let decoder = JSONDecoder()
        return try? decoder.decode(UploadProgress.self, from: data)
    }

    private func scheduleRetryOnAppActivation(uploadId: String) {
        NotificationCenter.default.post(
            name: .uploadNeedsRetry,
            object: nil,
            userInfo: ["uploadId": uploadId]
        )
    }

    private func scheduleNextBackgroundTask() {
        let request = BGProcessingTaskRequest(identifier: Self.uploadTaskIdentifier)
        request.requiresNetworkConnectivity = true
        request.earliestBeginDate = Date(timeIntervalSinceNow: 30) // Try again in 30 seconds

        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ [BackgroundUpload] Scheduled next background task")
        } catch {
            print("❌ [BackgroundUpload] Failed to schedule next task: \(error)")
        }
    }

    private func pauseAllActiveUploads() {
        for (uploadId, _) in activeUploads {
            if var progress = activeUploads[uploadId] {
                progress.status = .paused
                progress.pauseReason = "Background time limit reached"
                saveUploadState(progress)
            }
        }
    }

    private func resumePausedUploads() async {
        // Look for saved upload states
        let keys = UserDefaults.standard.dictionaryRepresentation().keys
        let uploadKeys = keys.filter { $0.hasPrefix("upload_state_") }

        for key in uploadKeys {
            let uploadId = String(key.dropFirst("upload_state_".count))
            if let savedProgress = loadUploadState(uploadId: uploadId),
               savedProgress.status == .paused {
                print("🔄 [BackgroundUpload] Resuming upload: \(uploadId)")
                // Post notification to resume upload
                NotificationCenter.default.post(
                    name: .resumeUpload,
                    object: nil,
                    userInfo: ["uploadId": uploadId, "progress": savedProgress]
                )
            }
        }
    }

    private func processQueuedUploads() async {
        // Process any uploads waiting in queue
        print("📤 [BackgroundUpload] Processing queued uploads")
        // Implementation depends on upload queue system
    }

    private func getCurrentProcessingUploadId() -> String? {
        // Return the upload ID currently being processed
        return activeUploads.keys.first
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    @objc private func handleAppDidEnterBackground() {
        print("📱 [BackgroundUpload] App entered background with \(activeUploads.count) active uploads")
        // Ensure all active uploads have background tasks
        for (uploadId, progress) in activeUploads where progress.status == .uploading {
            if activeBackgroundTasks[uploadId] == nil && activeBGTasks[uploadId] == nil {
                beginBackgroundTask(for: uploadId, estimatedDuration: progress.estimatedDuration)
            }
        }
    }

    @objc private func handleAppWillEnterForeground() {
        print("📱 [BackgroundUpload] App entering foreground")
        // Clean up background tasks as they're no longer needed
        for (uploadId, taskId) in activeBackgroundTasks {
            UIApplication.shared.endBackgroundTask(taskId)
            print("🧹 [BackgroundUpload] Cleaned up background task for: \(uploadId)")
        }
        activeBackgroundTasks.removeAll()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Supporting Models

struct UploadProgress: Codable {
    let id: String
    let startTime: Date
    let estimatedDuration: TimeInterval
    var progress: Double = 0.0
    var status: UploadStatus = .queued
    var error: Error?
    var pauseReason: String?

    enum CodingKeys: String, CodingKey {
        case id, startTime, estimatedDuration, progress, status, pauseReason
    }

    enum UploadStatus: String, Codable {
        case queued
        case uploading
        case paused
        case completed
        case failed
    }

    init(id: String, startTime: Date, estimatedDuration: TimeInterval) {
        self.id = id
        self.startTime = startTime
        self.estimatedDuration = estimatedDuration
    }

    // Custom encoding to skip non-codable error
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(estimatedDuration, forKey: .estimatedDuration)
        try container.encode(progress, forKey: .progress)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(pauseReason, forKey: .pauseReason)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let uploadNeedsRetry = Notification.Name("com.brrow.upload.needsRetry")
    static let resumeUpload = Notification.Name("com.brrow.upload.resume")
}
