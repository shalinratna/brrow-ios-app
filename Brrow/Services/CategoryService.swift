//
//  CategoryService.swift
//  Brrow
//
//  Fetches and caches categories from the API
//

import Foundation
import Combine

// MARK: - Category API Models
struct CategoryResponse: Codable {
    let id: String
    let name: String
    let description: String?
    let iconUrl: String?
    let parentId: String?
    let isActive: Bool?  // Optional to handle null from database
    let sortOrder: Int?  // Optional to handle null from database
    let createdAt: String?  // Optional to handle null from database
    let updatedAt: String?  // Optional to handle null from database

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case iconUrl = "icon_url"
        case parentId = "parent_id"
        case isActive = "is_active"
        case sortOrder = "sort_order"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Category Display Model
struct CategoryItem: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let iconUrl: String?
    let sortOrder: Int

    init(from response: CategoryResponse) {
        self.id = response.id
        self.name = response.name
        self.description = response.description ?? ""
        self.iconUrl = response.iconUrl
        self.sortOrder = response.sortOrder ?? 999  // Default to end if no sort order
    }
}

// MARK: - Category Service
@MainActor
class CategoryService: ObservableObject {
    static let shared = CategoryService()

    // MARK: - Published Properties
    @Published var categories: [CategoryItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var lastFetchTime: Date?
    private let cacheExpirationInterval: TimeInterval = 3600 // 1 hour
    private let userDefaults = UserDefaults.standard
    private let categoriesCacheKey = "cached_categories"
    private let cacheTimestampKey = "categories_cache_timestamp"

    // MARK: - Initialization
    private init() {
        // Load cached categories immediately on init
        loadCachedCategories()

        // Fetch fresh categories if cache is expired
        if isCacheExpired() {
            Task {
                await fetchCategories()
            }
        }
    }

    // MARK: - Public Methods

    /// Fetch categories from API
    func fetchCategories() async {
        // Don't fetch if already loading
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        do {
            let baseURL = await APIEndpointManager.shared.getBestEndpoint()
            guard let url = URL(string: "\(baseURL)/api/categories") else {
                throw CategoryServiceError.invalidURL
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 10

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw CategoryServiceError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                throw CategoryServiceError.serverError(statusCode: httpResponse.statusCode)
            }

            let categoryResponses = try JSONDecoder().decode([CategoryResponse].self, from: data)

            // Filter out "General" and "default-category" (legacy categories)
            let validCategories = categoryResponses
                .filter { ($0.isActive ?? true) && $0.id != "default-category" }
                .map { CategoryItem(from: $0) }
                .sorted { $0.sortOrder < $1.sortOrder }

            self.categories = validCategories
            self.lastFetchTime = Date()

            // Cache the categories
            cacheCategories(validCategories)

            print("✅ Fetched \(validCategories.count) categories from API")

        } catch {
            errorMessage = "Failed to load categories: \(error.localizedDescription)"
            print("❌ Failed to fetch categories: \(error)")

            // If fetch fails and we have no categories, load from cache
            if categories.isEmpty {
                loadCachedCategories()
            }
        }

        isLoading = false
    }

    /// Force refresh categories
    func refreshCategories() async {
        lastFetchTime = nil
        await fetchCategories()
    }

    /// Get category by ID
    func getCategory(byId id: String) -> CategoryItem? {
        return categories.first { $0.id == id }
    }

    /// Get category by name
    func getCategory(byName name: String) -> CategoryItem? {
        return categories.first { $0.name.lowercased() == name.lowercased() }
    }

    /// Get category names for UI display
    func getCategoryNames() -> [String] {
        return categories.map { $0.name }
    }

    /// Get category names with "All" option
    func getCategoryNamesWithAll() -> [String] {
        return ["All"] + getCategoryNames()
    }

    // MARK: - Private Methods

    private func isCacheExpired() -> Bool {
        guard let lastFetch = lastFetchTime else { return true }
        return Date().timeIntervalSince(lastFetch) > cacheExpirationInterval
    }

    private func cacheCategories(_ categories: [CategoryItem]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(categories)
            userDefaults.set(data, forKey: categoriesCacheKey)
            userDefaults.set(Date(), forKey: cacheTimestampKey)
            print("✅ Cached \(categories.count) categories")
        } catch {
            print("❌ Failed to cache categories: \(error)")
        }
    }

    private func loadCachedCategories() {
        guard let data = userDefaults.data(forKey: categoriesCacheKey),
              let timestamp = userDefaults.object(forKey: cacheTimestampKey) as? Date else {
            print("ℹ️ No cached categories found")
            return
        }

        do {
            let decoder = JSONDecoder()
            let cachedCategories = try decoder.decode([CategoryItem].self, from: data)
            self.categories = cachedCategories
            self.lastFetchTime = timestamp
            print("✅ Loaded \(cachedCategories.count) categories from cache")
        } catch {
            print("❌ Failed to load cached categories: \(error)")
        }
    }
}

// MARK: - CategoryItem Codable Conformance
extension CategoryItem: Codable {
    enum CodingKeys: String, CodingKey {
        case id, name, description, iconUrl, sortOrder
    }
}

// MARK: - Error Types
enum CategoryServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid server response"
        case .serverError(let code):
            return "Server error: \(code)"
        }
    }
}
