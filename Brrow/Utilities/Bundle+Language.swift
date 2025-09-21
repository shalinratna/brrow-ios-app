import Foundation

// Bundle extension to support dynamic language switching
extension Bundle {
    private static var languageBundleCache: [String: Bundle] = [:]

    // Override the main bundle to support language switching
    static func setLanguage(_ language: String) {
        // Validate language code format
        guard !language.isEmpty && language.count <= 10 else {
            print("❌ Invalid language code: \(language)")
            return
        }

        // Set the language in UserDefaults safely
        UserDefaults.standard.set([language], forKey: "AppleLanguages")
        UserDefaults.standard.set(language, forKey: "AppLanguage")

        // Try to synchronize, but don't fail if it doesn't work
        if UserDefaults.standard.synchronize() {
            print("✅ Language preferences saved: \(language)")
        } else {
            print("⚠️ Failed to synchronize language preferences, but continuing...")
        }

        // Pre-load the bundle for the new language to verify it exists
        if let bundlePath = Bundle.main.path(forResource: language, ofType: "lproj"),
           let bundle = Bundle(path: bundlePath) {
            languageBundleCache[language] = bundle
            print("✅ Language bundle loaded: \(language)")
        } else {
            print("⚠️ Language bundle not found for: \(language), falling back to English")
            languageBundleCache[language] = Bundle.main
        }

        // Use a safer approach than class swapping - just rely on our String extension
        // The AnyLanguageBundle class is still used but with better error handling
        object_setClass(Bundle.main, AnyLanguageBundle.self)
    }

    // Helper method to get localized string safely
    static func localizedString(for key: String, language: String) -> String? {
        // Check cache first
        if let bundle = languageBundleCache[language] {
            let localized = bundle.localizedString(forKey: key, value: nil, table: nil)
            return localized != key ? localized : nil
        }

        // Try to load bundle if not cached
        if let bundlePath = Bundle.main.path(forResource: language, ofType: "lproj"),
           let bundle = Bundle(path: bundlePath) {
            languageBundleCache[language] = bundle
            let localized = bundle.localizedString(forKey: key, value: nil, table: nil)
            return localized != key ? localized : nil
        }

        return nil
    }
}

// Custom bundle class to override localization with better error handling
private class AnyLanguageBundle: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        // Get the current language safely
        guard let languageCode = UserDefaults.standard.string(forKey: "AppLanguage") else {
            return super.localizedString(forKey: key, value: value, table: tableName)
        }

        // Try to get localized string for the current language
        if let localized = Bundle.localizedString(for: key, language: languageCode) {
            return localized
        }

        // Fallback to English if the current language doesn't have the string
        if languageCode != "en",
           let englishLocalized = Bundle.localizedString(for: key, language: "en") {
            return englishLocalized
        }

        // Final fallback to system default
        return super.localizedString(forKey: key, value: value, table: tableName)
    }
}