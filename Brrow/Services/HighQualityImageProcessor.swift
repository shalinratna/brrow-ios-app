//
//  HighQualityImageProcessor.swift
//  Brrow
//
//  High-quality image processing with adaptive sizing and optimal compression
//

import UIKit
import CoreGraphics
import Accelerate
import Photos

// MARK: - Image Processing Configuration
struct ImageProcessingConfig {
    // Quality settings
    let compressionQuality: CGFloat
    let useHEICFormat: Bool
    
    // Size settings for different contexts
    let listingMaxDimension: CGFloat
    let garageSaleMaxDimension: CGFloat
    let profileMaxDimension: CGFloat
    let thumbnailDimension: CGFloat
    
    // Performance settings
    let maxConcurrentUploads: Int
    let chunkSize: Int // For chunked uploads
    
    static let highQuality = ImageProcessingConfig(
        compressionQuality: 0.95,  // Highest quality JPEG
        useHEICFormat: false,       // Use JPEG for compatibility
        listingMaxDimension: 2400,  // High resolution for listings
        garageSaleMaxDimension: 2000,
        profileMaxDimension: 1200,
        thumbnailDimension: 600,
        maxConcurrentUploads: 3,
        chunkSize: 1024 * 512      // 512KB chunks
    )
    
    static let balanced = ImageProcessingConfig(
        compressionQuality: 0.90,
        useHEICFormat: false,
        listingMaxDimension: 1920,
        garageSaleMaxDimension: 1600,
        profileMaxDimension: 1000,
        thumbnailDimension: 400,
        maxConcurrentUploads: 2,
        chunkSize: 1024 * 256
    )
}

// MARK: - Image Context
enum ImageContext {
    case listing
    case garageSale
    case profile
    case thumbnail
    
    var aspectRatios: [CGFloat] {
        switch self {
        case .listing:
            return [1.0, 4.0/3.0, 16.0/9.0] // Square, 4:3, 16:9
        case .garageSale:
            return [1.0, 4.0/3.0, 3.0/2.0]
        case .profile:
            return [1.0] // Square only
        case .thumbnail:
            return [1.0, 4.0/3.0]
        }
    }
    
    func maxDimension(for config: ImageProcessingConfig) -> CGFloat {
        switch self {
        case .listing:
            return config.listingMaxDimension
        case .garageSale:
            return config.garageSaleMaxDimension
        case .profile:
            return config.profileMaxDimension
        case .thumbnail:
            return config.thumbnailDimension
        }
    }
}

// MARK: - High Quality Image Processor
class HighQualityImageProcessor {
    static let shared = HighQualityImageProcessor()
    
    private let config = ImageProcessingConfig.highQuality
    private let uploadQueue = DispatchQueue(label: "com.brrow.imageupload", qos: .userInitiated, attributes: .concurrent)
    private let processingQueue = OperationQueue()
    
    private init() {
        processingQueue.maxConcurrentOperationCount = config.maxConcurrentUploads
        processingQueue.qualityOfService = .userInitiated
    }
    
    // MARK: - Main Processing Methods
    
    /// Process image with highest quality for specific context
    func processImage(_ image: UIImage, for context: ImageContext) async throws -> ProcessedImage {
        return try await withCheckedThrowingContinuation { continuation in
            uploadQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: ImageProcessingError.processorDeallocated)
                    return
                }
                
                do {
                    // Step 1: Fix orientation
                    let orientedImage = self.fixImageOrientation(image)
                    
                    // Step 2: Smart resize with aspect ratio preservation
                    let resized = self.smartResize(orientedImage, for: context)
                    
                    // Step 3: Apply image enhancements
                    let enhanced = self.enhanceImage(resized)
                    
                    // Step 4: Generate data with highest quality
                    let imageData = try self.generateHighQualityData(enhanced)
                    
                    // Step 5: Generate thumbnail
                    let thumbnail = self.generateThumbnail(resized)
                    let thumbnailData = try self.generateHighQualityData(thumbnail)
                    
                    let processed = ProcessedImage(
                        fullImage: enhanced,
                        thumbnail: thumbnail,
                        fullImageData: imageData,
                        thumbnailData: thumbnailData,
                        dimensions: CGSize(width: enhanced.size.width, height: enhanced.size.height),
                        fileSize: imageData.count
                    )
                    
                    continuation.resume(returning: processed)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Process multiple images in parallel with progress tracking
    func processImages(_ images: [UIImage], for context: ImageContext, progress: ((Float) -> Void)? = nil) async throws -> [ProcessedImage] {
        let totalImages = images.count
        var processedCount = 0
        var results: [ProcessedImage] = []
        
        try await withThrowingTaskGroup(of: (Int, ProcessedImage).self) { group in
            for (index, image) in images.enumerated() {
                group.addTask { [weak self] in
                    guard let self = self else {
                        throw ImageProcessingError.processorDeallocated
                    }
                    let processed = try await self.processImage(image, for: context)
                    return (index, processed)
                }
            }
            
            var indexedResults: [(Int, ProcessedImage)] = []
            for try await result in group {
                indexedResults.append(result)
                processedCount += 1
                await MainActor.run {
                    progress?(Float(processedCount) / Float(totalImages))
                }
            }
            
            // Sort by original index
            indexedResults.sort { $0.0 < $1.0 }
            results = indexedResults.map { $0.1 }
        }
        
        return results
    }
    
    // MARK: - Image Enhancement
    
    private func enhanceImage(_ image: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }
        
        let context = CIContext(options: [
            .useSoftwareRenderer: false,
            .highQualityDownsample: true
        ])
        
        // Apply subtle enhancements
        var enhanced = ciImage
        
        // Auto-adjust exposure and contrast
        let autoAdjust = enhanced.autoAdjustmentFilters()
        for filter in autoAdjust {
            filter.setValue(enhanced, forKey: kCIInputImageKey)
            if let output = filter.outputImage {
                enhanced = output
            }
        }
        
        // Slight sharpening for clarity
        if let sharpnessFilter = CIFilter(name: "CISharpenLuminance") {
            sharpnessFilter.setValue(enhanced, forKey: kCIInputImageKey)
            sharpnessFilter.setValue(0.4, forKey: "inputSharpness") // Subtle sharpening
            if let output = sharpnessFilter.outputImage {
                enhanced = output
            }
        }
        
        // Noise reduction for cleaner images
        if let noiseReduction = CIFilter(name: "CINoiseReduction") {
            noiseReduction.setValue(enhanced, forKey: kCIInputImageKey)
            noiseReduction.setValue(0.02, forKey: "inputNoiseLevel")
            noiseReduction.setValue(0.4, forKey: "inputSharpness")
            if let output = noiseReduction.outputImage {
                enhanced = output
            }
        }
        
        // Convert back to UIImage
        if let cgImage = context.createCGImage(enhanced, from: enhanced.extent) {
            return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        }
        
        return image
    }
    
