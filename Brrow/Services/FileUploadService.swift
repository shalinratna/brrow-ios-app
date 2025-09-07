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
    private let baseURL = "https://brrow-backend-nodejs-production.up.railway.app"
    
    func uploadImage(_ image: UIImage, fileName: String = UUID().uuidString + ".jpg") async throws -> String {
        isUploading = true
        progress = 0
        error = nil
        
        // Resize image and convert to Data
        guard let resizedImage = image.resized(to: CGSize(width: 1200, height: 1200)),
              let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
            throw FileUploadError.compressionFailed
        }
        
        // Convert to base64
        let base64String = imageData.base64EncodedString()
        let dataURL = "data:image/jpeg;base64,\(base64String)"
        
        // Create JSON payload
        let payload: [String: Any] = [
            "file": dataURL,
            "fileName": fileName,
            "fileType": "image/jpeg"
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            throw FileUploadError.invalidURL
        }
        
        // Create request - use Node.js upload endpoint 
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
    
    func uploadProfileImage(_ image: UIImage) async throws -> String {
        let fileName = "profile_\(AuthManager.shared.currentUser?.id ?? 0)_\(UUID().uuidString).jpg"
        return try await uploadImage(image, fileName: fileName)
    }
    
    func uploadMultipleImages(_ images: [UIImage]) async throws -> [String] {
        var uploadedUrls: [String] = []
        
        for image in images {
            let url = try await uploadImage(image)
            uploadedUrls.append(url)
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
