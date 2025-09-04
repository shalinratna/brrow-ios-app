//
//  LocalizationHelper.swift
//  Brrow
//
//  Created by Shalin Ratna on 7/18/25.
//

import Foundation

// MARK: - Localization Helper
class LocalizationHelper {
    
    // MARK: - String Localization
    static func localizedString(_ key: String, comment: String = "") -> String {
        return NSLocalizedString(key, comment: comment)
    }
    
    // MARK: - String with Parameters
    static func localizedString(_ key: String, arguments: CVarArg...) -> String {
        let format = NSLocalizedString(key, comment: "")
        return String(format: format, arguments: arguments)
    }
    
    // MARK: - Current Language
    static var currentLanguage: String {
        return Locale.current.languageCode ?? "en"
    }
    
    // MARK: - Supported Languages
    static var supportedLanguages: [String] {
        return ["en", "es"]
    }
    
    // MARK: - Language Names
    static var languageNames: [String: String] {
        return [
            "en": "English",
            "es": "Español"
        ]
    }
    
    // MARK: - Format Currency
    static func formatCurrency(_ amount: Double, currencyCode: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
    
    // MARK: - Format Date
    static func formatDate(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }
    
    // MARK: - Format Relative Date
    static func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale.current
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    // MARK: - Format Distance
    static func formatDistance(_ distance: Double) -> String {
        let formatter = MeasurementFormatter()
        formatter.locale = Locale.current
        formatter.unitStyle = .short
        
        let measurement = Measurement(value: distance, unit: UnitLength.meters)
        return formatter.string(from: measurement)
    }
    
    // MARK: - Format Number
    static func formatNumber(_ number: Double, style: NumberFormatter.Style = .decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = style
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    // MARK: - Pluralization
    static func pluralizedString(_ key: String, count: Int) -> String {
        let format = NSLocalizedString(key, comment: "")
        return String.localizedStringWithFormat(format, count)
    }
}

// MARK: - String Extension
extension String {
    var localized: String {
        return LocalizationHelper.localizedString(self)
    }
    
    func localized(with arguments: CVarArg...) -> String {
        return LocalizationHelper.localizedString(self, arguments: arguments)
    }
}

// MARK: - Localization Keys
struct LocalizationKeys {
    
    // MARK: - General
    struct General {
        static let appName = "app_name"
        static let welcome = "welcome"
        static let continueAction = "continue"
        static let cancel = "cancel"
        static let done = "done"
        static let save = "save"
        static let delete = "delete"
        static let edit = "edit"
        static let loading = "loading"
        static let error = "error"
        static let success = "success"
        static let tryAgain = "try_again"
        static let ok = "ok"
    }
    
    // MARK: - Authentication
    struct Auth {
        static let login = "login"
        static let signup = "signup"
        static let email = "email"
        static let password = "password"
        static let username = "username"
        static let forgotPassword = "forgot_password"
        static let createAccount = "create_account"
        static let alreadyHaveAccount = "already_have_account"
        static let dontHaveAccount = "dont_have_account"
        static let logout = "logout"
        static let loginError = "login_error"
        static let signupSuccess = "signup_success"
    }
    
    // MARK: - Navigation
    struct Navigation {
        static let home = "home"
        static let browse = "browse"
        static let garageSales = "garage_sales"
        static let seeks = "seeks"
        static let offers = "offers"
        static let messages = "messages"
        static let profile = "profile"
    }
    
    // MARK: - Listings
    struct Listings {
        static let listings = "listings"
        static let createListing = "create_listing"
        static let listingTitle = "listing_title"
        static let listingDescription = "listing_description"
        static let listingPrice = "listing_price"
        static let listingCategory = "listing_category"
        static let listingLocation = "listing_location"
        static let listingImages = "listing_images"
        static let addImages = "add_images"
        static let listingCreated = "listing_created"
        static let listingUpdated = "listing_updated"
        static let listingDeleted = "listing_deleted"
    }
    
    // MARK: - Offers
    struct Offers {
        static let makeOffer = "make_offer"
        static let offerAmount = "offer_amount"
        static let offerMessage = "offer_message"
        static let offerDuration = "offer_duration"
        static let sendOffer = "send_offer"
        static let acceptOffer = "accept_offer"
        static let rejectOffer = "reject_offer"
        static let offerSent = "offer_sent"
        static let offerAccepted = "offer_accepted"
        static let offerRejected = "offer_rejected"
    }
    
    // MARK: - Messages
    struct Messages {
        static let newMessage = "new_message"
        static let typeMessage = "type_message"
        static let sendMessage = "send_message"
        static let noMessages = "no_messages"
        static let conversationWith = "conversation_with"
    }
    
    // MARK: - Profile
    struct Profile {
        static let editProfile = "edit_profile"
        static let profilePicture = "profile_picture"
        static let changePhoto = "change_photo"
        static let bio = "bio"
        static let rating = "rating"
        static let reviews = "reviews"
        static let memberSince = "member_since"
        static let verified = "verified"
    }
    
    // MARK: - Errors
    struct Errors {
        static let networkError = "network_error"
        static let serverError = "server_error"
        static let validationError = "validation_error"
        static let unauthorizedError = "unauthorized_error"
        static let notFoundError = "not_found_error"
        static let unknownError = "unknown_error"
    }
    
    // MARK: - Empty States
    struct EmptyStates {
        static let noListingsFound = "no_listings_found"
        static let noOffersYet = "no_offers_yet"
        static let noTransactionsYet = "no_transactions_yet"
        static let noGarageSalesFound = "no_garage_sales_found"
        static let noSeeksFound = "no_seeks_found"
        static let startBrowsing = "start_browsing"
    }
}