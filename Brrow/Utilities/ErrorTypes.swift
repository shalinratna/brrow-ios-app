//
//  ErrorTypes.swift
//  Brrow
//
//  Created by Shalin Ratna on 7/16/25.
//

import Foundation

// MARK: - Validation Error
enum ValidationError: Error, LocalizedError {
    case emptyField(String)
    case invalidFormat(String)
    case tooShort(String, Int)
    case tooLong(String, Int)
    case invalidEmail
    case invalidPassword
    case passwordMismatch
    case invalidAge
    case invalidPrice
    case invalidDuration
    
    var errorDescription: String? {
        switch self {
        case .emptyField(let field):
            return "\(field) cannot be empty"
        case .invalidFormat(let field):
            return "\(field) has invalid format"
        case .tooShort(let field, let min):
            return "\(field) must be at least \(min) characters"
        case .tooLong(let field, let max):
            return "\(field) must be less than \(max) characters"
        case .invalidEmail:
            return "Invalid email format"
        case .invalidPassword:
            return "Password must be at least 8 characters with numbers and letters"
        case .passwordMismatch:
            return "Passwords do not match"
        case .invalidAge:
            return "You must be at least 13 years old to use Brrow"
        case .invalidPrice:
            return "Price must be greater than 0"
        case .invalidDuration:
            return "Duration must be between 1 and 30 days"
        }
    }
}

// MARK: - Storage Error
enum StorageError: Error, LocalizedError {
    case saveFailed
    case loadFailed
    case deleteFailed
    case corruptedData
    case insufficientStorage
    
    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "Failed to save data"
        case .loadFailed:
            return "Failed to load data"
        case .deleteFailed:
            return "Failed to delete data"
        case .corruptedData:
            return "Data is corrupted"
        case .insufficientStorage:
            return "Insufficient storage space"
        }
    }
}

// MARK: - Payment Error
// PaymentError is defined in PaymentService.swift to avoid duplication

// MARK: - Location Error
enum LocationError: Error, LocalizedError {
    case permissionDenied
    case locationUnavailable
    case locationTimeout
    case invalidLocation
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location permission denied"
        case .locationUnavailable:
            return "Location unavailable"
        case .locationTimeout:
            return "Location request timeout"
        case .invalidLocation:
            return "Invalid location"
        }
    }
}

// MARK: - File Error
enum FileError: Error, LocalizedError {
    case invalidFile
    case fileTooLarge
    case unsupportedFormat
    case uploadFailed
    case downloadFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidFile:
            return "Invalid file"
        case .fileTooLarge:
            return "File is too large"
        case .unsupportedFormat:
            return "Unsupported file format"
        case .uploadFailed:
            return "File upload failed"
        case .downloadFailed:
            return "File download failed"
        }
    }
}

// MARK: - File Upload Error
enum FileUploadError: Error, LocalizedError {
    case invalidURL
    case networkError
    case invalidResponse
    case serverError(String)
    case fileTooLarge
    case unsupportedFormat
    case uploadFailed
    case compressionFailed
    case multipleFailures(message: String, failedAttempts: Int, successfulUploads: Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid upload URL"
        case .networkError:
            return "Network error during upload"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let message):
            return "Server error: \(message)"
        case .fileTooLarge:
            return "File is too large to upload"
        case .unsupportedFormat:
            return "Unsupported file format"
        case .uploadFailed:
            return "File upload failed"
        case .compressionFailed:
            return "Failed to compress file"
        case .multipleFailures(let message, _, _):
            return message
        }
    }
}
