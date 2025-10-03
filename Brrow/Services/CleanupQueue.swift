//
//  CleanupQueue.swift
//  Brrow
//
//  Manages cleanup of orphaned uploads when users cancel or back out during upload
//

import Foundation
import Combine

@MainActor
class CleanupQueue: ObservableObject {
    static let shared = CleanupQueue()

    // MARK: - Published Properties
    @Published var queuedForDeletion: [String] = []
    @Published var isProcessingCleanup = false

    // MARK: - Private Properties
    private var cleanupTimer: Timer?
    private let maxRetries = 3
    private let batchSize = 10
    private let cleanupInterval: TimeInterval = 30 // Clean up every 30 seconds

    // MARK: - Initialization
    private init() {
        startCleanupTimer()
    }

    deinit {
        cleanupTimer?.invalidate()
    }

    // MARK: - Public Interface

    /// Add URLs to deletion queue
    func addForDeletion(urls: [String]) {
        guard !urls.isEmpty else { return }

        print("🗑️ Adding \(urls.count) URLs to cleanup queue")
        queuedForDeletion.append(contentsOf: urls)

        // If queue is large, process immediately
        if queuedForDeletion.count >= batchSize {
            Task {
                await processCleanupQueue()
            }
        }
    }

    /// Process cleanup queue immediately
    func processImmediately() async {
        await processCleanupQueue()
    }

    /// Clear all queued items (use with caution)
    func clearQueue() {
        print("🗑️ Clearing cleanup queue")
        queuedForDeletion.removeAll()
    }

    // MARK: - Private Methods

    private func startCleanupTimer() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: cleanupInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.processCleanupQueue()
            }
        }
    }

    private func processCleanupQueue() async {
        guard !isProcessingCleanup && !queuedForDeletion.isEmpty else { return }

        isProcessingCleanup = true

        let urlsToDelete = Array(queuedForDeletion.prefix(batchSize))
        print("🗑️ Processing cleanup queue: \(urlsToDelete.count) URLs")

        var successfulDeletions = 0

        for url in urlsToDelete {
            do {
                try await deleteUploadedFile(url)
                successfulDeletions += 1

                // Remove from queue on success
                if let index = queuedForDeletion.firstIndex(of: url) {
                    queuedForDeletion.remove(at: index)
                }
            } catch {
                print("⚠️ Failed to delete \(url): \(error.localizedDescription)")
                // Keep in queue for retry, but move to end
                if let index = queuedForDeletion.firstIndex(of: url) {
                    queuedForDeletion.remove(at: index)
                    queuedForDeletion.append(url)
                }
            }
        }

        print("✅ Cleanup complete: \(successfulDeletions)/\(urlsToDelete.count) deleted")
        isProcessingCleanup = false
    }

    private func deleteUploadedFile(_ url: String) async throws {
        // Extract public_id from Cloudinary URL
        guard let publicId = extractPublicId(from: url) else {
            throw CleanupError.invalidURL
        }

        let baseURL = await APIEndpointManager.shared.getBestEndpoint()
        guard let deleteURL = URL(string: "\(baseURL)/api/upload/delete") else {
            throw CleanupError.invalidURL
        }

        var request = URLRequest(url: deleteURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add auth headers
        if let token = AuthManager.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let user = AuthManager.shared.currentUser {
            request.setValue(user.apiId, forHTTPHeaderField: "X-User-API-ID")
        }

        let payload: [String: Any] = [
            "public_id": publicId
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CleanupError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw CleanupError.serverError(httpResponse.statusCode)
        }

        print("✅ Deleted orphaned upload: \(publicId)")
    }

    private func extractPublicId(from url: String) -> String? {
        // Cloudinary URL format: https://res.cloudinary.com/{cloud_name}/image/upload/{version}/{public_id}.jpg
        guard let urlObj = URL(string: url) else { return nil }

        let pathComponents = urlObj.pathComponents
        guard pathComponents.count >= 3 else { return nil }

        // Find "upload" component
        if let uploadIndex = pathComponents.firstIndex(of: "upload"), uploadIndex + 2 < pathComponents.count {
            let publicIdWithExt = pathComponents[uploadIndex + 2]
            // Remove file extension
            let publicId = (publicIdWithExt as NSString).deletingPathExtension
            return publicId
        }

        return nil
    }
}

// MARK: - Error Types
enum CleanupError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid cleanup URL"
        case .invalidResponse:
            return "Invalid server response"
        case .serverError(let code):
            return "Server error: \(code)"
        }
    }
}
