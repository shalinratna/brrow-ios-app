import Foundation
import SwiftUI

/// Professional Localization Manager for Brrow App
/// Supports dynamic language switching and persistence
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: Language = .english {
        didSet {
            UserDefaults.standard.set(currentLanguage.code, forKey: "AppLanguage")
            Bundle.setLanguage(currentLanguage.code)
            updateUserLanguagePreference()
        }
    }
    
    var currentLanguageName: String {
        currentLanguage.displayName
    }
    
    var availableLanguages: [String] {
        Language.allCases.map { $0.code }
    }
    
    // Supported languages with native names
    enum Language: String, CaseIterable {
        case english = "en"
        case spanish = "es"
        case vietnamese = "vi"
        case punjabi = "pa"
        case urdu = "ur"
        case french = "fr"
        case german = "de"
        case chinese = "zh-Hans"
        case japanese = "ja"
        case korean = "ko"
        case russian = "ru"
        case arabic = "ar"
        case hindi = "hi"
        case portuguese = "pt"
        case italian = "it"
        
        var displayName: String {
            switch self {
            case .english: return "English"
            case .spanish: return "Español"
            case .vietnamese: return "Tiếng Việt"
            case .punjabi: return "ਪੰਜਾਬੀ"
            case .urdu: return "اردو"
            case .french: return "Français"
            case .german: return "Deutsch"
            case .chinese: return "中文"
            case .japanese: return "日本語"
            case .korean: return "한국어"
            case .russian: return "Русский"
            case .arabic: return "العربية"
            case .hindi: return "हिन्दी"
            case .portuguese: return "Português"
            case .italian: return "Italiano"
            }
        }
        
        var flag: String {
            switch self {
            case .english: return "🇺🇸"
            case .spanish: return "🇪🇸"
            case .vietnamese: return "🇻🇳"
            case .punjabi: return "🇮🇳"
            case .urdu: return "🇵🇰"
            case .french: return "🇫🇷"
            case .german: return "🇩🇪"
            case .chinese: return "🇨🇳"
            case .japanese: return "🇯🇵"
            case .korean: return "🇰🇷"
            case .russian: return "🇷🇺"
            case .arabic: return "🇸🇦"
            case .hindi: return "🇮🇳"
            case .portuguese: return "🇵🇹"
            case .italian: return "🇮🇹"
            }
        }
        
        var code: String {
            return self.rawValue
        }
        
        var isRTL: Bool {
            switch self {
            case .arabic, .urdu:
                return true
            default:
                return false
            }
        }
        
        static func from(code: String) -> Language {
            return Language(rawValue: code) ?? .english
        }
    }
    
    private init() {
        // Load saved language preference
        if let savedLanguage = UserDefaults.standard.string(forKey: "AppLanguage"),
           let language = Language(rawValue: savedLanguage) {
            self.currentLanguage = language
            Bundle.setLanguage(language.code)
        } else {
            // Use device language if supported, otherwise default to English
            let deviceLanguage = Locale.current.languageCode ?? "en"
            if let matchedLanguage = Language.allCases.first(where: { $0.code.hasPrefix(deviceLanguage) }) {
                self.currentLanguage = matchedLanguage
            } else {
                self.currentLanguage = .english
            }
            Bundle.setLanguage(currentLanguage.code)
        }
    }
    
    /// Change the app language
    func setLanguage(_ language: Language) {
        currentLanguage = language
        UserDefaults.standard.set(language.code, forKey: "AppLanguage")
        UserDefaults.standard.set([language.code], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        Bundle.setLanguage(language.code)
        
        // Update layout direction for RTL languages
        if language.isRTL {
            UIView.appearance().semanticContentAttribute = .forceRightToLeft
        } else {
            UIView.appearance().semanticContentAttribute = .forceLeftToRight
        }
        
        // Post notification for UI refresh
        NotificationCenter.postLanguageChangeNotification()
        
        // Update user preference on server if logged in
        updateUserLanguagePreference()
    }
    
    func setLanguage(_ languageCode: String) {
        if let language = Language(rawValue: languageCode) {
            setLanguage(language)
        }
    }
    
    func languageName(for code: String) -> String {
        return Language(rawValue: code)?.displayName ?? code
    }
    
    /// Get localized string
    static func localizedString(_ key: String, comment: String = "") -> String {
        let languageCode = UserDefaults.standard.string(forKey: "AppLanguage") ?? "en"
        
        // Try to find the bundle for the selected language
        if let bundlePath = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: bundlePath) {
            return NSLocalizedString(key, bundle: bundle, comment: comment)
        }
        
        // Fallback to main bundle
        return NSLocalizedString(key, comment: comment)
    }
    
    /// Get localized string with parameters
    static func localizedString(_ key: String, _ arguments: CVarArg...) -> String {
        let format = localizedString(key)
        return String(format: format, arguments: arguments)
    }
    
    /// Update user's language preference on the server
    private func updateUserLanguagePreference() {
        guard let user = AuthManager.shared.currentUser else { return }
        
        // Update on server
        Task {
            do {
                _ = try await APIClient.shared.updateLanguagePreference(languageCode: currentLanguage.code)
                print("✅ Language preference updated on server: \(currentLanguage.code)")
            } catch {
                print("❌ Failed to update language preference on server: \(error)")
                // Still save locally even if server update fails
            }
        }
        
        // Save locally
        UserDefaults.standard.set(currentLanguage.code, forKey: "AppLanguage")
    }
}

// Bundle extension moved to Bundle+Language.swift to avoid conflicts

// MARK: - SwiftUI View Extension
extension View {
    /// Apply RTL layout if needed
    func applyRTLIfNeeded() -> some View {
        self.environment(\.layoutDirection, 
                         LocalizationManager.shared.currentLanguage.isRTL ? .rightToLeft : .leftToRight)
    }
}

// MARK: - Convenience String Extension
// Moved to StringExtensions.swift to avoid conflicts