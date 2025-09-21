import Foundation

extension String {
    var localizedString: String {
        // Get the selected language safely
        let languageCode = UserDefaults.standard.string(forKey: "AppLanguage") ?? "en"

        // Try Bundle's new safe method first
        if let localized = Bundle.localizedString(for: self, language: languageCode) {
            return localized
        }

        // Fallback to English if current language doesn't have the string
        if languageCode != "en",
           let englishLocalized = Bundle.localizedString(for: self, language: "en") {
            return englishLocalized
        }

        // Try the traditional approach as final fallback
        if let bundlePath = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: bundlePath) {
            let localized = NSLocalizedString(self, bundle: bundle, comment: "")
            if localized != self {
                return localized
            }
        }

        // If no localization found, convert snake_case to readable format
        return self
            .replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .map { word in
                // Handle common abbreviations
                let wordStr = String(word)
                if wordStr.uppercased() == wordStr && wordStr.count <= 3 {
                    return wordStr
                }
                // Capitalize first letter of each word
                return word.prefix(1).uppercased() + word.dropFirst().lowercased()
            }
            .joined(separator: " ")
    }
    
    func localizedWithArgs(_ arguments: CVarArg...) -> String {
        let format = self.localizedString
        return String(format: format, arguments: arguments)
    }
}