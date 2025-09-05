import Foundation
import Combine
import SwiftUI
import CoreLocation

@MainActor
class GarageSalesViewModel: ObservableObject {
    @Published var garageSales: [GarageSale] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedRadius: Double = 25.0
    @Published var showingCreateView = false
    @Published var selectedCategory: String?
    @Published var showActiveOnly = true
    @Published var hasMorePages = true
    
    private var cancellables = Set<AnyCancellable>()
    private let apiClient = APIClient.shared
    private let locationService = LocationService.shared
    private var currentPage = 1
    private let pageSize = 20
    private var isLoadingMore = false
    
    init() {
        Task {
            await fetchGarageSales()
        }
        setupSearchObserver()
    }
    
    private func setupSearchObserver() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task {
                    await self?.fetchGarageSales(refresh: true)
                }
            }
            .store(in: &cancellables)
    }
    
    func fetchGarageSales(refresh: Bool = false) async {
        guard !isLoading && !isLoadingMore else { return }
        
        if refresh {
            currentPage = 1
            hasMorePages = true
            garageSales = []
        }
        
        isLoading = currentPage == 1
        isLoadingMore = currentPage > 1
        errorMessage = nil
        
        do {
            let parameters = buildRequestParameters()
            
            // Use the new clean API endpoint
            let baseURL = await APIEndpointManager.shared.getBestEndpoint()
            let url = "\(baseURL)/api/garage_sales/fetch.php"
            var request = URLRequest(url: URL(string: url)!)
            request.httpMethod = "GET"
            
            // Add query parameters
            var components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
            components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
            request.url = components.url
            
            // Add auth header if available
            if let token = UserDefaults.standard.string(forKey: "authToken") {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(GarageSalesListResponse.self, from: data)
            
            if response.success {
                if currentPage == 1 {
                    garageSales = response.garageSales
                } else {
                    garageSales.append(contentsOf: response.garageSales)
                }
                
                hasMorePages = response.pagination.page < response.pagination.pages
                currentPage += 1
                
                // Track analytics
                let event = AnalyticsEvent(
                    eventName: "garage_sales_viewed",
                    eventType: "view",
                    metadata: [
                        "page": String(response.pagination.page),
                        "total": String(response.pagination.total),
                        "category": selectedCategory ?? "all"
                    ]
                )
                
                Task {
                    try? await apiClient.trackAnalytics(event: event)
                }
            }
            
            isLoading = false
            isLoadingMore = false
        } catch {
            self.errorMessage = error.localizedDescription
            isLoading = false
            isLoadingMore = false
        }
    }
    
    private func buildRequestParameters() -> [String: String] {
        var parameters: [String: String] = [
            "page": String(currentPage),
            "limit": String(pageSize),
            "is_active": String(showActiveOnly)
        ]
        
        // Add location parameters if available
        if let location = locationService.currentLocation {
            parameters["latitude"] = String(location.coordinate.latitude)
            parameters["longitude"] = String(location.coordinate.longitude)
            parameters["radius"] = String(selectedRadius)
        }
        
        // Add category filter if selected
        if let category = selectedCategory {
            parameters["category"] = category
        }
        
        // Add search text if not empty
        if !searchText.isEmpty {
            parameters["search"] = searchText
        }
        
        return parameters
    }
    
    func loadGarageSales() {
        Task {
            await fetchGarageSales()
        }
    }
    
    func refreshGarageSales() {
        Task {
            await fetchGarageSales(refresh: true)
        }
    }
    
    func loadMoreIfNeeded(currentItem: GarageSale?) async {
        guard let currentItem = currentItem,
              hasMorePages,
              !isLoadingMore else { return }
        
        let thresholdIndex = garageSales.index(garageSales.endIndex, offsetBy: -5)
        if garageSales.firstIndex(where: { $0.id == currentItem.id }) ?? 0 >= thresholdIndex {
            await fetchGarageSales()
        }
    }
    
    func toggleRSVP(for garageSale: GarageSale) async {
        do {
            let response = try await apiClient.rsvpGarageSale(
                id: garageSale.id,
                isRsvp: !(garageSale.isRsvp ?? false)
            )
            
            if response.success {
                // Update local state
                if let index = garageSales.firstIndex(where: { $0.id == garageSale.id }) {
                    garageSales[index].isRsvp = response.data?.rsvpStatus == "rsvp"
                    garageSales[index].rsvpCount = response.data?.totalRSVPs ?? 0
                }
            }
        } catch {
            self.errorMessage = "Failed to update RSVP: \(error.localizedDescription)"
        }
    }
    
    func toggleFavorite(for garageSale: GarageSale) async {
        do {
            let response = try await apiClient.toggleGarageSaleFavorite(id: garageSale.id)
            
            if response.success {
                // Update local state
                if let index = garageSales.firstIndex(where: { $0.id == garageSale.id }) {
                    garageSales[index].isFavorited = response.data?.isFavorited ?? false
                }
            }
        } catch {
            self.errorMessage = "Failed to update favorite: \(error.localizedDescription)"
        }
    }
    
    func deleteGarageSale(_ sale: GarageSale) {
        Task {
            do {
                // For now, just deactivate instead of delete
                let updatedSale = try await apiClient.toggleGarageSaleActive(
                    id: sale.id,
                    isActive: false
                )
                
                await MainActor.run {
                    if let index = self.garageSales.firstIndex(where: { $0.id == sale.id }) {
                        self.garageSales[index] = updatedSale
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Response Models
struct GarageSalesListResponse: Codable {
    let success: Bool
    let garageSales: [GarageSale]
    let pagination: Pagination
    
    enum CodingKeys: String, CodingKey {
        case success
        case garageSales = "garage_sales"
        case pagination
    }
}

struct Pagination: Codable {
    let page: Int
    let limit: Int
    let total: Int
    let pages: Int
}