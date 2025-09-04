import Foundation

// Bundle extension to support dynamic language switching
extension Bundle {
    private static var bundleKey: UInt8 = 0
    
    // Override the main bundle to support language switching
    static func setLanguage(_ language: String) {
        defer {
            // Force UI to refresh
            object_setClass(Bundle.main, AnyLanguageBundle.self)
        }
        
        // Set the language in UserDefaults
        UserDefaults.standard.set([language], forKey: "AppleLanguages")
        UserDefaults.standard.set(language, forKey: "AppLanguage")
        UserDefaults.standard.synchronize()
    }
}

// Custom bundle class to override localization
private class AnyLanguageBundle: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        if let languageCode = UserDefaults.standard.string(forKey: "AppLanguage"),
           let bundlePath = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: bundlePath) {
            return bundle.localizedString(forKey: key, value: value, table: tableName)
        }
        return super.localizedString(forKey: key, value: value, table: tableName)
    }
}