import Foundation

extension String {
    var localizedString: String {
        // Get the selected language from LocalizationManager
        let languageCode = UserDefaults.standard.string(forKey: "AppLanguage") ?? "en"
        
        // Try to find the bundle for the selected language
        if let bundlePath = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: bundlePath) {
            // Get localized string from the specific bundle
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