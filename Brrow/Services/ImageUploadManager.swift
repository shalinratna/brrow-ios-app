//
//  ImageUploadManager.swift
//  Brrow
//
//  Optimized image uploading with compression and quality settings
//

import SwiftUI
import Combine

class ImageUploadManager {
    static let shared = ImageUploadManager()
    
    // Upload configuration
    private let maxImageSize: CGFloat = 1920 // Max dimension (width or height)
    private let thumbnailSize: CGFloat = 400
    private let jpegCompressionQuality: CGFloat = 0.85
    private let maxFileSize: Int = 5 * 1024 * 1024 // 5MB
    
    private init() {}
    
    // MARK: - Public Methods
    
    func uploadImages(_ images: [UIImage], endpoint: String) async throws -> [String] {
        var uploadedUrls: [String] = []
        
        // Process images in parallel for speed
        await withTaskGroup(of: (Int, String?).self) { group in
            for (index, image) in images.enumerated() {
                group.addTask { [weak self] in
                    guard let self = self else { return (index, nil) }
                    
                    // Optimize image
                    let optimizedImage = self.optimizeImageForUpload(image)
                    
                    // Upload image
                    do {
                        let url = try await self.uploadSingleImage(optimizedImage, endpoint: endpoint)
                        return (index, url)
                    } catch {
                        print("Failed to upload image \(index): \(error)")
                        return (index, nil)
                    }
                }
            }
            
            // Collect results in order
            var results = [(Int, String?)]()
            for await result in group {
                results.append(result)
            }
            
            // Sort by index to maintain order
            results.sort { $0.0 < $1.0 }
            uploadedUrls = results.compactMap { $0.1 }
        }
        
        return uploadedUrls
    }
    
    func uploadImageWithThumbnail(_ image: UIImage, endpoint: String) async throws -> (fullUrl: String, thumbnailUrl: String) {
        // Create optimized versions
        let fullImage = optimizeImageForUpload(image)
        let thumbnail = createThumbnail(from: image)
        
        // Upload both versions
        async let fullUpload = uploadSingleImage(fullImage, endpoint: endpoint)
        async let thumbUpload = uploadSingleImage(thumbnail, endpoint: "\(endpoint)?type=thumbnail")
        
        let (fullUrl, thumbUrl) = try await (fullUpload, thumbUpload)
        
        return (fullUrl, thumbUrl)
    }
    
    // MARK: - Private Methods
    
    func optimizeImageForUpload(_ image: UIImage) -> UIImage {
        // Calculate new size maintaining aspect ratio
        let size = image.size
        let ratio = min(maxImageSize / size.width, maxImageSize / size.height)
        
        // Only resize if image is larger than max
        let newSize: CGSize
        if ratio < 1 {
            newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        } else {
            newSize = size
        }
        
        // Create resized image with high quality
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        
        // Compress to JPEG with quality setting
        var compressionQuality = jpegCompressionQuality
        var imageData = resizedImage.jpegData(compressionQuality: compressionQuality)
        
        // Further compress if still too large
        while let data = imageData, data.count > maxFileSize && compressionQuality > 0.3 {
            compressionQuality -= 0.1
            imageData = resizedImage.jpegData(compressionQuality: compressionQuality)
        }
        
        // Return optimized image
        if let data = imageData, let optimized = UIImage(data: data) {
            return optimized
        }
        
        return resizedImage
    }
    
    private func createThumbnail(from image: UIImage) -> UIImage {
        let size = image.size
        let ratio = min(thumbnailSize / size.width, thumbnailSize / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let thumbnail = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        
        return thumbnail
    }
    
    private func uploadSingleImage(_ image: UIImage, endpoint: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: jpegCompressionQuality) else {
            throw ImageUploadError.compressionFailed
        }
        
        // Create multipart form data
        let boundary = UUID().uuidString
        var body = Data()
        
        // Add image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add user info if available
        if let userApiId = AuthManager.shared.currentUser?.apiId {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"user_api_id\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(userApiId)\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        // Create request
        guard let url = URL(string: "\(APIClient.shared.baseURL)/\(endpoint)") else {
            throw ImageUploadError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        // Add auth header
        if let token = AuthManager.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Perform upload
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ImageUploadError.uploadFailed
        }
        
        // Parse response
        struct UploadResponse: Codable {
            let success: Bool
            let data: UploadData?
            let message: String?
            
            struct UploadData: Codable {
                let url: String
                let thumbnail_url: String?
            }
        }
        
        let uploadResponse = try JSONDecoder().decode(UploadResponse.self, from: data)
        
        guard uploadResponse.success, let imageUrl = uploadResponse.data?.url else {
            throw ImageUploadError.serverError(uploadResponse.message ?? "Upload failed")
        }
        
        return imageUrl
    }
}

// MARK: - Error Types

enum ImageUploadError: LocalizedError {
    case compressionFailed
    case invalidURL
    case uploadFailed
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "Failed to compress image"
        case .invalidURL:
            return "Invalid upload URL"
        case .uploadFailed:
            return "Image upload failed"
        case .serverError(let message):
            return message
        }
    }
}

// MARK: - Image Picker with Optimization

struct OptimizedImagePicker: UIViewControllerRepresentable {
    @Binding var images: [UIImage]
    @Environment(\.dismiss) private var dismiss
    let maxImages: Int
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: OptimizedImagePicker
        
        init(_ parent: OptimizedImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                // Optimize image immediately upon selection
                let optimized = ImageUploadManager.shared.optimizeImageForUpload(image)
                
                if parent.images.count < parent.maxImages {
                    parent.images.append(optimized)
                }
            }
            
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}