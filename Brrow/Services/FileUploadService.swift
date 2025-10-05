//
//  FileUploadService.swift
//  Brrow
//
//  Created by Shalin Ratna on 7/16/25.
//

import Foundation
import Combine
import UIKit

// MARK: - Upload Task Tracking
struct UploadTask {
    let taskIdentifier: Int
    let fileName: String
    var progress: Double = 0
    var error: Error?
    var result: String? // URL of uploaded file
}

class FileUploadService: NSObject, ObservableObject {
    static let shared = FileUploadService()

    @Published var isUploading = false
    @Published var progress: Double = 0
    @Published var error: String?

    private var cancellables = Set<AnyCancellable>()

    // Background upload tracking
    private var uploadTasks: [Int: UploadTask] = [:]
    private var uploadCompletionHandlers: [Int: (Result<String, Error>) -> Void] = [:]

    // Background URLSession configuration
    private lazy var backgroundSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "com.brrow.app.background-upload")
        config.isDiscretionary = false // Upload as soon as possible
        config.sessionSendsLaunchEvents = true // Wake app when upload completes
        config.shouldUseExtendedBackgroundIdleMode = true // Extended background time
        config.timeoutIntervalForRequest = 300 // 5 minutes timeout per request
        config.timeoutIntervalForResource = 3600 // 1 hour total timeout
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    // Use Railway backend URL
    private var baseURL: String {
        return APIEndpointManager.shared.currentEndpoint
    }

    // Override init to setup as NSObject for URLSessionDelegate
    override private init() {
        super.init()
        // Initialize background session on creation
        _ = backgroundSession
        print("📤 Background upload session initialized")
    }

    func uploadImage(_ image: UIImage, fileName: String = UUID().uuidString + ".jpg", useBackgroundSession: Bool = true) async throws -> String {
        await MainActor.run {
            self.isUploading = true
            self.progress = 0
            self.error = nil
        }

        print("🚀 [UPLOAD START] Beginning image upload (background: \(useBackgroundSession))")
        print("📐 Original image size: \(image.size.width)x\(image.size.height)")

        // High quality compression for better image quality
        let originalSize = image.size
        let maxDimension: CGFloat = 1920  // Much higher max size for better quality
        var compressionQuality: CGFloat = 0.90  // Start with 90% quality

        print("📏 Resizing to max dimension: \(maxDimension)px")

        // Resize first
        let resizedImage = image.resizedWithAspectRatio(maxDimension: maxDimension)
        print("✅ Resized to: \(resizedImage.size.width)x\(resizedImage.size.height)")

        // Try progressively lower quality until we get under reasonable size
        var imageData: Data?
        let targetSize = 2 * 1024 * 1024  // 2MB target - Much more reasonable

        print("🎯 Target size: \(targetSize / 1024 / 1024)MB")

        for quality in stride(from: compressionQuality, to: 0.6, by: -0.05) {
            if let data = resizedImage.jpegData(compressionQuality: quality) {
                print("  📊 Quality \(Int(quality * 100))%: \(data.count / 1024)KB")
                if data.count <= targetSize {
                    imageData = data
                    print("✅ SUCCESS: Image compressed to \(data.count / 1024)KB at \(Int(quality * 100))% quality")
                    break
                } else if quality <= 0.65 {
                    // Last resort - use this even if too big (still good quality)
                    imageData = data
                    print("⚠️ WARNING: Image still \(data.count / 1024)KB at minimum quality \(Int(quality * 100))%")
                    break
                }
            }
        }

        guard let finalImageData = imageData else {
            print("❌ ERROR: Failed to compress image")
            throw FileUploadError.compressionFailed
        }

        // For now, still use JSON but with optimized image
        let base64String = finalImageData.base64EncodedString()

        print("📦 Base64 size: \(base64String.count / 1024)KB")

        let payload: [String: Any] = [
            "image": base64String,
            "type": "listing",
            "preserve_metadata": true
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            print("❌ ERROR: Failed to create JSON payload")
            throw FileUploadError.invalidURL
        }

        print("📤 Final payload size: \(jsonData.count / 1024)KB")

        // Create request - use Railway Node.js upload endpoint
        guard let url = URL(string: "\(baseURL)/api/upload") else {
            throw FileUploadError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add auth token if available
        if let token = AuthManager.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Add user API ID if available
        if let user = AuthManager.shared.currentUser {
            request.setValue(user.apiId, forHTTPHeaderField: "X-User-API-ID")
        }

        // Use background session for reliable uploads
        if useBackgroundSession {
            return try await performBackgroundUpload(request: request, data: jsonData, fileName: fileName)
        } else {
            // Fallback to regular upload
            return try await performRegularUpload(request: request, data: jsonData)
        }
    }

    // MARK: - Background Upload Implementation

    private func performBackgroundUpload(request: URLRequest, data: Data, fileName: String) async throws -> String {
        // Save data to temp file for background upload
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try data.write(to: tempURL)

        // Begin UIBackgroundTask to keep upload alive when app backgrounds
        let uploadId = UUID().uuidString
        BackgroundUploadTaskManager.shared.beginBackgroundTask(
            for: uploadId,
            estimatedDuration: estimateUploadDuration(dataSize: data.count)
        )

        return try await withCheckedThrowingContinuation { continuation in
            let uploadTask = backgroundSession.uploadTask(with: request, fromFile: tempURL)

            // Track this upload
            let task = UploadTask(taskIdentifier: uploadTask.taskIdentifier, fileName: fileName)
            uploadTasks[uploadTask.taskIdentifier] = task

            // Store completion handler
            uploadCompletionHandlers[uploadTask.taskIdentifier] = { result in
                // End background task
                BackgroundUploadTaskManager.shared.endBackgroundTask(for: uploadId)

                continuation.resume(with: result)

                // Clean up temp file
                try? FileManager.default.removeItem(at: tempURL)
            }

            print("📤 [BACKGROUND] Starting upload task \(uploadTask.taskIdentifier) with background protection")
            uploadTask.resume()

            // Start progress simulation
            Task {
                await self.simulateUploadProgress()
            }
        }
    }

    /// Estimate upload duration based on data size
    /// Assumes average upload speed of 1 Mbps (conservative for mobile)
    private func estimateUploadDuration(dataSize: Int) -> TimeInterval {
        let bytesPerSecond = 125_000.0 // 1 Mbps = 125 KB/s
        let estimatedSeconds = Double(dataSize) / bytesPerSecond
        // Add 50% buffer for network variability
        return min(estimatedSeconds * 1.5, 25.0) // Cap at 25 seconds for UIBackgroundTask
    }

    // MARK: - Regular Upload (Fallback)

    private func performRegularUpload(request: URLRequest, data: Data) async throws -> String {
        var mutableRequest = request
        mutableRequest.httpBody = data

        // Start progress simulation
        Task {
            await simulateUploadProgress()
        }

        do {
            let (responseData, response) = try await URLSession.shared.data(for: mutableRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw FileUploadError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                throw FileUploadError.serverError("HTTP Error: \(httpResponse.statusCode)")
            }

            // Decode the API response
            if let json = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any],
               let success = json["success"] as? Bool,
               success,
               let data = json["data"] as? [String: Any],
               let fileUrl = data["url"] as? String {

                await MainActor.run {
                    self.isUploading = false
                    self.progress = 1.0
                }

                print("✅ File uploaded successfully: \(fileUrl)")
                return fileUrl
            } else {
                throw FileUploadError.invalidResponse
            }

        } catch {
            await MainActor.run {
                self.isUploading = false
                self.error = error.localizedDescription
            }

            if let fileError = error as? FileUploadError {
                throw fileError
            } else {
                throw FileUploadError.uploadFailed
            }
        }
    }
    
    // Simulate upload progress for better UX
    private func simulateUploadProgress() async {
        await MainActor.run {
            self.progress = 0.1
        }

        for i in 1...8 {
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            await MainActor.run {
                self.progress = Double(i) * 0.1
            }
        }
    }

    func uploadProfileImage(_ image: UIImage) async throws -> String {
        let fileName = "profile_\(AuthManager.shared.currentUser?.id ?? "0")_\(UUID().uuidString).jpg"
        return try await uploadImage(image, fileName: fileName)
    }
    
    func uploadMultipleImages(_ images: [UIImage]) async throws -> [String] {
        var uploadedUrls: [String] = []
        var failureCount = 0
        let maxConsecutiveFailures = 2
        
        for (index, image) in images.enumerated() {
            do {
                print("📤 Uploading image \(index + 1) of \(images.count)...")
                let url = try await uploadImage(image)
                uploadedUrls.append(url)
                failureCount = 0 // Reset failure count on success
                print("✅ Successfully uploaded image \(index + 1)")
            } catch {
                failureCount += 1
                print("❌ Failed to upload image \(index + 1): \(error.localizedDescription)")
                
                // Early failure detection: stop after 2 consecutive failures
                if failureCount >= maxConsecutiveFailures {
                    print("🚨 Early failure detected after \(failureCount) consecutive failures. Stopping upload process.")
                    throw FileUploadError.multipleFailures(
                        message: "Upload failed after \(failureCount) consecutive attempts. Please check your connection and try again.",
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
    
    // MARK: - Video Upload

    func uploadVideo(_ videoURL: URL, thumbnail: UIImage? = nil) async throws -> VideoUploadResult {
        isUploading = true
        progress = 0
        error = nil

        print("🎥 [VIDEO UPLOAD] Starting video upload")

        // Read video data
        guard let videoData = try? Data(contentsOf: videoURL) else {
            throw FileUploadError.compressionFailed
        }

        print("📦 Video size: \(videoData.count / 1024 / 1024)MB")

        // Upload thumbnail first if provided
        var thumbnailURL: String?
        if let thumbnail = thumbnail {
            do {
                thumbnailURL = try await uploadImage(thumbnail, fileName: "thumb_\(UUID().uuidString).jpg")
                print("✅ Thumbnail uploaded: \(thumbnailURL ?? "")")
            } catch {
                print("⚠️ Thumbnail upload failed, continuing with video...")
            }
        }

        // Create multipart request for video
        guard let url = URL(string: "\(baseURL)/api/upload/video") else {
            throw FileUploadError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        if let token = AuthManager.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let user = AuthManager.shared.currentUser {
            request.setValue(user.apiId, forHTTPHeaderField: "X-User-API-ID")
        }

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add video file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"video\"; filename=\"video.mp4\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: video/mp4\r\n\r\n".data(using: .utf8)!)
        body.append(videoData)
        body.append("\r\n".data(using: .utf8)!)

        // Add thumbnail URL if available
        if let thumbnailURL = thumbnailURL {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"thumbnailUrl\"\r\n\r\n".data(using: .utf8)!)
            body.append(thumbnailURL.data(using: .utf8)!)
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        // Start progress simulation
        Task {
            await simulateUploadProgress()
        }

        do {
            let (responseData, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw FileUploadError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                throw FileUploadError.serverError("HTTP Error: \(httpResponse.statusCode)")
            }

            if let json = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any],
               let success = json["success"] as? Bool,
               success,
               let data = json["data"] as? [String: Any],
               let videoUrl = data["url"] as? String {

                await MainActor.run {
                    self.isUploading = false
                    self.progress = 1.0
                }

                let result = VideoUploadResult(
                    videoURL: videoUrl,
                    thumbnailURL: data["thumbnailUrl"] as? String ?? thumbnailURL
                )

                print("✅ Video uploaded successfully: \(videoUrl)")
                return result
            } else {
                throw FileUploadError.invalidResponse
            }
        } catch {
            await MainActor.run {
                self.isUploading = false
                self.error = error.localizedDescription
            }
            throw error
        }
    }

    // MARK: - File Upload

    func uploadFile(_ fileURL: URL) async throws -> FileUploadResult {
        isUploading = true
        progress = 0
        error = nil

        print("📄 [FILE UPLOAD] Starting file upload")

        // Read file data
        guard let fileData = try? Data(contentsOf: fileURL) else {
            throw FileUploadError.compressionFailed
        }

        let fileName = fileURL.lastPathComponent
        let fileSize = fileData.count

        print("📦 File: \(fileName), Size: \(fileSize / 1024)KB")

        // Validate file size (max 10MB for files)
        if fileSize > 10 * 1024 * 1024 {
            throw FileUploadError.serverError("File too large. Maximum size is 10MB")
        }

        // Create multipart request
        guard let url = URL(string: "\(baseURL)/api/upload/file") else {
            throw FileUploadError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        if let token = AuthManager.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let user = AuthManager.shared.currentUser {
            request.setValue(user.apiId, forHTTPHeaderField: "X-User-API-ID")
        }

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)

        // Determine MIME type
        let mimeType = getMimeType(for: fileURL)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        // Start progress simulation
        Task {
            await simulateUploadProgress()
        }

        do {
            let (responseData, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw FileUploadError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                throw FileUploadError.serverError("HTTP Error: \(httpResponse.statusCode)")
            }

            if let json = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any],
               let success = json["success"] as? Bool,
               success,
               let data = json["data"] as? [String: Any],
               let fileUrl = data["url"] as? String {

                await MainActor.run {
                    self.isUploading = false
                    self.progress = 1.0
                }

                let result = FileUploadResult(
                    fileURL: fileUrl,
                    fileName: fileName,
                    fileSize: Int64(fileSize),
                    mimeType: mimeType
                )

                print("✅ File uploaded successfully: \(fileUrl)")
                return result
            } else {
                throw FileUploadError.invalidResponse
            }
        } catch {
            await MainActor.run {
                self.isUploading = false
                self.error = error.localizedDescription
            }
            throw error
        }
    }

    private func getMimeType(for url: URL) -> String {
        let ext = url.pathExtension.lowercased()

        switch ext {
        case "pdf":
            return "application/pdf"
        case "doc":
            return "application/msword"
        case "docx":
            return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case "txt":
            return "text/plain"
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "mp4":
            return "video/mp4"
        case "mov":
            return "video/quicktime"
        default:
            return "application/octet-stream"
        }
    }

    private func trackFileUpload(fileId: String, fileSize: Int) {
        AnalyticsService.shared.track(event: "file_uploaded", properties: [
            "file_id": fileId,
            "file_size": fileSize
        ])
        print("File upload completed: \(fileId), size: \(fileSize)")
    }

    private func trackFileUploadError(_ error: Error) {
        AnalyticsService.shared.trackError(error: error, context: "file_upload")
        print("File upload error: \(error.localizedDescription)")
    }
}

// MARK: - URLSessionDelegate for Background Uploads
extension FileUploadService: URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate {

    // Called when all messages for a session have been delivered
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        print("📤 [BACKGROUND] All background upload events finished")

        DispatchQueue.main.async {
            // Notify AppDelegate that background processing is complete
            NotificationCenter.default.post(name: .backgroundUploadComplete, object: nil)
        }
    }

    // Track upload progress
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let uploadProgress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)

        print("📤 [BACKGROUND] Upload progress: \(Int(uploadProgress * 100))%")

        // Update tracking
        if var uploadTask = uploadTasks[task.taskIdentifier] {
            uploadTask.progress = uploadProgress
            uploadTasks[task.taskIdentifier] = uploadTask
        }

        // Update UI progress
        DispatchQueue.main.async {
            self.progress = uploadProgress
        }
    }

    // Handle upload completion
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        defer {
            // Clean up tracking
            uploadTasks.removeValue(forKey: task.taskIdentifier)
        }

        guard let completionHandler = uploadCompletionHandlers.removeValue(forKey: task.taskIdentifier) else {
            print("⚠️ [BACKGROUND] No completion handler for task \(task.taskIdentifier)")
            return
        }

        if let error = error {
            print("❌ [BACKGROUND] Upload failed: \(error.localizedDescription)")

            DispatchQueue.main.async {
                self.isUploading = false
                self.error = error.localizedDescription
            }

            completionHandler(.failure(error))
            return
        }

        print("✅ [BACKGROUND] Upload completed for task \(task.taskIdentifier)")
    }

    // Collect response data
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let taskIdentifier = uploadTasks.keys.first(where: { $0 == dataTask.taskIdentifier }) else {
            return
        }

        print("📥 [BACKGROUND] Received response data (\(data.count) bytes)")

        // Parse response
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let success = json["success"] as? Bool,
               success,
               let responseData = json["data"] as? [String: Any],
               let fileUrl = responseData["url"] as? String {

                print("✅ [BACKGROUND] Upload successful: \(fileUrl)")

                // Update tracking
                if var uploadTask = uploadTasks[taskIdentifier] {
                    uploadTask.result = fileUrl
                    uploadTasks[taskIdentifier] = uploadTask
                }

                DispatchQueue.main.async {
                    self.isUploading = false
                    self.progress = 1.0
                }

                // Call completion handler
                if let completionHandler = uploadCompletionHandlers[taskIdentifier] {
                    completionHandler(.success(fileUrl))
                }
            } else {
                print("❌ [BACKGROUND] Invalid response format")

                DispatchQueue.main.async {
                    self.isUploading = false
                    self.error = "Invalid response from server"
                }

                if let completionHandler = uploadCompletionHandlers[taskIdentifier] {
                    completionHandler(.failure(FileUploadError.invalidResponse))
                }
            }
        } catch {
            print("❌ [BACKGROUND] Failed to parse response: \(error)")

            DispatchQueue.main.async {
                self.isUploading = false
                self.error = error.localizedDescription
            }

            if let completionHandler = uploadCompletionHandlers[taskIdentifier] {
                completionHandler(.failure(error))
            }
        }
    }

    // Handle authentication challenges (if needed)
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // Accept all SSL certificates in development (remove in production)
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let serverTrust = challenge.protectionSpace.serverTrust {
                completionHandler(.useCredential, URLCredential(trust: serverTrust))
                return
            }
        }

        completionHandler(.performDefaultHandling, nil)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let backgroundUploadComplete = Notification.Name("backgroundUploadComplete")
}

// MARK: - Upload Result Models

struct VideoUploadResult {
    let videoURL: String
    let thumbnailURL: String?
}

struct FileUploadResult {
    let fileURL: String
    let fileName: String
    let fileSize: Int64
    let mimeType: String
}

// MARK: - Response Models
struct FileUploadResponse: Codable {
    let success: Bool
    let fileUrl: String
    let fileId: String
    let message: String?
}

// MARK: - UIImage Extension
extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