    // MARK: - Smart Resizing
    
    private func smartResize(_ image: UIImage, for context: ImageContext) -> UIImage {
        let maxDimension = context.maxDimension(for: config)
        let size = image.size
        
        // Don't upscale images
        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }
        
        // Calculate new size maintaining aspect ratio
        let aspectRatio = size.width / size.height
        var newSize: CGSize
        
        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        
        // Use high-quality rendering
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0 // Use 1.0 for consistent sizing
        format.opaque = false
        format.preferredRange = .standard
        
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        
        return renderer.image { context in
            // Use high-quality interpolation
            context.cgContext.interpolationQuality = .high
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    // MARK: - Orientation Fix
    
    private func fixImageOrientation(_ image: UIImage) -> UIImage {
        if image.imageOrientation == .up {
            return image
        }
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalizedImage ?? image
    }
    
    // MARK: - High Quality Data Generation
    
    private func generateHighQualityData(_ image: UIImage) throws -> Data {
        // Try JPEG with highest quality first
        if let jpegData = image.jpegData(compressionQuality: config.compressionQuality) {
            // Check if size is reasonable (under 10MB)
            if jpegData.count < 10 * 1024 * 1024 {
                return jpegData
            }
            
            // If too large, try progressive compression
            var quality = config.compressionQuality
            var data = jpegData
            
            while data.count > 8 * 1024 * 1024 && quality > 0.85 {
                quality -= 0.05
                if let newData = image.jpegData(compressionQuality: quality) {
                    data = newData
                }
            }
            
            return data
        }
        
        throw ImageProcessingError.compressionFailed
    }
    
    // MARK: - Thumbnail Generation
    
    private func generateThumbnail(_ image: UIImage) -> UIImage {
        let thumbnailSize = CGSize(
            width: config.thumbnailDimension,
            height: config.thumbnailDimension
        )
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: thumbnailSize, format: format)
        
        return renderer.image { context in
            context.cgContext.interpolationQuality = .high
            
            // Calculate aspect fill rect
            let aspectRatio = image.size.width / image.size.height
            var drawRect = CGRect(origin: .zero, size: thumbnailSize)
            
            if aspectRatio > 1 {
                // Wider than tall
                drawRect.size.width = thumbnailSize.height * aspectRatio
                drawRect.origin.x = (thumbnailSize.width - drawRect.width) / 2
            } else {
                // Taller than wide
                drawRect.size.height = thumbnailSize.width / aspectRatio
                drawRect.origin.y = (thumbnailSize.height - drawRect.height) / 2
            }
            
            image.draw(in: drawRect)
        }
    }
}

// MARK: - Supporting Types

struct ProcessedImage {
    let fullImage: UIImage
    let thumbnail: UIImage
    let fullImageData: Data
    let thumbnailData: Data
    let dimensions: CGSize
    let fileSize: Int
    
    var readableFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(fileSize))
    }
}

enum ImageProcessingError: LocalizedError {
    case processorDeallocated
    case compressionFailed
    case invalidImage
    case sizeTooLarge
    
    var errorDescription: String? {
        switch self {
        case .processorDeallocated:
            return "Image processor was deallocated"
        case .compressionFailed:
            return "Failed to compress image"
        case .invalidImage:
            return "Invalid image data"
        case .sizeTooLarge:
            return "Image size exceeds maximum allowed"
        }
    }
}

// MARK: - Parallel Upload Manager

extension HighQualityImageProcessor {
    
    /// Upload processed images with entity context for organized storage
    func uploadProcessedImages(_ images: [ProcessedImage], to endpoint: String, entityType: String = "listings", entityId: String? = nil) async throws -> [String] {
        var uploadedURLs: [String] = []
        
        try await withThrowingTaskGroup(of: (Int, String).self) { group in
            for (index, processedImage) in images.enumerated() {
                group.addTask {
                    let url = try await APIClient.shared.uploadFileData(
                        processedImage.fullImageData,
                        fileName: "image_\(Date().timeIntervalSince1970)_\(index).jpg",
                        endpoint: endpoint,
                        entityType: entityType,
                        entityId: entityId
                    )
                    return (index, url)
                }
            }
            
            var results: [(Int, String)] = []
            for try await result in group {
                results.append(result)
            }
            
            // Sort by index to maintain order
            results.sort { $0.0 < $1.0 }
            uploadedURLs = results.map { $0.1 }
        }
        
        return uploadedURLs
    }
}