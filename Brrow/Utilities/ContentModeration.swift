//
//  ContentModeration.swift
//  Brrow
//
//  Client-side NSFW and inappropriate content detection
//

import Foundation
import UIKit

class ContentModeration {
    static let shared = ContentModeration()
    
    // Comprehensive list of inappropriate words and phrases
    private let profanityList = [
        // Adult content
        "nsfw", "18+", "xxx", "porn", "adult", "nude", "sex",
        
        // Illegal items
        "drugs", "cocaine", "heroin", "meth", "weed", "marijuana",
        "weapon", "gun", "pistol", "rifle", "explosive", "bomb",
        "stolen", "counterfeit", "fake id", "illegal",
        
        // Hate speech
        "hate", "racist", "nazi",
        
        // Violence
        "kill", "murder", "assault", "violence",
        
        // Scams
        "pyramid", "mlm", "get rich quick", "bitcoin doubler"
    ]
    
    private let illegalCategories = [
        "weapons", "drugs", "counterfeit", "stolen goods", "fake documents"
    ]
    
    // Check if content is appropriate
    func isContentAppropriate(_ title: String, _ description: String) -> ContentCheckResult {
        let combinedText = "\(title) \(description)".lowercased()
        
        // Check for profanity
        for word in profanityList {
            if combinedText.contains(word) {
                return ContentCheckResult(
                    isAppropriate: false,
                    reason: "Content contains prohibited language: '\(word)'",
                    category: .profanity
                )
            }
        }
        
        // Check for suspicious patterns
        if containsSuspiciousPatterns(combinedText) {
            return ContentCheckResult(
                isAppropriate: false,
                reason: "Content appears to violate community guidelines",
                category: .suspicious
            )
        }
        
        // Check for all caps (spam indicator)
        if isAllCaps(title) && title.count > 5 {
            return ContentCheckResult(
                isAppropriate: false,
                reason: "Please avoid using all capital letters",
                category: .spam
            )
        }
        
        // Check for excessive special characters (spam)
        if hasExcessiveSpecialCharacters(combinedText) {
            return ContentCheckResult(
                isAppropriate: false,
                reason: "Content contains excessive special characters",
                category: .spam
            )
        }
        
        return ContentCheckResult(
            isAppropriate: true,
            reason: nil,
            category: nil
        )
    }
    
    // Check for suspicious patterns
    private func containsSuspiciousPatterns(_ text: String) -> Bool {
        let suspiciousPatterns = [
            "quick money", "easy money", "work from home",
            "click here", "limited time", "act now",
            "100% guaranteed", "risk free", "no experience",
            "double your", "triple your"
        ]
        
        for pattern in suspiciousPatterns {
            if text.contains(pattern) {
                return true
            }
        }
        
        // Check for phone numbers in title (often spam)
        let phoneRegex = try? NSRegularExpression(
            pattern: "\\b\\d{3}[-.]?\\d{3}[-.]?\\d{4}\\b",
            options: []
        )
        if let matches = phoneRegex?.matches(in: text, options: [], range: NSRange(location: 0, length: text.count)) {
            if matches.count > 0 {
                return true
            }
        }
        
        return false
    }
    
    private func isAllCaps(_ text: String) -> Bool {
        let letters = text.filter { $0.isLetter }
        let uppercase = letters.filter { $0.isUppercase }
        return letters.count > 0 && uppercase.count == letters.count
    }
    
    private func hasExcessiveSpecialCharacters(_ text: String) -> Bool {
        let specialChars = text.filter { !$0.isLetterOrNumber && !$0.isWhitespace }
        let ratio = Double(specialChars.count) / Double(max(text.count, 1))
        return ratio > 0.3 // More than 30% special characters
    }
    
    // Validate images (placeholder for future ML-based detection)
    func validateImages(_ images: [UIImage]) -> ContentCheckResult {
        // In production, this would use Vision framework or server-side ML
        // For now, just check image count
        if images.isEmpty {
            return ContentCheckResult(
                isAppropriate: false,
                reason: "At least one image is required",
                category: .missing
            )
        }
        
        if images.count > 10 {
            return ContentCheckResult(
                isAppropriate: false,
                reason: "Maximum 10 images allowed",
                category: .excess
            )
        }
        
        return ContentCheckResult(
            isAppropriate: true,
            reason: nil,
            category: nil
        )
    }
    
    // Clean text by removing mild profanity
    func cleanText(_ text: String) -> String {
        var cleaned = text
        let mildProfanity = ["damn", "hell", "crap"]
        
        for word in mildProfanity {
            cleaned = cleaned.replacingOccurrences(
                of: word,
                with: String(repeating: "*", count: word.count),
                options: .caseInsensitive
            )
        }
        
        return cleaned
    }
}

// Result structure for content checks
struct ContentCheckResult {
    let isAppropriate: Bool
    let reason: String?
    let category: ViolationCategory?
    
    enum ViolationCategory {
        case profanity
        case illegal
        case spam
        case suspicious
        case missing
        case excess
    }
}

// Extension for String helpers
extension Character {
    var isLetterOrNumber: Bool {
        return self.isLetter || self.isNumber
    }
}