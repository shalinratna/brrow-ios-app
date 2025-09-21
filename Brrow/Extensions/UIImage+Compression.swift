//
//  UIImage+Compression.swift
//  Brrow
//
//  Image compression and optimization utilities
//

import UIKit

extension UIImage {
    /// Compress and resize image for optimal upload
    /// - Parameters:
    ///   - maxDimension: Maximum width or height (default 1200)
    ///   - compressionQuality: JPEG compression quality (default 0.8)
    /// - Returns: Compressed image data
    func optimizedForUpload(maxDimension: CGFloat = 1200, compressionQuality: CGFloat = 0.8) -> Data? {
        // First resize the image if needed
        let resized = self.resizedWithAspectRatio(maxDimension: maxDimension)
        
        // Then compress
        return resized.jpegData(compressionQuality: compressionQuality)
    }
    
    /// Resize image maintaining aspect ratio
    /// - Parameter maxDimension: Maximum width or height
    /// - Returns: Resized image
    func resizedWithAspectRatio(maxDimension: CGFloat) -> UIImage {
        let size = self.size

        // Guard against zero or invalid dimensions to prevent NaN
        guard size.width > 0 && size.height > 0 && maxDimension > 0 else {
            return self
        }

        // If image is already small enough, return original
        if size.width <= maxDimension && size.height <= maxDimension {
            return self
        }

        let widthRatio = maxDimension / size.width
        let heightRatio = maxDimension / size.height
        let ratio = min(widthRatio, heightRatio)
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? self
    }
    
    /// Get file size of image data
    var fileSize: Int? {
        guard let data = self.jpegData(compressionQuality: 1.0) else { return nil }
        return data.count
    }
    
    /// Get human-readable file size
    var readableFileSize: String? {
        guard let bytes = fileSize else { return nil }
        
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}