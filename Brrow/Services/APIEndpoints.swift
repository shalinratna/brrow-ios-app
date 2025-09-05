//
//  APIEndpoints.swift
//  Brrow
//
//  Centralized API endpoints configuration
//  Updated: August 28, 2025
//

import Foundation

struct APIEndpoints {
    
    // MARK: - Base URLs
    static let baseURL = "https://brrow-backend-nodejs-production.up.railway.app"
    static let websocketURL = "wss://brrow-backend-nodejs-production.up.railway.app"
    
    // MARK: - Authentication
    struct Auth {
        static let login = "api_login.php"
        static let register = "api_register.php"
        static let appleLogin = "api_apple_login.php"
        static let refreshToken = "refresh_token.php"
        static let validateToken = "validate_token.php"
        static let logout = "logout.php"
    }
    
    // MARK: - Listings
    struct Listings {
        // Use moderated version for new listings
        static let create = "ios_create_listing_moderated.php"
        static let getDetails = "get_listing_details.php"
        static let update = "api_update_listing_simple.php"
        static let delete = "api_delete_listing_simple.php"
        static let fetchAll = "api_fetch_listings_zero_errors.php"  // Guaranteed zero decoding errors
        static let getUserListings = "api_user_listings_zero_errors.php"  // Guaranteed zero decoding errors
        static let search = "search_listings.php"
        static let featured = "api_fetch_featured.php"  // Working featured endpoint
    }
    
    // MARK: - Seeks
    struct Seeks {
        static let create = "api_create_seek_with_images.php"
        static let getDetails = "api_get_seek_details.php"
        static let update = "api_update_seek.php"
        static let delete = "api_delete_seek.php"
        static let fetchAll = "api_fetch_seeks.php"
    }
    
    // MARK: - Garage Sales
    struct GarageSales {
        static let create = "api_create_garage_sale_with_images.php"
        static let getDetails = "api_get_garage_sale_details.php"
        static let update = "api_update_garage_sale.php"
        static let delete = "api_delete_garage_sale.php"
        static let fetchAll = "api_garage_sales_fetch.php"  // Working garage sales endpoint
    }
    
    // MARK: - User Profile
    struct Profile {
        static let get = "api_get_user_profile.php"
        static let update = "api_update_profile.php"
        static let updateImage = "api_update_profile_image.php"
        static let updateFCMToken = "api_update_fcm_token.php"
        static let updateLanguage = "api_update_user_language.php"  // Working endpoint
    }
    
    // MARK: - Messaging
    struct Messages {
        static let send = "api_send_message_with_notification.php"  // Includes push notification
        static let fetchConversations = "api_fetch_conversations.php"
        static let fetchMessages = "fetch_messages.php"
    }
    
    // MARK: - Favorites
    struct Favorites {
        static let toggle = "api_toggle_favorite.php"
        static let getFavorites = "api_get_favorites.php"
        static let check = "check_favorite.php"
    }
    
    // MARK: - Notifications
    struct Notifications {
        static let updateFCMToken = "api_update_fcm_token.php"
        static let send = "api_send_notification.php"
        static let test = "test_push_notification.php"
    }
    
    // MARK: - Moderation
    struct Moderation {
        static let moderate = "api_moderate_listing.php"
        static let approveAjax = "admin/approve_listing_ajax.php"
    }
    
    // MARK: - Upload
    struct Upload {
        static let image = "api_upload_v2.php"
    }
    
    // MARK: - Categories
    struct Categories {
        static let getAll = "get_categories.php"
    }
    
    // MARK: - Helper Methods
    static func fullURL(for endpoint: String) -> String {
        return "\(baseURL)/\(endpoint)"
    }
    
    static func url(for endpoint: String) -> URL? {
        return URL(string: fullURL(for: endpoint))
    }
}

// MARK: - Usage Example
/*
 let createListingURL = APIEndpoints.url(for: APIEndpoints.Listings.create)
 let loginURL = APIEndpoints.fullURL(for: APIEndpoints.Auth.login)
 */