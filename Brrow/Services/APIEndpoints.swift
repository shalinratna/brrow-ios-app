//
//  APIEndpoints.swift
//  Brrow
//
//  Centralized API endpoints configuration
//  Updated: September 5, 2025 - Migrated to Node.js REST API
//

import Foundation

struct APIEndpoints {
    
    // MARK: - Base URLs
    static let baseURL = "https://brrow-backend-nodejs-production.up.railway.app"
    static let websocketURL = "wss://brrow-backend-nodejs-production.up.railway.app"
    
    // MARK: - Authentication
    struct Auth {
        static let login = "api/auth/login"
        static let register = "api/auth/register"
        static let appleLogin = "api/auth/apple-signin"
        static let refreshToken = "api/auth/refresh-token"
        static let validateToken = "api/auth/validate-token"
        static let logout = "api/auth/logout"
        static let checkUsername = "api/auth/check-username"  // GET /api/auth/check-username/:username
    }
    
    // MARK: - Listings
    struct Listings {
        static let create = "api/listings"  // POST
        static let getDetails = "api/listings"  // GET /api/listings/:id
        static let update = "api/listings"  // PUT /api/listings/:id
        static let delete = "api/listings"  // DELETE /api/listings/:id
        static let fetchAll = "api/listings"  // GET
        static let getUserListings = "api/listings"  // GET with user filter
        static let myListings = "api/listings/my-listings"  // GET - JWT-based user's own listings
        static let search = "api/search"  // GET
        static let featured = "api/listings/featured"  // GET
    }
    
    // MARK: - Seeks
    struct Seeks {
        static let create = "api/seeks"  // POST
        static let getDetails = "api/seeks"  // GET /api/seeks/:id
        static let update = "api/seeks"  // PUT /api/seeks/:id
        static let delete = "api/seeks"  // DELETE /api/seeks/:id
        static let fetchAll = "api/seeks"  // GET
    }
    
    // MARK: - Garage Sales
    struct GarageSales {
        static let create = "api/garage-sales"  // POST
        static let getDetails = "api/garage-sales"  // GET /api/garage-sales/:id
        static let update = "api/garage-sales"  // PUT /api/garage-sales/:id
        static let delete = "api/garage-sales"  // DELETE /api/garage-sales/:id
        static let fetchAll = "api/garage-sales"  // GET
    }
    
    // MARK: - User Profile
    struct Profile {
        static let get = "api/users/me"  // GET
        static let update = "api/users/me"  // PUT
        static let updateImage = "api/users/me/profile-image"  // PUT
        static let updateFCMToken = "api/users/me/fcm-token"  // PUT
        static let updateLanguage = "api/users/me/language"  // PUT
    }
    
    // MARK: - Messaging
    struct Messages {
        static let send = "api/messages"  // POST
        static let fetchConversations = "api/conversations"  // GET
        static let fetchMessages = "api/conversations"  // GET /api/conversations/:id/messages
    }
    
    // MARK: - Favorites
    struct Favorites {
        static let toggle = "api/favorites"  // POST/DELETE
        static let getFavorites = "api/favorites"  // GET
        static let check = "api/favorites"  // GET with query params
    }
    
    // MARK: - Notifications
    struct Notifications {
        static let updateFCMToken = "api/users/me/fcm-token"  // PUT
        static let send = "api/notifications"  // POST
        static let get = "api/notifications"  // GET
    }
    
    // MARK: - Moderation
    struct Moderation {
        static let moderate = "api/listings/moderate"  // POST
    }
    
    // MARK: - Upload
    struct Upload {
        static let file = "api/upload"  // POST - handles both images and videos
    }
    
    // MARK: - Categories
    struct Categories {
        static let getAll = "api/categories"  // GET
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