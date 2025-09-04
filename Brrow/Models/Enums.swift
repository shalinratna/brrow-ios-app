//
//  Enums.swift
//  Brrow
//
//  App-wide Enumerations
//

import Foundation

// MARK: - Listing Category
enum ListingCategory: String, CaseIterable {
    case all = "all"
    case electronicsGadgets = "Electronics & Gadgets"
    case homeKitchen = "Home & Kitchen Appliances"
    case toolsDIY = "Tools & DIY Equipment"
    case outdoorGarden = "Outdoor & Garden"
    case vehiclesAccessories = "Vehicles & Accessories"
    case furnitureDecor = "Furniture & Home Decor"
    case toysGamesHobbies = "Toys, Games & Hobbies"
    case sportsFitness = "Sports & Fitness Equipment"
    case campingTravel = "Camping & Travel Gear"
    case partyEvent = "Party & Event Supplies"
    case musicalInstruments = "Musical Instruments & Gear"
    case babyKids = "Baby & Kids Essentials"
    case clothingAccessories = "Clothing & Accessories"
    case businessOffice = "Business & Office Equipment"
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .electronicsGadgets: return "Electronics & Gadgets"
        case .homeKitchen: return "Home & Kitchen Appliances"
        case .toolsDIY: return "Tools & DIY Equipment"
        case .outdoorGarden: return "Outdoor & Garden"
        case .vehiclesAccessories: return "Vehicles & Accessories"
        case .furnitureDecor: return "Furniture & Home Decor"
        case .toysGamesHobbies: return "Toys, Games & Hobbies"
        case .sportsFitness: return "Sports & Fitness Equipment"
        case .campingTravel: return "Camping & Travel Gear"
        case .partyEvent: return "Party & Event Supplies"
        case .musicalInstruments: return "Musical Instruments & Gear"
        case .babyKids: return "Baby & Kids Essentials"
        case .clothingAccessories: return "Clothing & Accessories"
        case .businessOffice: return "Business & Office Equipment"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .electronicsGadgets: return "tv.and.mediabox"
        case .homeKitchen: return "refrigerator"
        case .toolsDIY: return "hammer"
        case .outdoorGarden: return "leaf"
        case .vehiclesAccessories: return "car"
        case .furnitureDecor: return "sofa"
        case .toysGamesHobbies: return "gamecontroller"
        case .sportsFitness: return "figure.strengthtraining.traditional"
        case .campingTravel: return "tent"
        case .partyEvent: return "party.popper"
        case .musicalInstruments: return "guitars"
        case .babyKids: return "figure.2.and.child.holdinghands"
        case .clothingAccessories: return "tshirt"
        case .businessOffice: return "briefcase"
        }
    }
}

// MARK: - Sort Options
enum SortOption: String, CaseIterable {
    case nearest = "nearest"
    case newest = "newest"
    case priceLowToHigh = "price_low_high"
    case priceHighToLow = "price_high_low"
    
    var displayName: String {
        switch self {
        case .nearest: return "Nearest"
        case .newest: return "Newest"
        case .priceLowToHigh: return "Price: Low to High"
        case .priceHighToLow: return "Price: High to Low"
        }
    }
}

// MARK: - Listing Type
enum ListingType: String, Codable {
    case borrow = "borrow"
    case buy = "buy"
    case free = "free"
}


// MARK: - Payment Status
enum PaymentStatus: String, Codable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    case refunded = "refunded"
}

// MARK: - User Verification Status
enum VerificationStatus: String, Codable {
    case unverified = "unverified"
    case emailVerified = "email_verified"
    case idVerified = "id_verified"
    case fullyVerified = "fully_verified"
}

// MARK: - Notification Type
enum NotificationType: String, Codable {
    case newOffer = "new_offer"
    case offerAccepted = "offer_accepted"
    case offerDeclined = "offer_declined"
    case newMessage = "new_message"
    case transactionUpdate = "transaction_update"
    case paymentReceived = "payment_received"
    case reviewReceived = "review_received"
    case listingExpiring = "listing_expiring"
    case karmaUpdate = "karma_update"
}

// MARK: - Error Types
enum BrrowError: LocalizedError {
    case networkError(String)
    case authenticationError(String)
    case validationError(String)
    case serverError(String)
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message): return "Network Error: \(message)"
        case .authenticationError(let message): return "Authentication Error: \(message)"
        case .validationError(let message): return "Validation Error: \(message)"
        case .serverError(let message): return "Server Error: \(message)"
        case .unknownError: return "An unknown error occurred"
        }
    }
}