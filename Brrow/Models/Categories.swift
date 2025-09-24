import SwiftUI

// MARK: - Comprehensive Categories
enum BrrowCategory: String, CaseIterable {
    case electronics = "Electronics & Gadgets"
    case homeKitchen = "Home & Kitchen Appliances"
    case tools = "Tools & DIY Equipment"
    case outdoor = "Outdoor & Garden"
    case vehicles = "Vehicles & Accessories"
    case furniture = "Furniture & Home Decor"
    case toys = "Toys, Games & Hobbies"
    case sports = "Sports & Fitness Equipment"
    case camping = "Camping & Travel Gear"
    case party = "Party & Event Supplies"
    case music = "Musical Instruments & Gear"
    case baby = "Baby & Kids Essentials"
    case clothing = "Clothing & Accessories"
    case business = "Business & Office Equipment"
    case books = "Books & Media"
    case homeGarden = "Home & Garden"
    
    var displayName: String {
        return self.rawValue
    }
    
    var icon: String {
        switch self {
        case .electronics: return "tv"
        case .homeKitchen: return "fork.knife"
        case .tools: return "hammer"
        case .outdoor: return "leaf"
        case .vehicles: return "car"
        case .furniture: return "sofa"
        case .toys: return "teddybear"
        case .sports: return "sportscourt"
        case .camping: return "tent"
        case .party: return "party.popper"
        case .music: return "guitars"
        case .baby: return "figure.and.child.holdinghands"
        case .clothing: return "tshirt"
        case .business: return "briefcase"
        case .books: return "book"
        case .homeGarden: return "house"
        }
    }
    
    var color: Color {
        switch self {
        case .electronics: return Theme.Colors.accentBlue
        case .homeKitchen: return Theme.Colors.primary
        case .tools: return Theme.Colors.accentOrange
        case .outdoor: return .green
        case .vehicles: return .black
        case .furniture: return .brown
        case .toys: return .yellow
        case .sports: return .blue
        case .camping: return .mint
        case .party: return .red
        case .music: return .purple
        case .baby: return .pink
        case .clothing: return .indigo
        case .business: return .gray
        case .books: return .orange
        case .homeGarden: return .green
        }
    }
    
    // Group categories for better organization
    static var grouped: [String: [BrrowCategory]] {
        return [
            "Home & Living": [.homeKitchen, .furniture, .outdoor],
            "Equipment & Tools": [.tools, .electronics, .business],
            "Recreation & Hobbies": [.sports, .camping, .toys, .music],
            "Events & Social": [.party],
            "Transportation": [.vehicles],
            "Family & Personal": [.baby, .clothing]
        ]
    }
    
    // Popular categories for quick access
    static var popular: [BrrowCategory] {
        return [.electronics, .tools, .furniture, .sports, .party, .camping]
    }
    
    // For database compatibility - returns snake_case version
    var databaseValue: String {
        switch self {
        case .electronics: return "electronics"
        case .homeKitchen: return "home_kitchen"
        case .tools: return "tools"
        case .outdoor: return "outdoor"
        case .vehicles: return "vehicles"
        case .furniture: return "furniture"
        case .toys: return "toys"
        case .sports: return "sports"
        case .camping: return "camping"
        case .party: return "party"
        case .music: return "music"
        case .baby: return "baby"
        case .clothing: return "clothing"
        case .business: return "business"
        case .books: return "books"
        case .homeGarden: return "home_garden"
        }
    }
    
    // Initialize from database value
    init?(databaseValue: String) {
        switch databaseValue {
        case "electronics": self = .electronics
        case "home_kitchen": self = .homeKitchen
        case "tools": self = .tools
        case "outdoor": self = .outdoor
        case "vehicles": self = .vehicles
        case "furniture": self = .furniture
        case "toys": self = .toys
        case "sports": self = .sports
        case "camping": self = .camping
        case "party": self = .party
        case "music": self = .music
        case "baby": self = .baby
        case "clothing": self = .clothing
        case "business": self = .business
        case "books": self = .books
        case "home_garden": self = .homeGarden
        default: return nil
        }
    }
}

// MARK: - Category Helper
struct CategoryHelper {
    static func getAllCategories() -> [String] {
        return BrrowCategory.allCases.map { $0.displayName }
    }
    
    static func getPopularCategories() -> [String] {
        return BrrowCategory.popular.map { $0.displayName }
    }
    
    static func getCategoryIcon(for category: String) -> String {
        return BrrowCategory.allCases.first { $0.displayName == category }?.icon ?? "ellipsis.circle"
    }
    
    static func getCategoryColor(for category: String) -> Color {
        return BrrowCategory.allCases.first { $0.displayName == category }?.color ?? .gray
    }
    
    static func searchCategories(query: String) -> [BrrowCategory] {
        guard !query.isEmpty else { return Array(BrrowCategory.allCases) }
        
        return BrrowCategory.allCases.filter { category in
            category.displayName.lowercased().contains(query.lowercased())
        }
    }
    
    // Get database value for a display name
    static func getDatabaseValue(for displayName: String) -> String {
        return BrrowCategory.allCases.first { $0.displayName == displayName }?.databaseValue ?? "other"
    }
    
    // Get display name from database value
    static func getDisplayName(for databaseValue: String) -> String {
        return BrrowCategory(databaseValue: databaseValue)?.displayName ?? "Other"
    }
}