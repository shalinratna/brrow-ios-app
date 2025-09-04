//
//  ContentModerator.swift
//  Brrow
//
//  Local content moderation to check for inappropriate content before submission
//

import Foundation
import UIKit

class ContentModerator {
    static let shared = ContentModerator()
    
    private init() {}
    
    // Common curse words and inappropriate language
    private let profanityList = [
        // Basic profanity
        "fuck", "shit", "damn", "hell", "ass", "bitch", "bastard", "crap",
        "piss", "dick", "cock", "pussy", "cunt", "fag", "slut", "whore",
        
        // Variations and leetspeak
        "f*ck", "sh*t", "b*tch", "a$$", "fuk", "fuq", "fvck", "sh1t",
        "b1tch", "a55", "pr0n", "n1gger", "f@ck", "sh!t", "@ss",
        
        // Racial slurs (abbreviated for sensitivity)
        "nigger", "nigga", "chink", "spic", "wetback", "kike", "gook",
        
        // NSFW terms
        "porn", "sex", "nude", "naked", "xxx", "nsfw", "18+", "adult",
        "escort", "prostitute", "hooker", "onlyfans", "camgirl",
        
        // Drug related
        "cocaine", "heroin", "meth", "weed", "marijuana", "420", "drugs",
        "mdma", "ecstasy", "lsd", "crack", "pills", "xanax", "oxycontin",
        
        // Violence related
        "kill", "murder", "suicide", "rape", "assault", "bomb", "terrorist",
        "weapon", "gun", "knife", "shoot", "stab"
    ]
    
    // Common website patterns
    private let websitePatterns = [
        // URLs
        #"https?://[^\s]+"#,
        #"www\.[^\s]+"#,
        #"[a-zA-Z0-9]+\.(com|org|net|io|co|app|xyz|site|online|store|shop)[^\s]*"#,
        
        // Social media handles
        #"@[a-zA-Z0-9_]+"#,
        #"instagram\.com"#,
        #"facebook\.com"#,
        #"twitter\.com"#,
        #"tiktok\.com"#,
        #"snapchat\.com"#,
        #"telegram\.me"#,
        #"discord\.gg"#,
        
        // Contact info patterns
        #"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b"#, // Email
        #"\b\d{3}[-.]?\d{3}[-.]?\d{4}\b"#, // Phone numbers
        #"\b\d{5,}\b"# // Long number sequences that might be phone/social security
    ]
    
    // Suspicious promotional keywords
    private let promotionalKeywords = [
        "click here", "click link", "follow me", "dm me", "message me",
        "whatsapp", "telegram", "cashapp", "venmo", "paypal", "zelle",
        "bitcoin", "crypto", "investment", "forex", "mlm", "pyramid",
        "get rich", "make money", "work from home", "limited time",
        "act now", "don't miss", "exclusive offer", "promo code"
    ]
    
    struct ModerationResult {
        let isPassed: Bool
        let issues: [ModerationIssue]
        
        var message: String {
            if isPassed {
                return "Content passed moderation"
            }
            
            let uniqueTypes = Set(issues.map { $0.type })
            var messages: [String] = []
            
            if uniqueTypes.contains(.profanity) {
                messages.append("inappropriate language")
            }
            if uniqueTypes.contains(.website) {
                messages.append("external links or contact information")
            }
            if uniqueTypes.contains(.promotional) {
                messages.append("promotional content")
            }
            if uniqueTypes.contains(.nsfw) {
                messages.append("adult content")
            }
            
            let issueText = messages.joined(separator: ", ")
            return "Your content contains \(issueText). Please remove it before posting."
        }
    }
    
    struct ModerationIssue {
        enum IssueType {
            case profanity
            case website
            case promotional
            case nsfw
        }
        
        let type: IssueType
        let text: String
        let field: String
    }
    
    // MARK: - Main Moderation Methods
    
    func moderateListingContent(title: String, description: String, category: String? = nil) -> ModerationResult {
        var issues: [ModerationIssue] = []
        
        // Check title
        let titleIssues = checkContent(title, field: "title")
        issues.append(contentsOf: titleIssues)
        
        // Check description
        let descriptionIssues = checkContent(description, field: "description")
        issues.append(contentsOf: descriptionIssues)
        
        // Additional checks for certain categories
        if let category = category?.lowercased() {
            if category == "adult" || category == "services" {
                issues.append(ModerationIssue(
                    type: .nsfw,
                    text: category,
                    field: "category"
                ))
            }
        }
        
        return ModerationResult(
            isPassed: issues.isEmpty,
            issues: issues
        )
    }
    
