//
//  FileUploadService.swift
//  Brrow
//
//  Created by Shalin Ratna on 7/16/25.
//

import Foundation
import Combine
import UIKit

class FileUploadService: ObservableObject {
    static let shared = FileUploadService()
    
    @Published var isUploading = false
    @Published var progress: Double = 0
    @Published var error: String?
    
    private var cancellables = Set<AnyCancellable>()

    // Use Railway backend URL
    private var baseURL: String {
        return APIEndpointManager.shared.currentEndpoint
    }

    func uploadImage(_ image: UIImage, fileName: String = UUID().uuidString + ".jpg") async throws -> String {
        isUploading = true
        progress = 0
        error = nil

        // AGGRESSIVE compression to prevent timeouts
        let originalSize = image.size
        let maxDimension: CGFloat = 800  // Much smaller max size
        var compressionQuality: CGFloat = 0.5  // Start with 50% quality

        // Resize first
        let resizedImage = image.resizedWithAspectRatio(maxDimension: maxDimension)

        // Try progressively lower quality until we get under 100KB
        var imageData: Data?
        let targetSize = 100 * 1024  // 100KB target for base64 (becomes ~133KB)

        for quality in stride(from: compressionQuality, to: 0.1, by: -0.1) {
            if let data = resizedImage.jpegData(compressionQuality: quality) {
                if data.count <= targetSize {
                    imageData = data
                    print("📸 Image compressed to \(data.count / 1024)KB at \(Int(quality * 100))% quality")
                    break
                } else if quality <= 0.2 {
                    // Last resort - use this even if too big
                    imageData = data
                    print("⚠️ Image still \(data.count / 1024)KB at minimum quality")
                    break
                }
            }
        }

        guard let finalImageData = imageData else {
            throw FileUploadError.compressionFailed
        }

        // For now, still use JSON but with optimized image
        // TODO: Switch to multipart when backend supports it
        let base64String = finalImageData.base64EncodedString()

        let payload: [String: Any] = [
            "image": base64String,
            "type": "listing",
            "preserve_metadata": true
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            throw FileUploadError.invalidURL
        }

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
        
        request.httpBody = jsonData

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
                
                print("File uploaded successfully: \(fileUrl)")
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
            } else if let apiError = error as? BrrowAPIError {
                throw apiError
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
    
    private func trackFileUpload(fileId: String, fileSize: Int) {
        // TODO: Track analytics for file upload
        print("File upload completed: \(fileId), size: \(fileSize)")
    }
    
    private func trackFileUploadError(_ error: Error) {
        // TODO: Track analytics for file upload error
        print("File upload error: \(error.localizedDescription)")
    }
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
