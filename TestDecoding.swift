import Foundation

// Test iOS decoding with actual backend JSON
let jsonString = """
{"success":true,"data":{"listings":[{"id":"cmfg657t40001o31mwic8dvmz","title":"iPad Pro 2024","description":"Latest iPad Pro with M4 chip","categoryId":"default-category","condition":"NEW","price":85,"isNegotiable":false,"availabilityStatus":"AVAILABLE","location":{"city":"San Francisco","state":"CA","address":"123 Market St","country":"USA","zipCode":"94105","latitude":37.7749,"longitude":-122.4194,"coordinates":{"latitude":37.7749,"longitude":-122.4194}},"userId":"cmfg5zsrm0000o21mtexoi9h3","viewCount":2,"favoriteCount":0,"isActive":true,"isPremium":false,"premiumExpiresAt":null,"deliveryOptions":{"pickup":true,"delivery":false,"shipping":false,"localPickup":true,"localDelivery":false},"tags":[],"metadata":{"submittedAt":"2025-09-12T01:38:45.062Z","clientOptimistic":"true","moderationStatus":"auto-approved"},"createdAt":"2025-09-12T01:38:45.063Z","updatedAt":"2025-09-12T05:17:31.120Z","user":{"id":"cmfg5zsrm0000o21mtexoi9h3","username":"testuser","profilePictureUrl":null,"averageRating":null},"category":{"id":"default-category","name":"General","description":"General items","iconUrl":null,"parentId":null,"isActive":true,"sortOrder":0,"createdAt":"2025-09-11T02:17:40.311Z","updatedAt":"2025-09-11T02:17:40.311Z"},"images":[],"videos":[],"_count":{"favorites":0},"imageUrls":[]}],"pagination":{"total":5,"page":1,"per_page":20,"total_pages":1,"has_more":false,"limit":20,"offset":0,"pages":1}}}
"""

// Test Response structures (simplified)
struct TestListingsResponse: Codable {
    let success: Bool
    let data: TestListingsData?
    
    struct TestListingsData: Codable {
        let listings: [TestListing]
        let pagination: TestPaginationData
    }
    
    struct TestPaginationData: Codable {
        let total: Int
        let page: Int?
        let perPage: Int?
        let totalPages: Double?
        let hasMore: Bool?
        let limit: Int?
        let offset: Int?
        let pages: Int?
        
        enum CodingKeys: String, CodingKey {
            case total
            case page
            case perPage = "per_page"
            case totalPages = "total_pages"
            case hasMore = "has_more"
            case limit
            case offset
            case pages
        }
    }
}

struct TestListing: Codable {
    let id: String
    let title: String
    let description: String
    let categoryId: String
    let condition: String
    let price: Double
    let isNegotiable: Bool
    let availabilityStatus: String
    let location: TestLocation
    let userId: String
    let viewCount: Int
    let favoriteCount: Int
    let isActive: Bool
    let isPremium: Bool
    let premiumExpiresAt: Date?
    let deliveryOptions: TestDeliveryOptions?
    let tags: [String]
    let metadata: [String: String]?
    let createdAt: Date
    let updatedAt: Date
    let user: TestUserInfo?
    let category: TestCategory?
    let images: [TestListingImage]
    let videos: [TestListingVideo]?
    let imageUrls: [String]
    let _count: TestCount?
    
    struct TestCount: Codable {
        let favorites: Int
    }
}

struct TestLocation: Codable {
    let city: String?
    let state: String?
    let address: String?
    let country: String?
    let zipCode: String?
    let latitude: Double?
    let longitude: Double?
    let coordinates: TestCoordinates?
    
    struct TestCoordinates: Codable {
        let latitude: Double
        let longitude: Double
    }
}

struct TestDeliveryOptions: Codable {
    let pickup: Bool?
    let delivery: Bool?
    let shipping: Bool?
    let localPickup: Bool?
    let localDelivery: Bool?
}

struct TestUserInfo: Codable {
    let id: String
    let username: String?
    let profilePictureUrl: String?
    let averageRating: Double?
}

struct TestCategory: Codable {
    let id: String
    let name: String
    let description: String?
    let iconUrl: String?
    let parentId: String?
    let isActive: Bool?
    let sortOrder: Int?
    let createdAt: Date?
    let updatedAt: Date?
}

struct TestListingImage: Codable {
    let id: String?
    let url: String?
    let imageUrl: String?
}

struct TestListingVideo: Codable {
    let id: String?
    let url: String?
}

// Test decoding
let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .iso8601

do {
    let data = jsonString.data(using: .utf8)!
    let response = try decoder.decode(TestListingsResponse.self, from: data)
    print("✅ Decoding successful!")
    print("Listings count:", response.data?.listings.count ?? 0)
} catch {
    print("❌ Decoding failed:", error)
    if let decodingError = error as? DecodingError {
        switch decodingError {
        case .keyNotFound(let key, let context):
            print("Missing key:", key.stringValue)
            print("Path:", context.codingPath.map { $0.stringValue }.joined(separator: "."))
        case .typeMismatch(let type, let context):
            print("Type mismatch. Expected:", type)
            print("Path:", context.codingPath.map { $0.stringValue }.joined(separator: "."))
            print("Debug:", context.debugDescription)
        case .valueNotFound(let type, let context):
            print("Value not found. Expected:", type)
            print("Path:", context.codingPath.map { $0.stringValue }.joined(separator: "."))
        case .dataCorrupted(let context):
            print("Data corrupted")
            print("Path:", context.codingPath.map { $0.stringValue }.joined(separator: "."))
            print("Debug:", context.debugDescription)
        @unknown default:
            print("Unknown error")
        }
    }
}