    func moderateGarageSaleContent(title: String, description: String, address: String) -> ModerationResult {
        var issues: [ModerationIssue] = []
        
        // Check title
        let titleIssues = checkContent(title, field: "title")
        issues.append(contentsOf: titleIssues)
        
        // Check description
        let descriptionIssues = checkContent(description, field: "description")
        issues.append(contentsOf: descriptionIssues)
        
        // Don't check address for websites/contact info as it's expected to have location data
        let addressIssues = checkForProfanity(address, field: "address")
        issues.append(contentsOf: addressIssues)
        
        return ModerationResult(
            isPassed: issues.isEmpty,
            issues: issues
        )
    }
    
    // MARK: - Private Helper Methods
    
    private func checkContent(_ text: String, field: String) -> [ModerationIssue] {
        var issues: [ModerationIssue] = []
        
        // Check for profanity
        issues.append(contentsOf: checkForProfanity(text, field: field))
        
        // Check for websites and contact info
        issues.append(contentsOf: checkForWebsites(text, field: field))
        
        // Check for promotional content
        issues.append(contentsOf: checkForPromotional(text, field: field))
        
        return issues
    }
    
    private func checkForProfanity(_ text: String, field: String) -> [ModerationIssue] {
        var issues: [ModerationIssue] = []
        let lowercasedText = text.lowercased()
        
        for word in profanityList {
            // Check for word boundaries to avoid false positives
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: word))\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: lowercasedText.utf16.count)
                if regex.firstMatch(in: lowercasedText, options: [], range: range) != nil {
                    issues.append(ModerationIssue(
                        type: word.contains("sex") || word.contains("porn") || word.contains("nude") ? .nsfw : .profanity,
                        text: word,
                        field: field
                    ))
                    break // Only report first issue found
                }
            }
        }
        
        return issues
    }
    
    private func checkForWebsites(_ text: String, field: String) -> [ModerationIssue] {
        var issues: [ModerationIssue] = []
        
        for pattern in websitePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: text.utf16.count)
                if let match = regex.firstMatch(in: text, options: [], range: range) {
                    let matchedText = (text as NSString).substring(with: match.range)
                    issues.append(ModerationIssue(
                        type: .website,
                        text: matchedText,
                        field: field
                    ))
                    break // Only report first issue found
                }
            }
        }
        
        return issues
    }
    
    private func checkForPromotional(_ text: String, field: String) -> [ModerationIssue] {
        var issues: [ModerationIssue] = []
        let lowercasedText = text.lowercased()
        
        for keyword in promotionalKeywords {
            if lowercasedText.contains(keyword) {
                issues.append(ModerationIssue(
                    type: .promotional,
                    text: keyword,
                    field: field
                ))
                break // Only report first issue found
            }
        }
        
        return issues
    }
    
    // MARK: - Image Moderation
    
    func moderateImage(_ image: UIImage) -> ModerationResult {
        // Basic image moderation checks
        // In a production app, you would use Vision framework or an API service
        // For now, we'll do basic checks
        
        // Check image dimensions (profile pictures shouldn't be tiny or huge)
        let size = image.size
        if size.width < 100 || size.height < 100 {
            return ModerationResult(
                isPassed: false,
                issues: [ModerationIssue(type: .nsfw, text: "Image too small", field: "image")]
            )
        }
        
        if size.width > 5000 || size.height > 5000 {
            return ModerationResult(
                isPassed: false,
                issues: [ModerationIssue(type: .nsfw, text: "Image too large", field: "image")]
            )
        }
        
        // For production, integrate with an image moderation API
        // For now, return as appropriate
        return ModerationResult(
            isPassed: true,
            issues: []
        )
    }
    
    // MARK: - Quick Check Methods
    
    func containsProfanity(_ text: String) -> Bool {
        return !checkForProfanity(text, field: "").isEmpty
    }
    
    func containsWebsite(_ text: String) -> Bool {
        return !checkForWebsites(text, field: "").isEmpty
    }
    
    func containsPromotional(_ text: String) -> Bool {
        return !checkForPromotional(text, field: "").isEmpty
    }
}