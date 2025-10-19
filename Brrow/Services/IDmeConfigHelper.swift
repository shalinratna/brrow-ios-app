//
//  IDmeConfigHelper.swift
//  Brrow
//
//  Helper for ID.me configuration setup
//

import Foundation

struct IDmeConfigHelper {
    
    // MARK: - Setup Instructions
    static let setupInstructions = """
    ID.me Setup Instructions:
    
    1. Go to https://developers.id.me/
    2. Create developer account with your business email
    3. Create organization: "Brrow"
    4. Create application: "Brrow Mobile App"
    5. Set redirect URI: "brrowapp://idme/callback"
    6. Select scope: "Basic Identity Verification"
    7. Copy Client ID and Client Secret to IDmeService.swift
    """
    
    // MARK: - Configuration Validation
    static func validateConfiguration() -> (isValid: Bool, issues: [String]) {
        var issues: [String] = []
        
        // Check Client ID
        if IDmeConfig.clientID == "YOUR_IDME_CLIENT_ID" || IDmeConfig.clientID.isEmpty {
            issues.append("Client ID not configured")
        }
        
        // Check Client Secret
        if IDmeConfig.clientSecret == "YOUR_IDME_CLIENT_SECRET" || IDmeConfig.clientSecret.isEmpty {
            issues.append("Client Secret not configured")
        }
        
        // Check Redirect URI format
        if !IDmeConfig.redirectURI.hasPrefix("brrowapp://") {
            issues.append("Invalid redirect URI format")
        }
        
        return (issues.isEmpty, issues)
    }
    
    // MARK: - Development Helper
    static func printConfiguration() {
        print("🔧 ID.me Configuration Status:")
        print("Client ID: \(IDmeConfig.clientID == "YOUR_IDME_CLIENT_ID" ? "❌ Not Set" : "✅ Configured")")
        print("Client Secret: \(IDmeConfig.clientSecret == "YOUR_IDME_CLIENT_SECRET" ? "❌ Not Set" : "✅ Configured")")
        print("Redirect URI: \(IDmeConfig.redirectURI)")
        print("Default Scopes: \(IDmeConfig.defaultScopes)")

        let validation = validateConfiguration()
        if validation.isValid {
            print("✅ Configuration is valid!")
        } else {
            print("❌ Configuration issues:")
            validation.issues.forEach { print("  - \($0)") }
        }
    }
    
    // MARK: - Environment Detection
    static var isProduction: Bool {
        #if DEBUG
        return false
        #else
        return true
        #endif
    }
    
    static var environmentName: String {
        return isProduction ? "Production" : "Development"
    }
}

// MARK: - Configuration Update Helper
extension IDmeConfigHelper {
    
    /// Call this method after updating credentials to verify setup
    static func verifySetup() {
        print("\n🔍 Verifying ID.me Setup...")
        printConfiguration()
        
        let validation = validateConfiguration()
        if validation.isValid {
            print("\n✅ Ready to test ID.me verification!")
            print("Next steps:")
            print("1. Build and run the app")
            print("2. Go to Profile → Identity Verification")
            print("3. Tap 'Start Verification'")
            print("4. Complete ID.me flow in Safari")
        } else {
            print("\n❌ Setup incomplete. Please:")
            validation.issues.forEach { print("• \($0)") }
        }
    }
}

// MARK: - Debug Helper for Development
#if DEBUG
extension IDmeConfigHelper {
    
    static func enableDebugLogging() {
        print("🐛 ID.me Debug Mode Enabled")
        print("Environment: \(environmentName)")
        print("Base URL: \(IDmeConfig.baseURL)")
        print("Auth URL: \(IDmeConfig.authURL)")
        print("Token URL: \(IDmeConfig.tokenURL)")
        print("User Info URL: \(IDmeConfig.userInfoURL)")
    }
}
#endif